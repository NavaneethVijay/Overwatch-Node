import React, { PropsWithChildren } from 'react';
import { StyleSheet, View, ViewStyle } from 'react-native';
import Svg, { Polygon } from 'react-native-svg';

export interface ChamferViewProps {
  width: number;
  height: number;
  /** Corner cut size in px — see theme/tokens.ts `chamfer`. */
  cut?: number;
  fill?: string;
  borderColor?: string;
  borderWidth?: number;
  /** Approximated neon glow — real color bloom isn't available on Android. */
  glowColor?: string;
  style?: ViewStyle;
}

/**
 * The design system's core shape primitive: a chamfered (cut-corner) panel,
 * used everywhere instead of rounded rectangles. React Native has no CSS
 * clip-path equivalent, so this draws the cut shape with an SVG polygon and
 * lays children on top.
 *
 * Cuts the top-left and bottom-right corners, matching every mockup panel.
 */
export function ChamferView({
  width,
  height,
  cut = 8,
  fill = 'transparent',
  borderColor,
  borderWidth = 1,
  glowColor,
  style,
  children,
}: PropsWithChildren<ChamferViewProps>) {
  const points = [
    `${cut},0`,
    `${width},0`,
    `${width},${height - cut}`,
    `${width - cut},${height}`,
    `0,${height}`,
    `0,${cut}`,
  ].join(' ');

  return (
    <View
      style={[
        { width, height },
        glowColor
          ? {
              shadowColor: glowColor,
              shadowOpacity: 0.8,
              shadowRadius: 10,
              shadowOffset: { width: 0, height: 0 },
              elevation: 6,
            }
          : null,
        style,
      ]}
    >
      <Svg width={width} height={height} style={StyleSheet.absoluteFill}>
        <Polygon points={points} fill={fill} stroke={borderColor} strokeWidth={borderWidth} />
      </Svg>
      <View style={styles.content}>{children}</View>
    </View>
  );
}

const styles = StyleSheet.create({
  content: {
    ...StyleSheet.absoluteFill,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
