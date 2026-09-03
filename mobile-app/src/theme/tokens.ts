/**
 * Single source of truth for the "Overwatch Node" design language.
 * Values are ported 1:1 from design/mockups/*.dc.html and design/DESIGN_SYSTEM.md —
 * do not hardcode a hex/font/size in a screen or component, import it from here.
 */

export const color = {
  // Ambient / system chrome — borders, headers, HUD data, idle icon strokes.
  cyan: '#29f1ff',
  cyanDim: 'rgba(41,241,255,0.75)',
  cyanBorder: 'rgba(41,241,255,0.18)',
  cyanBorderStrong: 'rgba(41,241,255,0.25)',
  cyanGlow: 'rgba(41,241,255,0.35)',

  // Live / selected / active / playing.
  magenta: '#ff2f9e',
  magentaDim: 'rgba(255,47,158,0.12)',
  magentaBorder: 'rgba(255,47,158,0.55)',
  magentaGlow: 'rgba(255,47,158,0.35)',

  // Idle / muted text and icons.
  muted1: '#3d4656',
  muted2: '#4a5568',
  muted3: '#5a6472',
  mutedLabel: '#c3cad6',

  // Text.
  text: '#eaf6ff',
  textOnMagenta: '#0a0e17',

  // Background.
  bgTop: '#070a11',
  bgBottom: '#0a0e17',
  navBg: 'rgba(6,9,15,0.75)',
  panelFill: 'rgba(255,255,255,0.03)',
  panelFillStrong: 'rgba(255,255,255,0.06)',
  white: '#ffffff',
} as const;

export const font = {
  /** Big glowing numbers and screen titles only — sparingly. */
  display: 'Orbitron_800ExtraBold',
  displayBlack: 'Orbitron_900Black',
  /** Default UI font — tile labels, buttons, body copy. */
  bodyRegular: 'ChakraPetch_400Regular',
  bodyMedium: 'ChakraPetch_500Medium',
  bodySemiBold: 'ChakraPetch_600SemiBold',
  bodyBold: 'ChakraPetch_700Bold',
  /** All status/telemetry text — connection strings, latency, ACTIVE/IDLE tags. */
  mono: 'JetBrainsMono_400Regular',
  monoMedium: 'JetBrainsMono_500Medium',
  monoBold: 'JetBrainsMono_700Bold',
} as const;

/**
 * Font family name strings above must match the named exports pulled from
 * @expo-google-fonts/* in App.tsx's useFonts() call — see App.tsx.
 */

export const spacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 18,
  xl: 22,
  xxl: 28,
} as const;

/** Standard chamfer (cut-corner) notch sizes — scale to element size. */
export const chamfer = {
  tile: 8, // ~56px icon frames
  card: 10, // workspace grid app cards
  panel: 16, // larger panels, e.g. album art
} as const;

export const letterSpacing = {
  label: 0.05,
  mono: 0.07,
  wide: 0.09,
  wider: 0.12,
} as const;

/** Motion timings — see DESIGN_SYSTEM.md "Motion" section. */
export const motion = {
  scanlineDurationMs: 5500,
  pulseDurationMs: 1800,
  signalBarDurationMs: 1400,
  glitchCycleMs: 6000,
  waveBarDurationMs: 1100,
  spinRingDurationMs: 2400,
  tilePressScale: 0.94,
  controlPressScale: 0.9,
} as const;

/** Bonjour/mDNS service the Mac app advertises. Must match the Mac side exactly. */
export const macService = {
  type: 'overwatchnode',
  protocol: 'tcp' as const,
  domain: 'local.',
};
