/**
 * Wire protocol between this app and the Mac companion app.
 * Must stay in sync with the Mac app's WebSocket handler — see macos-app/.
 */

export interface MacApp {
  bundleId: string;
  name: string;
  /** Base64-encoded PNG, no data: prefix. */
  iconPngBase64: string;
  isFrontmost: boolean;
  isRunning: boolean;
}

export interface BluetoothDeviceInfo {
  name: string;
  connected: boolean;
}

/** System-wide Now Playing metadata — any source (Music, Spotify, a
 * browser tab, ...), not just Apple Music. See macos-app's NowPlaying.swift
 * for how the Mac reads this despite it being a private API. All fields
 * but `playing` are absent when nothing is currently playing. */
export interface NowPlayingInfo {
  title?: string;
  artist?: string;
  album?: string;
  bundleIdentifier?: string;
  /** Base64 PNG, already resized by the Mac — no data: prefix. */
  artworkPngBase64?: string;
  playing: boolean;
}

/**
 * One control's action. `"shortcut"` is executed generically by the Mac
 * (CGEvent key injection); `"capability"` calls a named Swift function for
 * anything a keystroke can't do (reserved for built-in modules — never
 * something the module builder or an uploaded file can produce); `"paste"`
 * types `text` into whatever's currently frontmost on the Mac, optionally
 * pressing Enter afterward if `pressReturn` is true. `params` is set either
 * by this app when echoing a tapped dynamic-list item's id back (per-app
 * module JSON itself never sets it), or by module JSON itself for a
 * built-in capability that takes parameters (e.g. Window Management's
 * `window.tile`/`system.symbolicHotkey` — see macos-app/Sources/OverwatchNode/
 * DefaultModules.swift).
 */
export interface ModuleAction {
  kind: 'shortcut' | 'capability' | 'paste';
  keys?: string[];
  id?: string;
  params?: Record<string, string>;
  text?: string;
  pressReturn?: boolean;
}

export interface ModuleControl {
  type: 'button' | 'dynamicList';
  label?: string;
  icon?: string;
  action?: ModuleAction;
  provider?: string;
  itemAction?: ModuleAction;
}

export interface ModuleSection {
  title: string;
  controls: ModuleControl[];
}

/** A named, reorderable set of custom sections attached to one app's
 * module — e.g. Warp shows a "Projects" list; tapping one shows that
 * project's own buttons. Always user-authored, never seeded by a built-in
 * module, so its sections are restricted the same way any user-created
 * content is (see the Mac app's ModuleValidator — only "button" controls
 * with "shortcut"/"paste" actions, never "dynamicList"/"capability"). */
export interface Project {
  id: string;
  name: string;
  sections: ModuleSection[];
}

/** One row of a dynamic list (e.g. one browser tab). `url` is
 * browser.tabs-specific (used to look up a favicon) — empty for any future
 * provider with no notion of a URL. */
export interface DynamicListItem {
  id: string;
  title: string;
  url: string;
  active: boolean;
}

export type ServerMessage =
  | { type: 'app_list'; apps: MacApp[] }
  | { type: 'installed_apps'; apps: MacApp[] }
  | { type: 'brightness_state'; level: number }
  | { type: 'volume_state'; level: number }
  | { type: 'bluetooth_devices'; devices: BluetoothDeviceInfo[] }
  | {
      type: 'active_module';
      bundleId: string;
      displayName: string;
      hasModule: boolean;
      sections: ModuleSection[];
      dynamicData: Record<string, DynamicListItem[]>;
      projects: Project[];
      currentProjectId: string | null;
    }
  | {
      type: 'builtin_module_data';
      bundleId: string;
      displayName: string;
      sections: ModuleSection[];
      dynamicData: Record<string, DynamicListItem[]>;
      projects: Project[];
      currentProjectId: string | null;
    }
  | ({ type: 'now_playing_state' } & NowPlayingInfo)
  | { type: 'pairing_required' }
  | { type: 'pairing_status'; paired: boolean; error?: string };

export type ClientMessage =
  | { type: 'activate_app'; bundleId: string }
  | { type: 'open_app'; bundleId: string }
  | { type: 'close_app'; bundleId: string }
  | { type: 'set_brightness'; level: number }
  | { type: 'set_volume'; level: number }
  | { type: 'trigger_screenshot' }
  | { type: 'request_bluetooth' }
  | { type: 'invoke_control_action'; action: ModuleAction }
  | { type: 'select_project'; bundleId: string; projectId: string }
  | { type: 'request_builtin_module'; bundleId: string }
  | { type: 'trigger_lock_screen' }
  | { type: 'trigger_shutdown' }
  | { type: 'trigger_media_play_pause' }
  | { type: 'trigger_media_next' }
  | { type: 'trigger_media_previous' }
  | { type: 'client_hello'; deviceName: string; deviceId: string }
  | { type: 'submit_pairing_code'; code: string };

export function parseServerMessage(raw: string): ServerMessage | null {
  try {
    const data = JSON.parse(raw);
    if (!data || typeof data.type !== 'string') return null;

    switch (data.type) {
      case 'app_list':
      case 'installed_apps':
        return Array.isArray(data.apps) ? (data as ServerMessage) : null;
      case 'brightness_state':
      case 'volume_state':
        return typeof data.level === 'number' ? (data as ServerMessage) : null;
      case 'bluetooth_devices':
        return Array.isArray(data.devices) ? (data as ServerMessage) : null;
      case 'active_module':
        return typeof data.hasModule === 'boolean' &&
          Array.isArray(data.sections) &&
          Array.isArray(data.projects)
          ? (data as ServerMessage)
          : null;
      case 'builtin_module_data':
        return Array.isArray(data.sections) && Array.isArray(data.projects) ? (data as ServerMessage) : null;
      case 'now_playing_state':
        return typeof data.playing === 'boolean' ? (data as ServerMessage) : null;
      case 'pairing_required':
        return data as ServerMessage;
      case 'pairing_status':
        return typeof data.paired === 'boolean' ? (data as ServerMessage) : null;
      default:
        return null;
    }
  } catch {
    return null;
  }
}
