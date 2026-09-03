# Overwatch Node — Design System

Visual language locked in from the approved mockup (`design/mockups/*.dc.html`,
also viewable as a canvas at the published artifact link shared in chat). This is
the reference for all future screens — new UI should read as more of this system,
not a new one. Tone: a productivity command deck / HUD you're jacked into, not a
remote control or a typical consumer app.

## Voice & copy

Technical/system vocabulary, not consumer-app language. Screen titles and labels
read like a HUD readout, not a menu.

| Consumer-app phrasing (avoid) | System phrasing (use) |
|---|---|
| "Open Apps" | "WORKSPACE GRID" |
| "Tap an app to switch" | "SELECT NODE :: FOCUS ON MACBOOK" |
| "Now Playing" | "SIGNAL // AUDIO STREAM" |
| "Brightness" | "OPTIC OUTPUT // DISPLAY" |
| "Connected" | "LINK // <DEVICE-ID>" |
| App tile subtext | "ACTIVE" / "IDLE" (process-state framing) |

Labels and section headers are `UPPERCASE`, letter-spaced (`0.05–0.12em`). Device
names render as `NAVANEETH-MBP`-style identifiers, not friendly possessive names.

## Color

Two-accent neon system on a near-black base. **The accent choice is semantic, not
decorative** — keep this rule when adding new screens:

- **Cyan `#29f1ff`** — ambient/system chrome: borders, headers, HUD status data,
  idle icon strokes, inactive-but-present elements.
- **Magenta `#ff2f9e`** — anything live, selected, active, or currently playing:
  the focused app tile, the active nav tab, a filled slider/gauge level, the
  playing-state ring.
- **Muted blue-gray `#3d4656` / `#4a5568` / `#5a6472`** — inactive/idle text and
  icons (unselected nav tabs, "IDLE" status, secondary metadata).
- **Text** — primary `#eaf6ff` (cool off-white), never pure white.
- **Background** — `linear-gradient(180deg, #070a11 0%, #0a0e17 100%)` with a
  faint 26px grid overlay (`repeating-linear-gradient`, ~2.5% white opacity, both
  axes) for texture. Panels/glass surfaces: `rgba(255,255,255,0.03–0.06)` fill
  with a `1px` cyan-tinted border (`rgba(41,241,255,0.15–0.25)`).

Never introduce a third accent hue or colorful per-item gradients (the old
rainbow-icon-tile approach was explicitly rejected) — differentiate items by
icon shape, not by color.

## Typography

Three fonts, each with one job (Google Fonts, already wired in the mockups):

- **Orbitron** (700/800/900) — big glowing numbers and screen titles only
  (`WORKSPACE GRID`, track title, the `72%` brightness readout). Sparingly —
  it's the least readable at small sizes.
- **Chakra Petch** (400–700) — everything else that's UI text: tile labels,
  buttons, body copy. This is the default `font-family` on every screen.
- **JetBrains Mono** — all status/telemetry text: connection strings, latency
  readouts, "ACTIVE"/"IDLE" tags, nav labels, timestamps. Always small
  (9–11px), letter-spaced, and usually muted or accent-colored rather than
  primary text color.

## Shape language

- **Chamfered (cut-corner) panels and icon frames**, not rounded rectangles.
  Standard clip-path for square-ish elements:
  `clip-path: polygon(8px 0, 100% 0, 100% calc(100% - 8px), calc(100% - 8px) 100%, 0 100%, 0 8px);`
  (scale the `8px`/`16px` cut to the element's size — 8px for ~56px tiles, 16px
  for larger panels like album art).
- **Circles stay circles** for transport/control buttons (play/pause, skip,
  slider thumbs) — that's the one place standard round shapes are correct,
  matching universal transport-control convention.
- **Corner brackets** (targeting-reticle marks) mark the *currently selected*
  element only — two small L-shaped marks, top-left and bottom-right, in the
  active magenta accent, `filter: drop-shadow(...)` for glow. Don't add all
  four corners; two is the established pattern.

## Motion

Every screen carries ambient motion — stillness reads as "disconnected." Reuse
these exact patterns rather than inventing new ones per screen:

- **Scanline sweep** — a soft horizontal glow band drifting down the full
  screen on a ~5.5s linear loop, `mix-blend-mode: screen`, very low opacity.
  Present on every screen, always running, never gated by interaction.
- **Pulse** — connection dot and any "live" indicator: `box-shadow` pulsing
  outward, ~1.8s ease-in-out infinite.
- **Signal bars** — 4 vertical bars, staggered opacity pulse (~1.4s, staggered
  `animation-delay`), used in the top status HUD.
- **Glitch flicker** — titles/big numbers get a rare (~6s cycle, one flicker
  frame) RGB-split text-shadow glitch. Subtle — this is a system-idle tell,
  not a constant effect.
- **Reactive states** — animation should reflect real state, not just decorate:
  waveform bars animate only while `playing`, freeze to a static dim shape when
  paused; a rotating conic-gradient glow ring appears around the play button
  only while audio is live.

## Components

- **Top HUD status bar** (used on the grid screen; extend to any screen that
  needs connection context): pulsing dot + `LINK // <DEVICE-ID>` in mono, signal
  bars, a secondary mono line for latency/network details.
- **Tile grid**: a 2-column grid of wide, horizontal cards — not a home-screen
  icon grid. Each card is one chamfered panel (the whole card, not just the
  icon) laid out as icon on the left, name + status stacked on the right,
  filling the card's width. Corner brackets, when active, wrap the *entire
  card*, not just the icon. This reads as a system module/process list, not
  an app launcher — resist shrinking it back to small centered icon+label
  tiles. Tap toggles selection instantly — no loading state, no confirmation.
- **Bottom nav**: HUD segmented tabs, not icon+label buttons — a thin glowing
  magenta underline over the active tab, muted blue-gray icon+label for
  inactive tabs. Labels are short mono nouns (`GRID`, `AUDIO`, `DISPLAY`).
- **Horizontal slider** (volume): thin track, magenta fill up to value, white
  thumb with magenta glow.
- **Vertical gauge** (brightness): tick-marked track (`repeating-linear-gradient`
  cyan ticks) with a magenta fill from the bottom, large glitch-flicker Orbitron
  readout above it. This is a *gauge*, not a plain slider — the tick marks and
  glow are load-bearing to the aesthetic, don't simplify them away.

## Implementation notes for the real app (React Native)

- Icons: recreate as `react-native-svg` components, one file per icon, stroke-
  based, matching the exact paths in `design/mockups/*.dc.html` — don't
  reinterpret them.
- Animation: `react-native-reanimated` for the scanline, pulse, glitch, and
  spin-ring loops (all are simple infinite keyframe-style loops, straightforward
  to port). A gauge/tick slider will need a custom component — no off-the-shelf
  RN slider matches this look.
- Centralize the tokens above (colors, font families, chamfer clip-path
  equivalent — RN has no `clip-path`, so use an SVG mask or a custom shaped
  `View` via `react-native-svg` `Polygon` background) in a single
  `design/tokens.ts` when implementation starts, so every screen pulls from one
  source instead of re-declaring hex values.
- Fonts: bundle Orbitron, Chakra Petch, and JetBrains Mono as app assets (Google
  Fonts `@import` won't work in RN) — use `expo-font` or link native font files.

## Source files

`design/mockups/Main.dc.html` (Workspace Grid), `Media.dc.html` (Audio Stream),
`Brightness.dc.html` (Display Luminance), `canvas.json` (layout) — these are the
literal, working reference implementation of every rule above. When in doubt
about an exact value (a specific rgba, a font-size, a keyframe timing), it's
authoritative here, not in this document's prose.
