# Contributing to Overwatch Node

This is a solo-built, build-it-yourself project — there's real room to make an
impact. Bug reports, feature ideas, and PRs are all welcome.

## Ways to help

- **Contextual controls** — add a new per-app control (browser action, terminal
  shortcut, editor command). See existing ones in
  `macos-app/Sources/OverwatchNode/` and `mobile-app/src/` for the pattern.
- **Device testing** — Android and iOS, different Mac models, real Wi-Fi
  conditions. The more hardware this sees, the more bugs surface early.
- **Protocol work** — both sides hand-implement the same WebSocket protocol
  with no shared schema (`macos-app/Sources/OverwatchNode/Protocol.swift` and
  `mobile-app/src/net/protocol.ts`). Keeping them in sync, or proposing
  codegen, is high-leverage.
- **Design** — the HUD visual language is documented in
  [`design/DESIGN_SYSTEM.md`](design/DESIGN_SYSTEM.md) and reusable. New
  screens should read as more of this system.
- **Docs** — setup friction is real for a build-it-yourself project; clearer
  Quick Starts and troubleshooting notes help every contributor after you.

## Before you start

1. Read the root [`README.md`](README.md) for the two-app/one-protocol
   overview, and each app's own README for setup:
   [`macos-app/README.md`](macos-app/README.md),
   [`mobile-app/README.md`](mobile-app/README.md).
2. For anything non-trivial, open an issue first to align on approach before
   sinking time into a PR.
3. If you touch the protocol, update **both** `Protocol.swift` and
   `protocol.ts` in the same PR — they're not codegen'd from each other.
4. Keep new UI consistent with `design/DESIGN_SYSTEM.md` (colors, type,
   motion, shape language) rather than introducing a new visual style.

## Submitting a PR

- Keep PRs focused — one control, one fix, one screen at a time.
- Describe what you tested it on (simulator vs. real device, macOS version,
  Android/iOS version) since this project is hardware-sensitive.
- Link the issue it addresses, if any.

## Reporting bugs

Open a [GitHub issue](https://github.com/NavaneethVijay/Overwatch-Node/issues)
with: what you expected, what happened, your macOS version, and your phone
OS/version. Screenshots or a screen recording help a lot for UI issues.
