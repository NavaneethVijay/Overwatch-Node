import { useWindowDimensions } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export const GRID_H_PADDING = 20;
export const GRID_COLUMN_GAP = 14;

/**
 * Column count adapts to available width (rather than a hardcoded number)
 * so landscape — or a wider device — doesn't just stretch a fixed column
 * count into oversized cards. Shared by every app-card grid screen.
 *
 * `maxColumnsLandscape` optionally caps the column count, but only in
 * landscape — a wide-enough device (e.g. a large iPad) can naturally
 * compute more columns than actually reads well at a glance, so a screen
 * can opt into a lower cap there specifically; portrait is never affected
 * by it; the tile width grows to fill the row automatically once there
 * are fewer columns, so a cap alone also means bigger tiles, no separate
 * sizing logic needed.
 */
export function useResponsiveGrid(idealCardWidth: number, options?: { maxColumnsLandscape?: number }) {
  const insets = useSafeAreaInsets();
  const { width: windowWidth, height: windowHeight } = useWindowDimensions();
  const isLandscape = windowWidth > windowHeight;

  // Landscape can put a camera cutout / gesture-nav inset on the left or
  // right edge instead of just the top, so it has to come out of the grid's
  // available width too, not just its own padding.
  const availableWidth = windowWidth - insets.left - insets.right;
  let numColumns = Math.max(
    2,
    Math.floor(
      (availableWidth - GRID_H_PADDING * 2 + GRID_COLUMN_GAP) / (idealCardWidth + GRID_COLUMN_GAP),
    ),
  );
  if (isLandscape && options?.maxColumnsLandscape) {
    numColumns = Math.min(numColumns, options.maxColumnsLandscape);
  }
  const cardWidth =
    (availableWidth - GRID_H_PADDING * 2 - GRID_COLUMN_GAP * (numColumns - 1)) / numColumns;

  const horizontalPadding = {
    paddingLeft: GRID_H_PADDING + insets.left,
    paddingRight: GRID_H_PADDING + insets.right,
  };

  return { numColumns, cardWidth, horizontalPadding };
}
