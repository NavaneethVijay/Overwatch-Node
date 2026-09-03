import React, { useState } from 'react';
import { Image, Pressable, StyleSheet, Text, useWindowDimensions, View } from 'react-native';
import { ChamferView } from './ChamferView';
import { CornerBrackets } from './CornerBrackets';
import { AppGenericIcon, MODULE_ICONS, TabsListIcon } from './icons';
import { DynamicListItem, ModuleAction, ModuleControl, ModuleSection } from '../net/protocol';
import { chamfer, color, font, letterSpacing } from '../theme/tokens';

/**
 * Renders one module's sections/controls (buttons + dynamic lists) from the
 * shared ModuleSection/ModuleControl schema. Originally lived in
 * ModuleScreen.tsx (the per-frontmost-app Contextual Controls renderer) —
 * pulled out here so the built-in Window Management tab can reuse the exact
 * same button-grid rendering for its own static, non-app-driven sections
 * without pulling in any of ModuleScreen's activeModule/bundleId plumbing.
 */
export function ModuleSectionView({
  section,
  dynamicData,
  buttonWidth,
  contentWidth,
  onInvoke,
  localActiveByProvider,
  onSelectListItem,
}: {
  section: ModuleSection;
  dynamicData: Record<string, DynamicListItem[]>;
  buttonWidth: number;
  contentWidth: number;
  onInvoke: (action: ModuleAction) => void;
  localActiveByProvider: Record<string, string>;
  onSelectListItem: (provider: string, id: string) => void;
}) {
  return (
    <View style={styles.section}>
      <Text style={styles.sectionLabel}>{section.title.toUpperCase()}</Text>
      <View style={styles.buttonRow}>
        {section.controls.map((control, index) =>
          control.type === 'button' ? (
            <ModuleButton
              key={index}
              control={control}
              width={buttonWidth}
              onPress={() => control.action && onInvoke(control.action)}
            />
          ) : (
            <ModuleDynamicList
              key={index}
              control={control}
              items={(control.provider && dynamicData[control.provider]) || []}
              width={contentWidth}
              onInvoke={onInvoke}
              localActiveId={control.provider ? localActiveByProvider[control.provider] : undefined}
              onSelectListItem={onSelectListItem}
            />
          ),
        )}
      </View>
    </View>
  );
}

const BUTTON_HEIGHT_PORTRAIT = 96;
// Landscape already gets wider buttons for free (buttonWidth is
// contentWidth / a fixed column count, and contentWidth grows with screen
// width) — without a taller height to match, that leaves flat, elongated
// buttons instead of properly proportioned big touch targets. This is
// explicitly a "fast touch access" grid (Stream Deck-style quick taps),
// so landscape goes noticeably bigger, not just proportionally bigger.
const BUTTON_HEIGHT_LANDSCAPE = 140;

function ModuleButton({
  control,
  width,
  onPress,
}: {
  control: ModuleControl;
  width: number;
  onPress: () => void;
}) {
  const { width: windowWidth, height: windowHeight } = useWindowDimensions();
  const buttonHeight = windowWidth > windowHeight ? BUTTON_HEIGHT_LANDSCAPE : BUTTON_HEIGHT_PORTRAIT;
  const Icon = (control.icon && MODULE_ICONS[control.icon]) || AppGenericIcon;
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [{ width, height: buttonHeight }, pressed && styles.pressed]}
    >
      <ChamferView
        width={width}
        height={buttonHeight}
        cut={chamfer.card}
        fill={color.panelFill}
        borderColor={color.cyanBorder}
      >
        <View style={styles.buttonContent}>
          <Icon size={24} color={color.cyan} />
          <Text style={styles.buttonLabel} numberOfLines={1}>
            {(control.label ?? '').toUpperCase()}
          </Text>
        </View>
      </ChamferView>
    </Pressable>
  );
}

const TAB_COLUMNS = 2;
const TAB_GAP = 12;
const TAB_CARD_HEIGHT = 108;
const TAB_FAVICON_SIZE = 20;

function ModuleDynamicList({
  control,
  items,
  width,
  onInvoke,
  localActiveId,
  onSelectListItem,
}: {
  control: ModuleControl;
  items: DynamicListItem[];
  width: number;
  onInvoke: (action: ModuleAction) => void;
  localActiveId?: string;
  onSelectListItem: (provider: string, id: string) => void;
}) {
  if (items.length === 0) {
    return <Text style={styles.emptyListText}>NOTHING TO SHOW</Text>;
  }

  const cardWidth = (width - TAB_GAP * (TAB_COLUMNS - 1)) / TAB_COLUMNS;
  const FallbackIcon = (control.icon && MODULE_ICONS[control.icon]) || TabsListIcon;

  // Only trust the local override once the item it points at is still in
  // this refresh's list — otherwise (e.g. that tab got closed) fall back to
  // whatever the server reports instead of highlighting nothing.
  const hasLocalOverride = localActiveId != null && items.some((item) => item.id === localActiveId);

  return (
    <View style={styles.tabGrid}>
      {items.map((item) => (
        <TabCard
          key={item.id}
          item={item}
          active={hasLocalOverride ? item.id === localActiveId : item.active}
          width={cardWidth}
          FallbackIcon={FallbackIcon}
          onPress={() => {
            if (!control.itemAction) return;
            if (control.provider) onSelectListItem(control.provider, item.id);
            onInvoke({ ...control.itemAction, params: { id: item.id } });
          }}
        />
      ))}
    </View>
  );
}

function TabCard({
  item,
  active,
  width,
  FallbackIcon,
  onPress,
}: {
  item: DynamicListItem;
  active: boolean;
  width: number;
  FallbackIcon: React.ComponentType<{ size?: number; color?: string }>;
  onPress: () => void;
}) {
  const labelColor = active ? color.white : color.mutedLabel;
  const statusColor = active ? color.magenta : color.muted2;

  return (
    <Pressable onPress={onPress} style={({ pressed }) => [{ width, height: TAB_CARD_HEIGHT }, pressed && styles.pressed]}>
      <View style={styles.tabCardWrap}>
        {/* "Active" is either the server's report or a locally-tapped
         * override (see ModuleScreen's localActiveByProvider) — corner
         * brackets + magenta border/glow match how AppTile highlights the
         * frontmost app elsewhere in the app, so the "live" one reads the
         * same way everywhere. */}
        {active ? <CornerBrackets /> : null}
        <ChamferView
          width={width}
          height={TAB_CARD_HEIGHT}
          cut={chamfer.card}
          fill={active ? color.magentaDim : color.panelFill}
          borderColor={active ? color.magentaBorder : color.cyanBorder}
          glowColor={active ? color.magenta : undefined}
        >
          <View style={styles.tabCardCol}>
            <View style={styles.tabTopRow}>
              <TabFavicon
                url={item.url}
                size={TAB_FAVICON_SIZE}
                tint={active ? color.magenta : color.cyanDim}
                FallbackIcon={FallbackIcon}
              />
              <View style={[styles.statusDot, { backgroundColor: statusColor }]} />
            </View>
            <Text numberOfLines={2} style={[styles.tabTitle, { color: labelColor }]}>
              {item.title}
            </Text>
          </View>
        </ChamferView>
      </View>
    </Pressable>
  );
}

/** The real site favicon, matching what you'd see in the actual browser's
 * tab strip — falls back to the control's declared icon (or the generic
 * tabs glyph) if there's no URL or the favicon fails to load, so a
 * non-browser dynamic list (e.g. git status, npm scripts) doesn't show a
 * mismatched browser-tabs icon. */
function TabFavicon({
  url,
  size,
  tint,
  FallbackIcon,
}: {
  url: string;
  size: number;
  tint: string;
  FallbackIcon: React.ComponentType<{ size?: number; color?: string }>;
}) {
  const [failed, setFailed] = useState(false);

  if (!url || failed) {
    return <FallbackIcon size={size} color={tint} />;
  }

  return (
    <Image
      source={{ uri: `https://www.google.com/s2/favicons?sz=64&domain_url=${encodeURIComponent(url)}` }}
      style={{ width: size, height: size }}
      onError={() => setFailed(true)}
    />
  );
}

const styles = StyleSheet.create({
  section: {
    gap: 12,
  },
  sectionLabel: {
    fontFamily: font.bodySemiBold,
    fontSize: 12,
    letterSpacing: letterSpacing.label,
    color: color.mutedLabel,
    textTransform: 'uppercase',
  },
  buttonRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  pressed: {
    transform: [{ scale: 0.97 }],
  },
  buttonContent: {
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  buttonLabel: {
    fontFamily: font.bodySemiBold,
    fontSize: 11,
    letterSpacing: letterSpacing.label,
    color: color.text,
  },
  tabGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: TAB_GAP,
  },
  tabCardWrap: {
    width: '100%',
    height: '100%',
  },
  tabCardCol: {
    width: '100%',
    height: '100%',
    padding: 14,
    justifyContent: 'space-between',
  },
  tabTopRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  tabTitle: {
    fontFamily: font.bodySemiBold,
    fontSize: 13,
    lineHeight: 17,
  },
  statusDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  emptyListText: {
    fontFamily: font.mono,
    fontSize: 11,
    color: color.muted3,
    letterSpacing: letterSpacing.mono,
  },
});
