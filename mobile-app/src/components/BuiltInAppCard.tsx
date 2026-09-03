import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { ChamferView } from './ChamferView';
import { IconProps } from './icons';
import { chamfer, color, font, letterSpacing } from '../theme/tokens';

const CARD_HEIGHT = 108;
const ICON_SIZE = 30;

/**
 * A built-in app card (see modules/builtInApps.ts) — same card language as
 * AppTile, but simpler: no running/active/dim states or quit gesture,
 * since these aren't Mac processes, just always-available control panels.
 */
export function BuiltInAppCard({
  displayName,
  Icon,
  width,
  onPress,
}: {
  displayName: string;
  Icon: React.ComponentType<IconProps>;
  width: number;
  onPress: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [{ width, height: CARD_HEIGHT }, pressed && styles.pressed]}
      hitSlop={6}
    >
      <ChamferView
        width={width}
        height={CARD_HEIGHT}
        cut={chamfer.card}
        fill={color.panelFill}
        borderColor={color.cyanBorder}
      >
        <View style={styles.row}>
          <View style={styles.iconSlot}>
            <Icon size={ICON_SIZE} color={color.cyanDim} />
          </View>
          <View style={styles.textCol}>
            <Text numberOfLines={2} style={styles.label}>
              {displayName.toUpperCase()}
            </Text>
          </View>
        </View>
      </ChamferView>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  pressed: {
    transform: [{ scale: 0.97 }],
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    width: '100%',
    height: '100%',
    paddingHorizontal: 16,
    gap: 14,
  },
  iconSlot: {
    width: ICON_SIZE + 10,
    height: ICON_SIZE + 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  textCol: {
    flex: 1,
  },
  label: {
    fontFamily: font.bodySemiBold,
    fontSize: 13,
    lineHeight: 16,
    letterSpacing: letterSpacing.label,
    color: color.mutedLabel,
    textTransform: 'uppercase',
  },
});
