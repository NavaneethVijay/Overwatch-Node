import React, { useEffect } from 'react';
import { Dimensions, StyleSheet } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import Animated, {
  Easing,
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withTiming,
} from 'react-native-reanimated';
import { motion } from '../theme/tokens';

const BAND_HEIGHT = 120;

/**
 * The ambient "system online" scanline sweep present on every screen —
 * a soft glow band drifting down, always running, never gated on interaction.
 * RN has no mix-blend-mode support used here (CSS `screen`); low opacity is
 * the cross-platform approximation.
 */
export function ScanlineOverlay() {
  const { height: windowHeight } = Dimensions.get('window');
  const progress = useSharedValue(0);

  useEffect(() => {
    progress.value = withRepeat(
      withTiming(1, { duration: motion.scanlineDurationMs, easing: Easing.linear }),
      -1,
    );
  }, [progress]);

  const style = useAnimatedStyle(() => ({
    transform: [
      {
        translateY:
          -BAND_HEIGHT + progress.value * (windowHeight + BAND_HEIGHT * 2),
      },
    ],
  }));

  return (
    <Animated.View style={[styles.band, style]} pointerEvents="none">
      <LinearGradient
        colors={[
          'rgba(41,241,255,0)',
          'rgba(41,241,255,0.05)',
          'rgba(41,241,255,0.14)',
          'rgba(41,241,255,0.05)',
          'rgba(41,241,255,0)',
        ]}
        locations={[0, 0.45, 0.5, 0.55, 1]}
        style={StyleSheet.absoluteFill}
      />
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  band: {
    position: 'absolute',
    left: 0,
    right: 0,
    top: 0,
    height: BAND_HEIGHT,
    zIndex: 5,
  },
});
