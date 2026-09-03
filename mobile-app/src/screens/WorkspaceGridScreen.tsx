import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import React from 'react';
import { FlatList, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { AppTile } from '../components/AppTile';
import { BuiltInAppCard } from '../components/BuiltInAppCard';
import { GlitchText } from '../components/GlitchText';
import { PulseDot } from '../components/PulseDot';
import { ScreenBackground } from '../components/ScreenBackground';
import { SignalBars } from '../components/SignalBars';
import { useResponsiveGrid } from '../hooks/useResponsiveGrid';
import { BUILT_IN_APPS } from '../modules/builtInApps';
import { ActiveStackParamList } from '../navigation/ActiveStack';
import { useMacLink } from '../net/MacLinkContext';
import { MacApp } from '../net/protocol';
import { color, font, letterSpacing } from '../theme/tokens';

type Nav = NativeStackNavigationProp<ActiveStackParamList, 'WorkspaceGrid'>;

// Target width for a card — the actual column count adapts to fit this,
// rather than a hardcoded number, so landscape (or a tablet) doesn't just
// stretch a fixed column count into oversized cards.
const IDEAL_CARD_WIDTH = 170;

export function WorkspaceGridScreen() {
  const insets = useSafeAreaInsets();
  const navigation = useNavigation<Nav>();
  const { numColumns, cardWidth, horizontalPadding } = useResponsiveGrid(IDEAL_CARD_WIDTH, {
    maxColumnsLandscape: 4,
  });

  const { discoveryStatus, deviceName, connectionStatus, apps, activeBundleId, activateApp, closeApp } =
    useMacLink();

  const linked = connectionStatus === 'open';
  const deviceLabel = linked
    ? (deviceName ?? 'MACBOOK').toUpperCase()
    : discoveryStatus === 'error'
      ? 'LINK ERROR'
      : 'RECONNECTING…';

  const renderItem = ({ item }: { item: MacApp }) => {
    const active = item.bundleId === activeBundleId;
    return (
      <AppTile
        app={item}
        active={active}
        statusLabel={active ? 'ACTIVE' : 'IDLE'}
        width={cardWidth}
        onPress={() => activateApp(item.bundleId)}
        onQuit={() => closeApp(item.bundleId)}
      />
    );
  };

  return (
    <ScreenBackground>
      <View style={{ paddingTop: insets.top }}>
        <View style={[styles.hudRow, horizontalPadding]}>
          <View style={styles.linkGroup}>
            <PulseDot tint={linked ? color.cyan : color.muted1} />
            <Text style={styles.linkText}>LINK // {deviceLabel}</Text>
          </View>
          {linked ? <SignalBars /> : null}
        </View>

        <View style={[styles.titleBlock, horizontalPadding]}>
          <GlitchText style={styles.title} glowColor={color.cyan}>
            ACTIVE NODES
          </GlitchText>
          <Text style={styles.subtitle}>
            {linked ? 'TAP TO FOCUS :: HOLD TO QUIT' : 'RE-ESTABLISHING LINK…'}
          </Text>
        </View>

        {linked ? (
          <View style={[styles.builtInSection, horizontalPadding]}>
            <Text style={styles.sectionLabel}>BUILT-IN</Text>
            <View style={styles.builtInRow}>
              {BUILT_IN_APPS.map((app) => (
                <BuiltInAppCard
                  key={app.id}
                  displayName={app.displayName}
                  Icon={app.Icon}
                  width={cardWidth}
                  onPress={() =>
                    app.kind === 'sections'
                      ? navigation.navigate('BuiltInApp', { appId: app.id })
                      : navigation.navigate(app.route)
                  }
                />
              ))}
            </View>
          </View>
        ) : null}
      </View>

      {linked && apps.length > 0 ? (
        <FlatList
          // FlatList can't change numColumns on the fly — remount when the
          // orientation/width change alters how many columns fit.
          key={numColumns}
          data={apps}
          keyExtractor={(app) => app.bundleId}
          renderItem={renderItem}
          numColumns={numColumns}
          ListHeaderComponent={<Text style={[styles.sectionLabel, styles.runningLabel]}>RUNNING</Text>}
          contentContainerStyle={[styles.grid, horizontalPadding]}
          columnWrapperStyle={styles.column}
        />
      ) : (
        <View style={styles.emptyState}>
          <Text style={styles.emptyText}>
            {discoveryStatus === 'error'
              ? 'NO SIGNAL — CHECK MAC APP IS RUNNING'
              : linked
                ? 'NO APPS REPORTED'
                : 'RECONNECTING TO MACBOOK…'}
          </Text>
        </View>
      )}
    </ScreenBackground>
  );
}

const styles = StyleSheet.create({
  hudRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  linkGroup: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  linkText: {
    fontFamily: font.mono,
    fontSize: 10.5,
    letterSpacing: letterSpacing.wide,
    color: color.cyan,
  },
  titleBlock: {
    paddingTop: 18,
    paddingBottom: 6,
  },
  title: {
    fontFamily: font.displayBlack,
    fontSize: 21,
    letterSpacing: 0.03 * 21,
    color: color.text,
  },
  subtitle: {
    fontFamily: font.mono,
    fontSize: 10,
    color: color.muted3,
    letterSpacing: letterSpacing.mono,
    marginTop: 5,
  },
  builtInSection: {
    paddingTop: 8,
    paddingBottom: 16,
    gap: 10,
  },
  builtInRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 14,
  },
  sectionLabel: {
    fontFamily: font.bodySemiBold,
    fontSize: 12,
    letterSpacing: letterSpacing.label,
    color: color.mutedLabel,
    textTransform: 'uppercase',
  },
  runningLabel: {
    marginBottom: 10,
  },
  grid: {
    paddingTop: 10,
    paddingBottom: 6,
    gap: 14,
  },
  column: {
    justifyContent: 'flex-start',
    gap: 14,
  },
  emptyState: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 40,
  },
  emptyText: {
    fontFamily: font.mono,
    fontSize: 11,
    color: color.muted3,
    letterSpacing: letterSpacing.mono,
    textAlign: 'center',
  },
});
