import React, { useState } from 'react';
import { Image, Pressable, StyleSheet, Text, View } from 'react-native';
import { ChamferView } from './ChamferView';
import { CornerBrackets } from './CornerBrackets';
import { APP_ICONS, AppGenericIcon } from './icons';
import { MacApp } from '../net/protocol';
import { chamfer, color, font, letterSpacing } from '../theme/tokens';

const CARD_HEIGHT = 108;
const ICON_SIZE = 30;

export interface AppTileProps {
  app: MacApp;
  /** Drives the magenta "live" styling — the frontmost/selected app. */
  active: boolean;
  /** Extra-muted styling for an app that isn't running at all. */
  dim?: boolean;
  /** Literal text shown in the status row — callers own the vocabulary
   * (ACTIVE/IDLE on the running-apps grid, ACTIVE/RUNNING/OFFLINE on the
   * launcher), so this isn't derived internally. */
  statusLabel: string;
  width: number;
  onPress: () => void;
  /** When set, long-pressing reveals an inline quit confirmation chip. */
  onQuit?: () => void;
}

/**
 * A workspace node card — icon, name, and live status laid out as a system
 * module row, not a centered icon-and-label home-screen tile. Width is
 * passed in by the screen (derived from the window width) since the
 * chamfer's SVG needs an explicit pixel size.
 */
export function AppTile({ app, active, dim = false, statusLabel, width, onPress, onQuit }: AppTileProps) {
  const [confirmingQuit, setConfirmingQuit] = useState(false);
  const canQuit = Boolean(onQuit);

  const iconColor = active ? color.magenta : dim ? color.muted1 : color.cyanDim;
  const labelColor = active ? color.white : dim ? color.muted2 : color.mutedLabel;
  const statusColor = active ? color.magenta : dim ? color.muted1 : color.muted2;
  const Icon = APP_ICONS[app.bundleId] ?? AppGenericIcon;

  const handlePress = () => {
    if (confirmingQuit) {
      setConfirmingQuit(false);
      return;
    }
    onPress();
  };

  const handleQuitConfirm = () => {
    setConfirmingQuit(false);
    onQuit?.();
  };

  return (
    <Pressable
      onPress={handlePress}
      onLongPress={canQuit ? () => setConfirmingQuit(true) : undefined}
      style={({ pressed }) => [{ width, height: CARD_HEIGHT }, pressed && styles.pressed]}
      hitSlop={6}
    >
      <View style={styles.cardWrap}>
        {active ? <CornerBrackets /> : null}
        <ChamferView
          width={width}
          height={CARD_HEIGHT}
          cut={chamfer.card}
          fill={active ? color.magentaDim : color.panelFill}
          borderColor={active ? color.magentaBorder : color.cyanBorder}
          glowColor={active ? color.magenta : undefined}
        >
          <View style={styles.row}>
            <View style={styles.iconSlot}>
              {app.iconPngBase64 ? (
                <Image
                  source={{ uri: `data:image/png;base64,${app.iconPngBase64}` }}
                  style={[styles.iconImage, dim && styles.iconDim]}
                  resizeMode="contain"
                />
              ) : (
                <Icon size={ICON_SIZE} color={iconColor} />
              )}
            </View>
            <View style={styles.textCol}>
              <Text numberOfLines={1} style={[styles.label, { color: labelColor }]}>
                {app.name}
              </Text>
              {confirmingQuit ? (
                <Pressable onPress={handleQuitConfirm} hitSlop={8} style={styles.quitChip}>
                  <Text style={styles.quitChipText}>QUIT ×</Text>
                </Pressable>
              ) : (
                <View style={styles.statusRow}>
                  <View style={[styles.statusDot, { backgroundColor: statusColor }]} />
                  <Text style={[styles.status, { color: statusColor }]}>{statusLabel}</Text>
                </View>
              )}
            </View>
          </View>
        </ChamferView>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  pressed: {
    transform: [{ scale: 0.97 }],
  },
  cardWrap: {
    width: '100%',
    height: '100%',
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
  iconImage: {
    width: 38,
    height: 38,
  },
  iconDim: {
    opacity: 0.4,
  },
  textCol: {
    flex: 1,
    gap: 7,
  },
  label: {
    fontFamily: font.bodySemiBold,
    fontSize: 14,
    letterSpacing: letterSpacing.label,
    textTransform: 'uppercase',
  },
  statusRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  statusDot: {
    width: 5,
    height: 5,
    borderRadius: 2.5,
  },
  status: {
    fontFamily: font.mono,
    fontSize: 10,
    letterSpacing: letterSpacing.wide,
  },
  quitChip: {
    alignSelf: 'flex-start',
    borderWidth: 1,
    borderColor: color.magentaBorder,
    backgroundColor: color.magentaDim,
    paddingHorizontal: 8,
    paddingVertical: 2,
  },
  quitChipText: {
    fontFamily: font.monoBold,
    fontSize: 9.5,
    letterSpacing: letterSpacing.wide,
    color: color.magenta,
  },
});
