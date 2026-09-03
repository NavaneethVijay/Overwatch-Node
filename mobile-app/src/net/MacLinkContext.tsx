import React, { createContext, useContext, useEffect, useMemo, useState } from 'react';
import { ActiveModule, BuiltinModuleData, ConnectionStatus, useMacConnection } from './connection';
import { DiscoveryStatus, useMacDiscovery } from './discovery';
import { BluetoothDeviceInfo, MacApp, ModuleAction, NowPlayingInfo } from './protocol';

interface MacLinkValue {
  discoveryStatus: DiscoveryStatus;
  deviceName: string | null;
  connectionStatus: ConnectionStatus;
  /** Once true, stays true for the rest of the session — see ConnectScreen. */
  hasConnectedOnce: boolean;
  apps: MacApp[];
  installedApps: MacApp[];
  activeBundleId: string | null;
  activateApp: (bundleId: string) => void;
  openApp: (bundleId: string) => void;
  closeApp: (bundleId: string) => void;
  brightness: number | null;
  setBrightness: (level: number) => void;
  volume: number | null;
  setVolume: (level: number) => void;
  bluetoothDevices: BluetoothDeviceInfo[];
  requestBluetooth: () => void;
  triggerScreenshot: () => void;
  activeModule: ActiveModule | null;
  invokeControlAction: (action: ModuleAction) => void;
  selectProject: (bundleId: string, projectId: string) => void;
  builtinModules: Record<string, BuiltinModuleData>;
  requestBuiltinModule: (bundleId: string) => void;
  triggerLockScreen: () => void;
  triggerShutdown: () => void;
  nowPlaying: NowPlayingInfo | null;
  mediaPlayPause: () => void;
  mediaNext: () => void;
  mediaPrevious: () => void;
  pairingRequired: boolean;
  pairingError: string | null;
  submitPairingCode: (code: string) => void;
  /** User-initiated: arms the connection attempt. Discovery runs regardless. */
  connect: () => void;
}

const MacLinkContext = createContext<MacLinkValue | null>(null);

/**
 * Owns the single shared discovery + WebSocket connection for the whole app.
 * Screens read from this via useMacLink() rather than each calling
 * useMacDiscovery()/useMacConnection() themselves — otherwise every screen
 * would open its own independent connection to the Mac.
 *
 * The connection only actually starts once `connect()` has been called (see
 * ConnectScreen) — discovery runs continuously in the background regardless,
 * but we don't attempt a WebSocket connection until the user has explicitly
 * asked to. After the first successful connection, `hasConnectedOnce` stays
 * true for the session: a later drop reconnects silently in the background
 * (see connection.ts's own backoff + resume-on-foreground logic) rather than
 * bouncing the user back to the connect screen.
 */
export function MacLinkProvider({ children }: { children: React.ReactNode }) {
  const discovery = useMacDiscovery();
  const [armed, setArmed] = useState(false);
  const [hasConnectedOnce, setHasConnectedOnce] = useState(false);

  const {
    status: connectionStatus,
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
  } = useMacConnection(armed ? discovery.host : null, armed ? discovery.port : null);

  useEffect(() => {
    if (connectionStatus === 'open') setHasConnectedOnce(true);
  }, [connectionStatus]);

  const value = useMemo<MacLinkValue>(
    () => ({
      discoveryStatus: discovery.status,
      deviceName: discovery.deviceName,
      connectionStatus,
      hasConnectedOnce,
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
      connect: () => setArmed(true),
    }),
    [
      discovery.status,
      discovery.deviceName,
      connectionStatus,
      hasConnectedOnce,
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
    ],
  );

  return <MacLinkContext.Provider value={value}>{children}</MacLinkContext.Provider>;
}

export function useMacLink(): MacLinkValue {
  const ctx = useContext(MacLinkContext);
  if (!ctx) {
    throw new Error('useMacLink() must be called within a MacLinkProvider');
  }
  return ctx;
}
