# Overwatch Node — mobile app

Expo + TypeScript app, styled per `../design/DESIGN_SYSTEM.md`'s cyberpunk
HUD look. Builds for **both Android and iOS** (not Android-only, despite
this folder's history). Talks to the [macOS companion app](../macos-app)
over the LAN — see its README for what to run on the Mac side first.

Uses the Expo **dev client** workflow (not Expo Go) because
`react-native-zeroconf`, used for Bonjour discovery, is a native module
Expo Go can't load.

## Quick Start

1. **Have `macos-app` running first** — this app needs something to
   discover and connect to. See `../macos-app/README.md`.
2. **Install dependencies**:
   ```sh
   npm install
   ```
3. **First build** (installs the dev client on a device/emulator — you
   only need to redo this after a *native* dependency change):
   ```sh
   npx expo prebuild
   npx expo run:android     # or: npx expo run:ios --device
   ```
4. **Day-to-day iteration**, once the dev client is installed:
   ```sh
   npm start
   ```
   Open the already-installed "Overwatch Node" dev client app on your
   device and point it at this Metro instance. Plain `expo start` +
   Expo Go will **not** work.
5. **On the phone**: the Connect screen scans for the Mac over Bonjour —
   tap **Connect** once it's found. The first time a given phone connects,
   the Mac shows a 6-digit pairing code; enter it on the phone to be
   trusted (see the Mac README's "Pairing" section for how this works).

For a standalone release build (APK sideload, or an iOS install without a
Metro server running), see [`../DEPLOYMENT.md`](../DEPLOYMENT.md) — it
covers both platforms.

## What's on screen

Four tabs (`src/navigation/RootTabs.tsx`), gated behind the Connect and
Pairing screens on first use:

- **ACTIVE** (`WorkspaceGridScreen`) — a **Built-in** row ("All Apps",
  "Window Management") plus a grid of the Mac's currently-*running* apps.
  Tap to switch focus; long-press to quit. "All Apps" pushes a screen
  listing every *installed* app (not just running ones), tap to
  launch/activate.
- **MUSIC** (`MusicScreen`) — real system-wide Now Playing info from the
  Mac (whatever's actually playing there — Music, Spotify, a browser tab,
  anything), with artwork and Play/Pause/Next/Previous transport controls.
- **MODULE** (`ModuleScreen`) — "Contextual Controls": per-app buttons and
  dynamic lists (e.g. browser tabs, terminal shortcuts) for whichever app
  is currently frontmost on the Mac, driven entirely by JSON the Mac
  sends — this screen has zero per-app knowledge baked into the client.
- **UTIL** (`UtilityScreen`) — real system controls: volume, screenshot
  trigger, lock screen, shutdown (double-tap to confirm), and a
  read-only Bluetooth device list (no connect/disconnect from the phone,
  by design). Brightness sends a real network message too, but the Mac
  side is currently a documented no-op — see the Mac README's "Known
  issues" for why.

Every control above is wired to a real WebSocket message
(`src/net/protocol.ts`/`src/net/connection.ts`) — there's no stubbed or
locally-faked screen left in the app.

## Stack

- Expo SDK ~57, React 19, React Native 0.86, TypeScript.
- `react-native-zeroconf` — mDNS/Bonjour discovery of the Mac's
  `_overwatchnode._tcp` service.
- Plain `WebSocket` (RN global) — no extra client library for the protocol.
- `@react-navigation/native` + `bottom-tabs` + `native-stack`, with a fully
  custom tab bar (`src/navigation/HudTabBar.tsx`).
- `react-native-svg` — every icon, plus the chamfered-panel shape primitive
  (RN has no CSS `clip-path`).
- `react-native-reanimated` + `react-native-gesture-handler` — ambient
  motion (scanline, pulse, signal bars) and the custom slider component.
- `@react-native-async-storage/async-storage` — persists this phone's
  stable pairing device id.
- `@expo-google-fonts/{orbitron,chakra-petch,jetbrains-mono}` — the three
  fonts, loaded via `expo-font`.

## Known simplifications vs. the mockups

- **Neon glow**: approximated with `shadowColor/shadowOpacity/shadowRadius`.
  Renders correctly on iOS; Android `View` shadows are elevation-only (not
  colored), so glow looks flatter there. A truly colored blur on Android
  would need a blur library or custom shader — not done here.
- **CSS `mix-blend-mode: screen`** (the scanline overlay) has no RN
  equivalent in use here; approximated with low opacity instead.
- Letter-spacing values in `theme/tokens.ts` are carried over from the
  mockups' `em`-relative CSS values but applied as flat point values (RN's
  `letterSpacing` is absolute, not font-relative) — close but not
  pixel-exact at every size.

## AGENTS.md note

`AGENTS.md` in this folder flags that Expo's docs move fast — read the
exact versioned docs at `docs.expo.dev/versions/v57.0.0/` before writing
code against a new Expo API, rather than relying on general knowledge that
may be stale for this SDK version.
