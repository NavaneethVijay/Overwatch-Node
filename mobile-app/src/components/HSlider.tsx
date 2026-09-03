import React, { useEffect, useState } from 'react';
import { LayoutChangeEvent, StyleSheet, View } from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, { runOnJS, useAnimatedStyle, useSharedValue } from 'react-native-reanimated';
import { color } from '../theme/tokens';

export interface HSliderProps {
  /** 0-100 */
  value: number;
  onChange: (value: number) => void;
  height?: number;
}

const THUMB_SIZE = 16;

/**
 * The horizontal fill slider used for volume/brightness — thin track,
 * magenta fill, glowing white thumb. No off-the-shelf RN slider matches
 * this look, so it's a custom gesture-driven component (see
 * DESIGN_SYSTEM.md).
 */
export function HSlider({ value, onChange, height = 4 }: HSliderProps) {
  const [trackWidth, setTrackWidth] = useState(0);
  const fraction = useSharedValue(value / 100);

  // `value` is a round-tripped network value (the Mac's confirmed
  // brightness/volume), which can arrive slightly after the finger has
  // already moved past it. Resyncing from it unconditionally makes the
  // thumb visibly snap backward mid-drag — this is what made the slider
  // feel laggy/inaccurate. Only resync once the gesture has actually ended.
  const isDragging = useSharedValue(false);

  useEffect(() => {
    if (isDragging.value) return;
    fraction.value = value / 100;
  }, [value, fraction, isDragging]);

  const updateFromX = (x: number) => {
    'worklet';
    const clamped = Math.max(0, Math.min(trackWidth, x));
    const next = trackWidth > 0 ? clamped / trackWidth : 0;
    fraction.value = next;
    runOnJS(onChange)(Math.round(next * 100));
  };

  const pan = Gesture.Pan()
    .onBegin((e) => {
      isDragging.value = true;
      updateFromX(e.x);
    })
    .onUpdate((e) => updateFromX(e.x))
    .onFinalize(() => {
      isDragging.value = false;
    });

  const onLayout = (e: LayoutChangeEvent) => setTrackWidth(e.nativeEvent.layout.width);

  const fillStyle = useAnimatedStyle(() => ({ width: `${fraction.value * 100}%` }));
  const thumbStyle = useAnimatedStyle(() => ({
    left: `${fraction.value * 100}%`,
    transform: [{ translateX: -THUMB_SIZE / 2 }],
  }));

  return (
    <GestureDetector gesture={pan}>
      <View
        style={[styles.track, { height }]}
        onLayout={onLayout}
        hitSlop={{ top: 14, bottom: 14 }}
      >
        <Animated.View style={[styles.fill, fillStyle, { height }]} />
        <Animated.View style={[styles.thumb, thumbStyle]} />
      </View>
    </GestureDetector>
  );
}

const styles = StyleSheet.create({
  track: {
    flex: 1,
    borderRadius: 2,
    backgroundColor: color.cyanBorder,
    justifyContent: 'center',
  },
  fill: {
    position: 'absolute',
    left: 0,
    top: 0,
    borderRadius: 2,
    backgroundColor: color.magenta,
  },
  thumb: {
    position: 'absolute',
    top: '50%',
    width: THUMB_SIZE,
    height: THUMB_SIZE,
    borderRadius: THUMB_SIZE / 2,
    backgroundColor: color.white,
    marginTop: -THUMB_SIZE / 2,
    shadowColor: color.magenta,
    shadowOpacity: 0.9,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 0 },
  },
});
