# Overwatch Node

A Mac companion app pair: a menu-bar helper on macOS, and a phone app
(Android + iOS) that turns your phone into a remote control for it —
switch/launch/quit apps, see what's running, control system volume and
Bluetooth, trigger a screenshot, lock or shut down the Mac, see and
control whatever's currently playing (any app, not just Music), and drive
per-app "contextual controls" (browser tabs, terminal shortcuts, and
more) — all over your own LAN, no cloud, no account.

## Two apps, one protocol

- **[`macos-app/`](macos-app/README.md)** — the Mac-side menu bar app
  (Swift Package Manager, no Xcode project needed). Advertises itself over
  Bonjour, runs a small WebSocket server, does the actual work (app
  switching, system controls, screenshots, media info).
- **[`mobile-app/`](mobile-app/README.md)** — the phone app (Expo +
  TypeScript, React Native). Builds for **both Android and iOS** — despite
  the "mobile" name, it's not Android-only. Discovers the Mac over the
  LAN and talks to it over WebSocket.
- **[`design/`](design/DESIGN_SYSTEM.md)** — the cyberpunk/HUD visual
  language the phone app implements.

Both sides hand-implement the same message protocol (no shared
schema/codegen) — see `macos-app/Sources/OverwatchNode/Protocol.swift` and
`mobile-app/src/net/protocol.ts`, kept in sync by hand.

## Building from source

This is a **build-it-yourself** project, not a download-and-run one —
there's no notarized, signed release to just download. Each side documents
its own setup:

- Mac: [`macos-app/README.md`](macos-app/README.md) — see its "Quick
  Start" section: one-time local code-signing setup (free, no Apple
  Developer account), then `./run.sh`.
- Phone: [`mobile-app/README.md`](mobile-app/README.md) — see its own
  "Quick Start" for day-to-day dev-client iteration, or
  [`DEPLOYMENT.md`](DEPLOYMENT.md) for standalone release builds (APK
  sideload / iOS device install) without a Metro server running.

## Security model

Worth understanding before you use this on your own network:

- All traffic is plain `ws://` (no TLS) — deliberate, since this is
  LAN-only and connects to whatever IP Bonjour discovers rather than a
  fixed domain a certificate could cover.
- A new phone must be **paired** before it can do anything: the Mac shows
  a 6-digit code (system notification + the Status screen), which expires
  after 5 minutes and locks out after 5 wrong attempts. Trusted devices
  persist and can be revoked from the Mac's Status screen at any time.
- This is LAN-trust, not hardened security — anyone who can already join
  your Wi-Fi network can attempt to pair. Fine for a home network; treat
  it accordingly on a shared or untrusted network.

## License

[MIT](LICENSE)
