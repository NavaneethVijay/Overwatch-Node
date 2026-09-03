import { useCallback, useEffect, useRef, useState } from 'react';
import { AppState, Platform } from 'react-native';
import { getOrCreateDeviceId } from './deviceId';
import {
  BluetoothDeviceInfo,
  ClientMessage,
  DynamicListItem,
  MacApp,
  ModuleAction,
  ModuleSection,
  NowPlayingInfo,
  Project,
  parseServerMessage,
} from './protocol';
import { useThrottledCallback } from '../hooks/useThrottledCallback';

/** Max rate to actually send brightness/volume changes to the Mac. The
 * slider itself stays perfectly smooth regardless (it's gesture-driven
 * locally, see HSlider.tsx) — this just caps how often we hit the network
 * and, for volume, the Mac's slow AppleScript call. */
const SLIDER_SEND_THROTTLE_MS = 80;

export type ConnectionStatus = 'idle' | 'connecting' | 'open' | 'closed';

/** The frontmost app's Contextual Controls module, or null until the Mac's
 * first `active_module` message arrives. `hasModule: false` is a real,
 * meaningful state — "this app has no module" — distinct from "unknown yet". */
export interface ActiveModule {
  bundleId: string;
  displayName: string;
  hasModule: boolean;
  sections: ModuleSection[];
  dynamicData: Record<string, DynamicListItem[]>;
  projects: Project[];
  currentProjectId: string | null;
}

/** A "built-in" module's data (Window Management, so far the only one) —
 * fetched on demand via `requestBuiltinModule`, not pushed on a
 * frontmost-app change like `ActiveModule`, since a built-in module isn't
 * tied to whichever app happens to be frontmost. Keyed by bundleId in
 * `builtinModules` below so more than one could be cached at once, even
 * though only one exists today. */
export interface BuiltinModuleData {
  bundleId: string;
  displayName: string;
  sections: ModuleSection[];
  dynamicData: Record<string, DynamicListItem[]>;
  projects: Project[];
  currentProjectId: string | null;
}

export interface MacConnectionState {
  status: ConnectionStatus;
  /** Currently-open apps only — the Active Nodes tab. */
  apps: MacApp[];
  /** Every installed app, running or not — the All Nodes tab. */
  installedApps: MacApp[];
  activeBundleId: string | null;
  activateApp: (bundleId: string) => void;
  /** Activates if already running, otherwise launches it. */
  openApp: (bundleId: string) => void;
  /** A normal, cancelable quit — same as Cmd+Q. */
  closeApp: (bundleId: string) => void;
  /** 0-100, null until the Mac's first snapshot arrives. */
  brightness: number | null;
  setBrightness: (level: number) => void;
  /** 0-100, null until the Mac's first snapshot arrives. */
  volume: number | null;
  setVolume: (level: number) => void;
  bluetoothDevices: BluetoothDeviceInfo[];
  requestBluetooth: () => void;
  triggerScreenshot: () => void;
  /** null until the Mac's first active_module message arrives. */
  activeModule: ActiveModule | null;
  invokeControlAction: (action: ModuleAction) => void;
  /** Persists + broadcasts which Project is "current" for an app (see
   * ModuleStore.setCurrentProject on the Mac) — synced via the Mac, not
   * phone-local, so it's consistent across a reconnect or another phone. */
  selectProject: (bundleId: string, projectId: string) => void;
  /** Keyed by bundleId — empty until requested. See requestBuiltinModule. */
  builtinModules: Record<string, BuiltinModuleData>;
  /** Asks the Mac for a built-in (not per-frontmost-app) module's current
   * data — the reply lands in `builtinModules[bundleId]`. Call this again
   * (e.g. on screen focus) to pick up an edit made in the Mac's Settings
   * while the phone had it cached. */
  requestBuiltinModule: (bundleId: string) => void;
  triggerLockScreen: () => void;
  triggerShutdown: () => void;
  /** null until the Mac's first now_playing_state message arrives. */
  nowPlaying: NowPlayingInfo | null;
  mediaPlayPause: () => void;
  mediaNext: () => void;
  mediaPrevious: () => void;
  /** True from the moment the Mac says this device isn't trusted yet
   * until a correct pairing code is submitted — see DevicePairing.swift.
   * The phone should show a blocking pairing screen while this is true;
   * every other message the Mac would normally send is withheld until
   * pairing completes. */
  pairingRequired: boolean;
  /** Set after a wrong/expired code — cleared on the next submit attempt
   * or once pairing succeeds. */
  pairingError: string | null;
  submitPairingCode: (code: string) => void;
}

const INITIAL_BACKOFF_MS = 1000;
const MAX_BACKOFF_MS = 10000;

/** Shown in the Mac's menu bar / Status tab once connected. */
function localDeviceName(): string {
  if (Platform.OS === 'android') {
    return Platform.constants.Model ?? 'Android Device';
  }
  return 'Phone';
}

/**
 * Owns a single WebSocket connection to the Mac app at ws://host:port/ws,
 * reconnecting with exponential backoff whenever it drops. `host`/`port`
 * normally come from useMacDiscovery().
 */
export function useMacConnection(host: string | null, port: number | null): MacConnectionState {
  const [status, setStatus] = useState<ConnectionStatus>('idle');
  const [apps, setApps] = useState<MacApp[]>([]);
  const [installedApps, setInstalledApps] = useState<MacApp[]>([]);
  const [activeBundleId, setActiveBundleId] = useState<string | null>(null);
  const [brightness, setBrightnessState] = useState<number | null>(null);
  const [volume, setVolumeState] = useState<number | null>(null);
  const [bluetoothDevices, setBluetoothDevices] = useState<BluetoothDeviceInfo[]>([]);
  const [activeModule, setActiveModule] = useState<ActiveModule | null>(null);
  const [builtinModules, setBuiltinModules] = useState<Record<string, BuiltinModuleData>>({});
  const [nowPlaying, setNowPlaying] = useState<NowPlayingInfo | null>(null);
  const [pairingRequired, setPairingRequired] = useState(false);
  const [pairingError, setPairingError] = useState<string | null>(null);

  // Resolved once on mount and reused for the app's lifetime — the Mac's
  // trust store is keyed on this exact value (see DevicePairing.swift),
  // so it can never change underneath a connection attempt.
  const [deviceId, setDeviceId] = useState<string | null>(null);
  useEffect(() => {
    getOrCreateDeviceId().then(setDeviceId);
  }, []);

  const socketRef = useRef<WebSocket | null>(null);
  const backoffRef = useRef(INITIAL_BACKOFF_MS);
  const reconnectTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const closedByEffectRef = useRef(false);

  // A socket can look OPEN on this side while the underlying connection is
  // actually dead — the phone's Wi-Fi radio power-saving while the screen
  // was off, or a router silently dropping an idle connection, won't
  // necessarily fire `onclose`. Rather than trust a possibly-stale socket,
  // force a fresh connection every time the app comes back to the
  // foreground.
  const [resumeNonce, setResumeNonce] = useState(0);
  useEffect(() => {
    const subscription = AppState.addEventListener('change', (next) => {
      if (next === 'active') setResumeNonce((n) => n + 1);
    });
    return () => subscription.remove();
  }, []);

  useEffect(() => {
    closedByEffectRef.current = false;

    if (!host || !port || !deviceId) {
      setStatus('idle');
      return;
    }

    let cancelled = false;

    const connect = () => {
      if (cancelled) return;
      setStatus('connecting');
      setPairingRequired(false);
      setPairingError(null);
      const socket = new WebSocket(`ws://${host}:${port}/ws`);
      socketRef.current = socket;

      socket.onopen = () => {
        if (cancelled) return;
        backoffRef.current = INITIAL_BACKOFF_MS;
        setStatus('open');
        socket.send(JSON.stringify({ type: 'client_hello', deviceName: localDeviceName(), deviceId }));
      };

      socket.onmessage = (event) => {
        const message = parseServerMessage(String(event.data));
        if (!message) return;
        switch (message.type) {
          case 'app_list': {
            setApps(message.apps);
            const frontmost = message.apps.find((app) => app.isFrontmost);
            setActiveBundleId(frontmost ? frontmost.bundleId : null);
            break;
          }
          case 'installed_apps':
            setInstalledApps(message.apps);
            break;
          case 'brightness_state':
            setBrightnessState(message.level);
            break;
          case 'volume_state':
            setVolumeState(message.level);
            break;
          case 'bluetooth_devices':
            setBluetoothDevices(message.devices);
            break;
          case 'active_module':
            setActiveModule({
              bundleId: message.bundleId,
              displayName: message.displayName,
              hasModule: message.hasModule,
              sections: message.sections,
              dynamicData: message.dynamicData,
              projects: message.projects,
              currentProjectId: message.currentProjectId,
            });
            break;
          case 'builtin_module_data':
            setBuiltinModules((prev) => ({
              ...prev,
              [message.bundleId]: {
                bundleId: message.bundleId,
                displayName: message.displayName,
                sections: message.sections,
                dynamicData: message.dynamicData,
                projects: message.projects,
                currentProjectId: message.currentProjectId,
              },
            }));
            break;
          case 'now_playing_state':
            setNowPlaying({
              title: message.title,
              artist: message.artist,
              album: message.album,
              bundleIdentifier: message.bundleIdentifier,
              artworkPngBase64: message.artworkPngBase64,
              playing: message.playing,
            });
            break;
          case 'pairing_required':
            setPairingRequired(true);
            break;
          case 'pairing_status':
            if (message.paired) {
              setPairingRequired(false);
              setPairingError(null);
            } else {
              setPairingError(message.error ?? 'Incorrect code.');
            }
            break;
        }
      };

      socket.onerror = () => {
        // onclose fires right after; reconnect is scheduled there.
      };

      socket.onclose = () => {
        if (cancelled) return;
        setStatus('closed');
        if (closedByEffectRef.current) return;
        const delay = backoffRef.current;
        backoffRef.current = Math.min(backoffRef.current * 2, MAX_BACKOFF_MS);
        reconnectTimerRef.current = setTimeout(connect, delay);
      };
    };

    connect();

    return () => {
      cancelled = true;
      closedByEffectRef.current = true;
      if (reconnectTimerRef.current) clearTimeout(reconnectTimerRef.current);
      socketRef.current?.close();
      socketRef.current = null;
    };
  }, [host, port, deviceId, resumeNonce]);

  const send = useCallback((message: ClientMessage) => {
    const socket = socketRef.current;
    if (!socket || socket.readyState !== WebSocket.OPEN) return;
    socket.send(JSON.stringify(message));
  }, []);

  const activateApp = useCallback(
    (bundleId: string) => {
      send({ type: 'activate_app', bundleId });
      // Optimistic local update — the Mac confirms with a fresh app_list,
      // but tapping a tile should feel instant.
      setActiveBundleId(bundleId);
    },
    [send],
  );

  const openApp = useCallback((bundleId: string) => send({ type: 'open_app', bundleId }), [send]);
  const closeApp = useCallback((bundleId: string) => send({ type: 'close_app', bundleId }), [send]);

  const sendBrightness = useThrottledCallback(
    useCallback((level: number) => send({ type: 'set_brightness', level }), [send]),
    SLIDER_SEND_THROTTLE_MS,
  );
  const sendVolume = useThrottledCallback(
    useCallback((level: number) => send({ type: 'set_volume', level }), [send]),
    SLIDER_SEND_THROTTLE_MS,
  );

  const setBrightness = useCallback(
    (level: number) => {
      // Optimistic local update happens on every call (cheap, and HSlider
      // ignores it mid-drag anyway) — only the actual network send is
      // throttled.
      setBrightnessState(level);
      sendBrightness(level);
    },
    [sendBrightness],
  );

  const setVolume = useCallback(
    (level: number) => {
      setVolumeState(level);
      sendVolume(level);
    },
    [sendVolume],
  );

  const requestBluetooth = useCallback(() => send({ type: 'request_bluetooth' }), [send]);
  const triggerScreenshot = useCallback(() => send({ type: 'trigger_screenshot' }), [send]);
  const invokeControlAction = useCallback(
    (action: ModuleAction) => send({ type: 'invoke_control_action', action }),
    [send],
  );
  const selectProject = useCallback(
    (bundleId: string, projectId: string) => send({ type: 'select_project', bundleId, projectId }),
    [send],
  );
  const requestBuiltinModule = useCallback(
    (bundleId: string) => send({ type: 'request_builtin_module', bundleId }),
    [send],
  );
  const triggerLockScreen = useCallback(() => send({ type: 'trigger_lock_screen' }), [send]);
  const triggerShutdown = useCallback(() => send({ type: 'trigger_shutdown' }), [send]);
  const mediaPlayPause = useCallback(() => send({ type: 'trigger_media_play_pause' }), [send]);
  const mediaNext = useCallback(() => send({ type: 'trigger_media_next' }), [send]);
  const mediaPrevious = useCallback(() => send({ type: 'trigger_media_previous' }), [send]);
  const submitPairingCode = useCallback(
    (code: string) => {
      setPairingError(null);
      send({ type: 'submit_pairing_code', code });
    },
    [send],
  );

  return {
    status,
    apps,
    installedApps,
    activeBundleId,
    activateApp,
    openApp,
    closeApp,
    brightness,
    setBrightness,
    volume,
    setVolume,
    bluetoothDevices,
    requestBluetooth,
    triggerScreenshot,
    activeModule,
    invokeControlAction,
    selectProject,
    builtinModules,
    requestBuiltinModule,
    triggerLockScreen,
    triggerShutdown,
    nowPlaying,
    mediaPlayPause,
    mediaNext,
    mediaPrevious,
    pairingRequired,
    pairingError,
    submitPairingCode,
  };
}
