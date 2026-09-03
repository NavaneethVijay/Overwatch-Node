import React, { useEffect } from 'react';
import { StyleSheet, Text, TextStyle, View } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withDelay,
  withRepeat,
  withSequence,
  withTiming,
} from 'react-native-reanimated';
import { color, motion } from '../theme/tokens';

export interface GlitchTextProps {
  children: string;
  style: TextStyle;
  /** Steady-state text-shadow glow color. */
  glowColor?: string;
}

/**
 * Titles/big numbers get a rare RGB-split glitch flicker — a system-idle
 * tell, not a constant effect. RN's Text only supports one text-shadow, so
 * the split is faked with two colored ghost copies that flash briefly.
 */
export function GlitchText({ children, style, glowColor = color.cyan }: GlitchTextProps) {
  const flicker = useSharedValue(0);

  useEffect(() => {
    flicker.value = withRepeat(
      withSequence(
        withTiming(0, { duration: motion.glitchCycleMs - 240 }),
        withDelay(0, withTiming(1, { duration: 60 })),
        withTiming(0, { duration: 60 }),
        withTiming(1, { duration: 60 }),
        withTiming(0, { duration: 60 }),
      ),
      -1,
    );
  }, [flicker]);

  const cyanGhostStyle = useAnimatedStyle(() => ({
    opacity: flicker.value,
    transform: [{ translateX: -2 * flicker.value }],
  }));
  const magentaGhostStyle = useAnimatedStyle(() => ({
    opacity: flicker.value,
    transform: [{ translateX: 2 * flicker.value }],
  }));

  return (
    <View style={styles.wrap}>
      <Text
        style={[
          style,
          {
            textShadowColor: glowColor,
            textShadowOffset: { width: 0, height: 0 },
            textShadowRadius: 12,
          },
        ]}
      >
        {children}
      </Text>
      <Animated.Text
        style={[styles.ghost, style, cyanGhostStyle, { color: color.cyan }]}
        pointerEvents="none"
      >
        {children}
      </Animated.Text>
      <Animated.Text
        style={[styles.ghost, style, magentaGhostStyle, { color: color.magenta }]}
        pointerEvents="none"
      >
        {children}
      </Animated.Text>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    position: 'relative',
    alignSelf: 'center',
  },
  ghost: {
    position: 'absolute',
    left: 0,
    top: 0,
    right: 0,
  },
});
