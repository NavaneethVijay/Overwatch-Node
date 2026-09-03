import React, { useEffect } from 'react';
import { StyleSheet, View } from 'react-native';
import Animated, {
  Easing,
  useAnimatedStyle,
  useSharedValue,
  withDelay,
  withRepeat,
  withTiming,
} from 'react-native-reanimated';
import { color, motion } from '../theme/tokens';

const HEIGHTS = [6, 10, 13, 16];
const DELAYS = [0, 200, 400, 600];

function Bar({ height, delay }: { height: number; delay: number }) {
  const progress = useSharedValue(0.35);

  useEffect(() => {
    progress.value = withDelay(
      delay,
      withRepeat(
        withTiming(1, {
          duration: motion.signalBarDurationMs / 2,
          easing: Easing.inOut(Easing.ease),
        }),
        -1,
        true,
      ),
    );
  }, [progress, delay]);

  const style = useAnimatedStyle(() => ({ opacity: progress.value }));

  return <Animated.View style={[styles.bar, { height }, style]} />;
}

/** The top-HUD "live signal" indicator — 4 bars, staggered opacity pulse. */
export function SignalBars() {
  return (
    <View style={styles.row}>
      {HEIGHTS.map((height, i) => (
        <Bar key={height} height={height} delay={DELAYS[i]} />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    gap: 2,
    height: 16,
  },
  bar: {
    width: 3,
    borderRadius: 1,
    backgroundColor: color.cyan,
  },
});
