import React from 'react';
import Svg, { Circle, Path, Polyline, Rect } from 'react-native-svg';

/**
 * Line icons ported 1:1 from the SVG paths in design/mockups/*.dc.html.
 * Don't redraw — if a new icon is needed, match this stroke style
 * (round caps/joins, ~1.7-1.9 stroke width on a 24x24 viewBox).
 */

export interface IconProps {
  size?: number;
  color?: string;
  strokeWidth?: number;
}

const strokeProps = (color: string, strokeWidth: number) => ({
  fill: 'none' as const,
  stroke: color,
  strokeWidth,
  strokeLinecap: 'round' as const,
  strokeLinejoin: 'round' as const,
});

export function BrowserIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Circle cx={12} cy={12} r={9} {...strokeProps(color, strokeWidth)} />
      <Path d="M14.8 9.2 10.6 10.6 9.2 14.8l4.2-1.4z" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

export function MailIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={3.5} y={6} width={17} height={12} rx={1.5} {...strokeProps(color, strokeWidth)} />
      <Path d="M4.5 7.5 12 13l7.5-5.5" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

export function MessagesIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path d="M4 5.5h16v10H9.5L5.5 19v-3.5H4z" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

export function NotesIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path
        d="M6 5h9l4 4v10a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z"
        {...strokeProps(color, strokeWidth)}
      />
      <Path d="M8 11h8M8 15h5" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

export function CalendarIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={4} y={5.5} width={16} height={14} rx={1.5} {...strokeProps(color, strokeWidth)} />
      <Path d="M4 9.5h16M8 3.5v3M16 3.5v3" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

export function MusicIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path d="M9 18V6l10-2v12" {...strokeProps(color, strokeWidth)} />
      <Circle cx={7} cy={18} r={2.2} {...strokeProps(color, strokeWidth)} />
      <Circle cx={17} cy={16} r={2.2} {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

export function PhotosIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={3.5} y={5} width={17} height={14} rx={1.5} {...strokeProps(color, strokeWidth)} />
      <Circle cx={8.5} cy={10} r={1.3} {...strokeProps(color, strokeWidth)} />
      <Path d="M4 17l5-5 4 4 3-3 4 4" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

export function TerminalIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path d="M6 8.5 10 12l-4 3.5" {...strokeProps(color, strokeWidth)} />
      <Path d="M12.5 16h5.5" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** A folder — used for Projects (a named set of custom buttons attached to
 * an app's module). */
export function ProjectIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path
        d="M3.5 7.5a1 1 0 0 1 1-1H9l1.6 2H19.5a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1h-16a1 1 0 0 1-1-1z"
        {...strokeProps(color, strokeWidth)}
      />
    </Svg>
  );
}

export function FilesIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path
        d="M4 7.5a1.5 1.5 0 0 1 1.5-1.5h4l1.5 2h7.5a1.5 1.5 0 0 1 1.5 1.5v7a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 4 16.5z"
        {...strokeProps(color, strokeWidth)}
      />
    </Svg>
  );
}

/** Generic fallback for an app the icon set above doesn't cover. */
export function AppGenericIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={4} y={4} width={16} height={16} rx={2} {...strokeProps(color, strokeWidth)} />
      <Circle cx={12} cy={12} r={3} {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

export function GridIcon({ size = 21, color = '#3d4656', strokeWidth = 1.8 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={4} y={4} width={7} height={7} rx={1} {...strokeProps(color, strokeWidth)} />
      <Rect x={13} y={4} width={7} height={7} rx={1} {...strokeProps(color, strokeWidth)} />
      <Rect x={4} y={13} width={7} height={7} rx={1} {...strokeProps(color, strokeWidth)} />
      <Rect x={13} y={13} width={7} height={7} rx={1} {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Stacked layers — the "All Nodes" launcher tab, distinct from GridIcon's
 * 2x2 (the currently-open apps) since this represents the full catalog. */
export function LayersIcon({ size = 21, color = '#3d4656', strokeWidth = 1.8 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path d="M12 3.5 21 8.5 12 13.5 3 8.5z" {...strokeProps(color, strokeWidth)} />
      <Path d="M3 13 12 18l9-5" {...strokeProps(color, strokeWidth)} />
      <Path d="M3 17.5 12 22.5l9-5" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Volume — reused from the Media Control mockup's speaker glyph. */
export function SpeakerIcon({ size = 18, color = '#29f1ff', strokeWidth = 2 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path d="M4 10v4h4l5 4V6l-5 4z" {...strokeProps(color, strokeWidth)} />
      <Path d="M17 9a4.5 4.5 0 0 1 0 6M19.5 6.5a8.2 8.2 0 0 1 0 11" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Screenshot trigger — a viewfinder, reusing the corner-bracket motif
 * already used to mark an active/selected card. */
export function ViewfinderIcon({ size = 18, color = '#29f1ff', strokeWidth = 1.9 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path d="M4 9V6a2 2 0 0 1 2-2h3" {...strokeProps(color, strokeWidth)} />
      <Path d="M20 9V6a2 2 0 0 0-2-2h-3" {...strokeProps(color, strokeWidth)} />
      <Path d="M4 15v3a2 2 0 0 0 2 2h3" {...strokeProps(color, strokeWidth)} />
      <Path d="M20 15v3a2 2 0 0 1-2 2h-3" {...strokeProps(color, strokeWidth)} />
      <Circle cx={12} cy={12} r={3.2} {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** The standard bluetooth rune glyph. */
export function BluetoothIcon({ size = 18, color = '#29f1ff', strokeWidth = 1.8 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Polyline
        points="7.5 7.5 17 16.5 12 21 12 3 17 7.5 7.5 16.5"
        {...strokeProps(color, strokeWidth)}
      />
    </Svg>
  );
}

/** Padlock — lock screen. */
export function LockIcon({ size = 18, color = '#29f1ff', strokeWidth = 1.8 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={5} y={11} width={14} height={9} rx={1.5} {...strokeProps(color, strokeWidth)} />
      <Path d="M8 11V8a4 4 0 0 1 8 0v3" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Standard power glyph — shutdown. */
export function PowerIcon({ size = 18, color = '#29f1ff', strokeWidth = 1.9 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path d="M12 3.5v7" {...strokeProps(color, strokeWidth)} />
      <Path d="M7 6.5a7.5 7.5 0 1 0 10 0" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

export function SunIcon({
  size = 24,
  color = '#ff2f9e',
  strokeWidth = 1.9,
  opacity = 1,
}: IconProps & { opacity?: number }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" opacity={opacity}>
      <Circle cx={12} cy={12} r={5} {...strokeProps(color, strokeWidth)} />
      <Path
        d="M12 2.5v2.5M12 19v2.5M4.2 4.2l1.8 1.8M18 18l1.8 1.8M2.5 12H5M19 12h2.5M4.2 19.8 6 18M18 6l1.8-1.8"
        {...strokeProps(color, strokeWidth)}
      />
    </Svg>
  );
}

/** Chip/module glyph — the Contextual Controls tab. */
export function ModuleIcon({ size = 21, color = '#3d4656', strokeWidth = 1.8 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={6} y={6} width={12} height={12} rx={1.5} {...strokeProps(color, strokeWidth)} />
      <Path d="M9 6V3.5M15 6V3.5M9 20.5V18M15 20.5V18M6 9H3.5M6 15H3.5M18 9h2.5M18 15h2.5" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Window Management tab glyph — a window outline with its top-left
 * quadrant filled, the same visual grammar as the Tiling section's own
 * icons (see makeWindowTileIcon below) so the tab bar hints at what's
 * inside before you even tap it. */
export function WindowTabIcon({ size = 21, color = '#3d4656', strokeWidth = 1.8 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={4} y={4} width={16} height={16} rx={1.5} {...strokeProps(color, strokeWidth)} />
      <Rect x={4} y={4} width={8} height={8} fill={color} opacity={0.55} />
    </Svg>
  );
}

/** A new-tab glyph — window outline with a plus. */
export function NewTabIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={4} y={5} width={16} height={14} rx={1.5} {...strokeProps(color, strokeWidth)} />
      <Path d="M12 9v6M9 12h6" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** A close-tab glyph — window outline with an x. */
export function CloseTabIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={4} y={5} width={16} height={14} rx={1.5} {...strokeProps(color, strokeWidth)} />
      <Path d="M9.5 9.5l5 5M14.5 9.5l-5 5" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Reload glyph — a partial circular arrow. */
export function ReloadIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path d="M18.5 8A7.5 7.5 0 1 0 19.5 13" {...strokeProps(color, strokeWidth)} />
      <Path d="M19.5 4v5h-5" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Stacked bars — a list of items, e.g. open browser tabs. */
export function TabsListIcon({ size = 16, color = '#29f1ff', strokeWidth = 1.8 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={4} y={4.5} width={16} height={4} rx={1} {...strokeProps(color, strokeWidth)} />
      <Rect x={4} y={10} width={16} height={4} rx={1} {...strokeProps(color, strokeWidth)} />
      <Rect x={4} y={15.5} width={16} height={4} rx={1} {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Pull — arrow into a tray. */
export function GitPullIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path d="M12 4v11M7.5 11l4.5 4.5L16.5 11" {...strokeProps(color, strokeWidth)} />
      <Path d="M4.5 19h15" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Push — arrow out of a tray. */
export function GitPushIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path d="M12 19V8M7.5 12.5 12 8l4.5 4.5" {...strokeProps(color, strokeWidth)} />
      <Path d="M4.5 19h15" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Branch glyph — git status rows. */
export function GitBranchIcon({ size = 16, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Circle cx={6} cy={6} r={2.2} {...strokeProps(color, strokeWidth)} />
      <Circle cx={6} cy={18} r={2.2} {...strokeProps(color, strokeWidth)} />
      <Circle cx={17} cy={9} r={2.2} {...strokeProps(color, strokeWidth)} />
      <Path d="M6 8.2V15.8M6 8.2a6 6 0 0 0 6 6h2.8" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Previous tab — a left chevron. */
export function TabPrevIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.9 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path d="M14 6l-6 6 6 6" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Next tab — a right chevron. */
export function TabNextIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.9 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path d="M10 6l6 6-6 6" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Split pane — a window outline divided by a vertical line. */
export function SplitPaneIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={4} y={5} width={16} height={14} rx={1.5} {...strokeProps(color, strokeWidth)} />
      <Path d="M12 5v14" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** AI command — a sparkle (large four-point star, small companion star). */
export function AiCommandIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.6 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path d="M12 3l1.5 4.5L18 9l-4.5 1.5L12 15l-1.5-4.5L6 9l4.5-1.5L12 3z" {...strokeProps(color, strokeWidth)} />
      <Path d="M18.5 15l0.7 2 2 0.7-2 0.7-0.7 2-0.7-2-2-0.7 2-0.7z" {...strokeProps(color, strokeWidth * 0.8)} />
    </Svg>
  );
}

/** Block up — an upward arrow inside a square, for jumping to the previous
 * command block. */
export function BlockUpIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={4} y={4} width={16} height={16} rx={2} {...strokeProps(color, strokeWidth)} />
      <Path d="M12 16V8M8.5 11.5 12 8l3.5 3.5" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Block down — a downward arrow inside a square, for jumping to the next
 * command block. */
export function BlockDownIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={4} y={4} width={16} height={16} rx={2} {...strokeProps(color, strokeWidth)} />
      <Path d="M12 8v8M8.5 12.5 12 16l3.5-3.5" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Search — a plain magnifying glass. */
export function SearchIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.8 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Circle cx={10.5} cy={10.5} r={6} {...strokeProps(color, strokeWidth)} />
      <Path d="M15.5 15.5L20 20" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Workflows — a small flowchart, one node branching into two. */
export function WorkflowsIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.6 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={9} y={3.5} width={6} height={4.5} rx={1} {...strokeProps(color, strokeWidth)} />
      <Rect x={3} y={16} width={6} height={4.5} rx={1} {...strokeProps(color, strokeWidth)} />
      <Rect x={15} y={16} width={6} height={4.5} rx={1} {...strokeProps(color, strokeWidth)} />
      <Path d="M12 8v4M12 12H6v4M12 12h6v4" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Clear — a circled X, distinct from CloseTabIcon's squared-off version. */
export function ClearIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Circle cx={12} cy={12} r={8} {...strokeProps(color, strokeWidth)} />
      <Path d="M9 9l6 6M15 9l-6 6" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Window-tiling glyph factory — a window outline with one region filled
 * in to show which preset a button applies. Shared by all Tiling section
 * buttons in the built-in Window Management module so they read as one
 * visual family instead of ten unrelated icons. */
function makeWindowTileIcon(rx: number, ry: number, rw: number, rh: number) {
  return function WindowTileIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
    return (
      <Svg width={size} height={size} viewBox="0 0 24 24">
        <Rect x={4} y={4} width={16} height={16} rx={1.5} {...strokeProps(color, strokeWidth)} />
        <Rect x={rx} y={ry} width={rw} height={rh} fill={color} opacity={0.55} />
      </Svg>
    );
  };
}

export const TileLeftHalfIcon = makeWindowTileIcon(4, 4, 8, 16);
export const TileRightHalfIcon = makeWindowTileIcon(12, 4, 8, 16);
export const TileTopHalfIcon = makeWindowTileIcon(4, 4, 16, 8);
export const TileBottomHalfIcon = makeWindowTileIcon(4, 12, 16, 8);
export const TileTopLeftIcon = makeWindowTileIcon(4, 4, 8, 8);
export const TileTopRightIcon = makeWindowTileIcon(12, 4, 8, 8);
export const TileBottomLeftIcon = makeWindowTileIcon(4, 12, 8, 8);
export const TileBottomRightIcon = makeWindowTileIcon(12, 12, 8, 8);
export const TileMaximizeIcon = makeWindowTileIcon(4, 4, 16, 16);
export const TileCenterIcon = makeWindowTileIcon(7.5, 7.5, 9, 9);

/** Previous space — a filled (destination) pane on the left, an outlined
 * (current) pane on the right, chevron pointing the direction of travel. */
export function PrevSpaceIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={3} y={7} width={7} height={10} rx={1} fill={color} opacity={0.55} />
      <Rect x={14} y={7} width={7} height={10} rx={1} {...strokeProps(color, strokeWidth)} />
      <Path d="M12.5 9l-2 3 2 3" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Next space — mirror of PrevSpaceIcon. */
export function NextSpaceIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={3} y={7} width={7} height={10} rx={1} {...strokeProps(color, strokeWidth)} />
      <Rect x={14} y={7} width={7} height={10} rx={1} fill={color} opacity={0.55} />
      <Path d="M11.5 9l2 3-2 3" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Cycle windows — ReloadIcon's arc, with a window rect in the center
 * instead of empty space, to read as "cycle windows" not "refresh". */
export function CycleWindowsIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.6 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={9} y={9} width={6} height={6} rx={1} {...strokeProps(color, strokeWidth)} />
      <Path d="M18.5 8A7.5 7.5 0 1 0 19.5 13" {...strokeProps(color, strokeWidth)} />
      <Path d="M19.5 4v5h-5" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Mission Control — four scattered window thumbnails, distinct from
 * GridIcon's uniform 2x2 (that one means "currently running apps"). */
export function MissionControlIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.6 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={4} y={5} width={8} height={6} rx={1} {...strokeProps(color, strokeWidth)} />
      <Rect x={13} y={4.5} width={7} height={5} rx={1} {...strokeProps(color, strokeWidth)} />
      <Rect x={4} y={13} width={7} height={6} rx={1} {...strokeProps(color, strokeWidth)} />
      <Rect x={12} y={12.5} width={8} height={7} rx={1} {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** App Exposé — two cascaded windows of one app, distinct from Mission
 * Control's four scattered ones (this is scoped to a single app). */
export function AppExposeIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.6 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={7} y={4} width={13} height={10} rx={1.5} {...strokeProps(color, strokeWidth)} />
      <Rect x={4} y={11} width={13} height={10} rx={1.5} {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

/** Now Playing transport controls — filled shapes (not stroked outlines
 * like the rest of this file) since a solid play triangle/pause bars read
 * far clearer at small size than an outline would. */
export function PlayIcon({ size = 26, color = '#29f1ff' }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path d="M7.5 4.5v15l13-7.5z" fill={color} />
    </Svg>
  );
}

export function PauseIcon({ size = 26, color = '#29f1ff' }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={6} y={4.5} width={4} height={15} rx={1} fill={color} />
      <Rect x={14} y={4.5} width={4} height={15} rx={1} fill={color} />
    </Svg>
  );
}

export function SkipBackIcon({ size = 26, color = '#29f1ff' }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={5} y={5} width={2.4} height={14} rx={1} fill={color} />
      <Path d="M19 5v14l-11-7z" fill={color} />
    </Svg>
  );
}

export function SkipForwardIcon({ size = 26, color = '#29f1ff' }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={16.6} y={5} width={2.4} height={14} rx={1} fill={color} />
      <Path d="M5 5v14l11-7z" fill={color} />
    </Svg>
  );
}

// General-purpose icons for IDE-style and common actions — added for
// hand-authored/builder-created buttons that aren't tied to any specific
// built-in app (e.g. a custom "Build" or "Copy" button in a Project). Kept
// in sync by hand with macos-app/Sources/OverwatchNode/ModuleIconCatalog.swift's
// SF Symbol equivalents, same as every other MODULE_ICONS key.

export function BuildIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path d="M14.5 3.5l6 6-2.5 2.5-6-6z" {...strokeProps(color, strokeWidth)} />
      <Path d="M13 8.5 4.7 16.8a1.8 1.8 0 0 0 2.5 2.5L15.5 11" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

export function RunIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path d="M8 5.5v13l11-6.5z" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

export function DebugIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.6 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Circle cx={12} cy={13} r={5} {...strokeProps(color, strokeWidth)} />
      <Path
        d="M9 9 7.5 7M15 9l1.5-2M7 13H4M20 13h-3M8 17l-1.5 2M16 17l1.5 2M9 11h6"
        {...strokeProps(color, strokeWidth)}
      />
    </Svg>
  );
}

export function StopIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={6} y={6} width={12} height={12} rx={1.5} {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

export function SaveIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.6 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path d="M5 4.5h11l3 3v12h-14z" {...strokeProps(color, strokeWidth)} />
      <Rect x={8} y={5} width={6} height={4} {...strokeProps(color, strokeWidth)} />
      <Rect x={7} y={14} width={10} height={5} {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

export function CopyIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={8} y={8} width={11} height={11} rx={1.5} {...strokeProps(color, strokeWidth)} />
      <Path d="M5 16V5h11" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

export function PasteIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.6 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect x={6} y={5} width={12} height={16} rx={1.5} {...strokeProps(color, strokeWidth)} />
      <Rect x={9} y={3} width={6} height={3} rx={1} {...strokeProps(color, strokeWidth)} />
      <Path d="M9 11h6M9 14.5h6M9 18h4" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

export function CutIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Circle cx={7} cy={7} r={2.2} {...strokeProps(color, strokeWidth)} />
      <Circle cx={7} cy={17} r={2.2} {...strokeProps(color, strokeWidth)} />
      <Path d="M8.6 8.4 19 19M8.6 15.6 19 5" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

export function UndoIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path d="M7 10h8a5 5 0 0 1 0 10H9" {...strokeProps(color, strokeWidth)} />
      <Path d="M10 6 6 10l4 4" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

export function RedoIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.7 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path d="M17 10H9a5 5 0 0 0 0 10h6" {...strokeProps(color, strokeWidth)} />
      <Path d="M14 6l4 4-4 4" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

export function DeleteIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.6 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path d="M5 7h14M9 7V5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2" {...strokeProps(color, strokeWidth)} />
      <Rect x={6.5} y={7} width={11} height={13} rx={1.5} {...strokeProps(color, strokeWidth)} />
      <Path d="M10 11v6M14 11v6" {...strokeProps(color, strokeWidth)} />
    </Svg>
  );
}

export function StarIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.6 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path
        d="M12 4l2.4 5 5.6.6-4.2 3.8 1.2 5.5-4.9-2.9-4.9 2.9 1.2-5.5L4.2 9.6l5.6-.6z"
        {...strokeProps(color, strokeWidth)}
      />
    </Svg>
  );
}

export function GearIcon({ size = 26, color = '#29f1ff', strokeWidth = 1.6 }: IconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Circle cx={12} cy={12} r={3} {...strokeProps(color, strokeWidth)} />
      <Path
        d="M12 3v2.5M12 18.5V21M21 12h-2.5M5.5 12H3M18.4 5.6l-1.8 1.8M7.4 16.6l-1.8 1.8M18.4 18.4l-1.8-1.8M7.4 7.4 5.6 5.6"
        {...strokeProps(color, strokeWidth)}
      />
    </Svg>
  );
}

/** icon name (from module JSON) -> icon component, for rendering a
 * Contextual Controls module's buttons and dynamic-list fallback icons
 * from server data. */
export const MODULE_ICONS: Record<string, React.ComponentType<IconProps>> = {
  'new-tab': NewTabIcon,
  'close-tab': CloseTabIcon,
  reload: ReloadIcon,
  tabs: TabsListIcon,
  'git-pull': GitPullIcon,
  'git-push': GitPushIcon,
  'git-branch': GitBranchIcon,
  'tab-prev': TabPrevIcon,
  'tab-next': TabNextIcon,
  'split-pane': SplitPaneIcon,
  'ai-command': AiCommandIcon,
  'block-up': BlockUpIcon,
  'block-down': BlockDownIcon,
  search: SearchIcon,
  workflows: WorkflowsIcon,
  clear: ClearIcon,
  'tile-left-half': TileLeftHalfIcon,
  'tile-right-half': TileRightHalfIcon,
  'tile-top-half': TileTopHalfIcon,
  'tile-bottom-half': TileBottomHalfIcon,
  'tile-top-left': TileTopLeftIcon,
  'tile-top-right': TileTopRightIcon,
  'tile-bottom-left': TileBottomLeftIcon,
  'tile-bottom-right': TileBottomRightIcon,
  'tile-maximize': TileMaximizeIcon,
  'tile-center': TileCenterIcon,
  'space-prev': PrevSpaceIcon,
  'space-next': NextSpaceIcon,
  'cycle-windows': CycleWindowsIcon,
  'mission-control': MissionControlIcon,
  'app-expose': AppExposeIcon,
  project: ProjectIcon,
  build: BuildIcon,
  run: RunIcon,
  debug: DebugIcon,
  stop: StopIcon,
  save: SaveIcon,
  console: TerminalIcon,
  copy: CopyIcon,
  paste: PasteIcon,
  cut: CutIcon,
  undo: UndoIcon,
  redo: RedoIcon,
  delete: DeleteIcon,
  lock: LockIcon,
  star: StarIcon,
  settings: GearIcon,
};

/** name -> icon component, for rendering the Workspace Grid from server data. */
export const APP_ICONS: Record<string, React.ComponentType<IconProps>> = {
  'com.apple.Safari': BrowserIcon,
  'com.apple.mail': MailIcon,
  'com.apple.MobileSMS': MessagesIcon,
  'com.apple.Notes': NotesIcon,
  'com.apple.iCal': CalendarIcon,
  'com.apple.Music': MusicIcon,
  'com.apple.Photos': PhotosIcon,
  'com.apple.Terminal': TerminalIcon,
  'com.apple.finder': FilesIcon,
};
