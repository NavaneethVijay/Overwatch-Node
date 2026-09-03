import React, { PropsWithChildren } from 'react';
import { Dimensions, StyleSheet, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import Svg, { Defs, Line, Pattern, Rect } from 'react-native-svg';
import { color } from '../theme/tokens';
import { ScanlineOverlay } from './ScanlineOverlay';

const GRID_SIZE = 26;

/** The faint graph-paper texture behind every screen. */
function GridTexture() {
  const { width, height } = Dimensions.get('window');
  return (
    <Svg width={width} height={height} style={StyleSheet.absoluteFill}>
      <Defs>
        <Pattern
          id="grid"
          width={GRID_SIZE}
          height={GRID_SIZE}
          patternUnits="userSpaceOnUse"
        >
          <Line x1={0} y1={0} x2={GRID_SIZE} y2={0} stroke="rgba(255,255,255,0.025)" strokeWidth={1} />
          <Line x1={0} y1={0} x2={0} y2={GRID_SIZE} stroke="rgba(255,255,255,0.025)" strokeWidth={1} />
        </Pattern>
      </Defs>
      <Rect x={0} y={0} width={width} height={height} fill="url(#grid)" />
    </Svg>
  );
}

/**
 * Shared root for every screen: dark gradient + grid texture + the ambient
 * scanline sweep, edge-to-edge (SDK 57 default) — screens are responsible
 * for their own safe-area padding on top of this.
 */
export function ScreenBackground({ children }: PropsWithChildren) {
  return (
    <View style={styles.root}>
      <LinearGradient
        colors={[color.bgTop, color.bgBottom]}
        style={StyleSheet.absoluteFill}
      />
      <GridTexture />
      <ScanlineOverlay />
      <View style={styles.content}>{children}</View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: color.bgTop,
  },
  content: {
    flex: 1,
    zIndex: 2,
  },
});
