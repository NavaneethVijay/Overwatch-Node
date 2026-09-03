import React, { useEffect } from 'react';
import { StyleSheet } from 'react-native';
import Animated, {
  Easing,
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withTiming,
} from 'react-native-reanimated';
import { color, motion } from '../theme/tokens';

/** The connection-live indicator dot — box-shadow pulse ported to opacity+scale. */
export function PulseDot({ tint = color.cyan }: { tint?: string }) {
  const progress = useSharedValue(0);

  useEffect(() => {
    progress.value = withRepeat(
      withTiming(1, { duration: motion.pulseDurationMs / 2, easing: Easing.inOut(Easing.ease) }),
      -1,
      true,
    );
  }, [progress]);

  const glowStyle = useAnimatedStyle(() => ({
    opacity: 0.35 + progress.value * 0.65,
    transform: [{ scale: 1 + progress.value * 1.6 }],
  }));

  return (
    <Animated.View style={styles.wrap}>
      <Animated.View style={[styles.glow, glowStyle, { backgroundColor: tint }]} />
      <Animated.View style={[styles.core, { backgroundColor: tint }]} />
    </Animated.View>
  );
}

const SIZE = 6;

const styles = StyleSheet.create({
  wrap: {
    width: SIZE,
    height: SIZE,
    alignItems: 'center',
    justifyContent: 'center',
  },
  core: {
    width: SIZE,
    height: SIZE,
    borderRadius: SIZE / 2,
  },
  glow: {
    position: 'absolute',
    width: SIZE,
    height: SIZE,
    borderRadius: SIZE / 2,
  },
});
