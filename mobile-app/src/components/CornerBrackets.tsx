import React from 'react';
import { StyleSheet, View } from 'react-native';
import { color } from '../theme/tokens';

/**
 * Targeting-reticle corner marks that flag the currently *selected* element.
 * Exactly two corners (top-left, bottom-right) — see DESIGN_SYSTEM.md.
 */
export function CornerBrackets({ tint = color.magenta }: { tint?: string }) {
  return (
    <>
      <View style={[styles.corner, styles.topLeft, { borderColor: tint, shadowColor: tint }]} />
      <View
        style={[styles.corner, styles.bottomRight, { borderColor: tint, shadowColor: tint }]}
      />
    </>
  );
}

const styles = StyleSheet.create({
  corner: {
    position: 'absolute',
    width: 12,
    height: 12,
    shadowOpacity: 0.7,
    shadowRadius: 4,
    shadowOffset: { width: 0, height: 0 },
  },
  topLeft: {
    top: -5,
    left: -5,
    borderTopWidth: 2,
    borderLeftWidth: 2,
  },
  bottomRight: {
    bottom: -5,
    right: -5,
    borderBottomWidth: 2,
    borderRightWidth: 2,
  },
});
