import { BottomTabBarProps } from '@react-navigation/bottom-tabs';
import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { GridIcon, ModuleIcon, MusicIcon, SunIcon } from '../components/icons';
import { color, font, letterSpacing } from '../theme/tokens';

const TAB_CONFIG: Record<string, { label: string; Icon: typeof GridIcon }> = {
  Active: { label: 'ACTIVE', Icon: GridIcon },
  Music: { label: 'MUSIC', Icon: MusicIcon },
  Module: { label: 'MODULE', Icon: ModuleIcon },
  Utility: { label: 'UTIL', Icon: SunIcon },
};

/**
 * The design system's segmented HUD tab bar — a glowing magenta underline
 * over the active tab, muted blue-gray icon+label otherwise. Deliberately
 * not the stock @react-navigation tab bar styling.
 */
export function HudTabBar({ state, navigation }: BottomTabBarProps) {
  const insets = useSafeAreaInsets();

  return (
    <View style={[styles.bar, { paddingBottom: Math.max(insets.bottom, 12) }]}>
      {state.routes.map((route, index) => {
        const config = TAB_CONFIG[route.name];
        if (!config) return null;
        const isFocused = state.index === index;
        const tint = isFocused ? color.magenta : color.muted1;
        const { Icon } = config;

        const onPress = () => {
          const event = navigation.emit({ type: 'tabPress', target: route.key, canPreventDefault: true });
          if (!isFocused && !event.defaultPrevented) {
            navigation.navigate(route.name);
          }
        };

        return (
          <Pressable key={route.key} onPress={onPress} style={styles.tab} hitSlop={8}>
            {isFocused ? <View style={styles.underline} /> : null}
            <Icon size={21} color={tint} strokeWidth={1.8} />
            <Text style={[styles.label, { color: tint }]}>{config.label}</Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    flexDirection: 'row',
    alignItems: 'stretch',
    justifyContent: 'space-around',
    paddingHorizontal: 10,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: color.cyanBorder,
    backgroundColor: color.navBg,
  },
  tab: {
    flex: 1,
    alignItems: 'center',
    gap: 5,
    paddingTop: 7,
    position: 'relative',
  },
  underline: {
    position: 'absolute',
    top: 0,
    width: 24,
    height: 2,
    borderRadius: 1,
    backgroundColor: color.magenta,
    shadowColor: color.magenta,
    shadowOpacity: 0.9,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 0 },
  },
  label: {
    fontFamily: font.mono,
    fontSize: 9.5,
    letterSpacing: letterSpacing.wider,
  },
});
