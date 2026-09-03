import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import React from 'react';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { AppTile } from '../components/AppTile';
import { GlitchText } from '../components/GlitchText';
import { TabPrevIcon } from '../components/icons';
import { PulseDot } from '../components/PulseDot';
import { ScreenBackground } from '../components/ScreenBackground';
import { SignalBars } from '../components/SignalBars';
import { useResponsiveGrid } from '../hooks/useResponsiveGrid';
import { ActiveStackParamList } from '../navigation/ActiveStack';
import { useMacLink } from '../net/MacLinkContext';
import { MacApp } from '../net/protocol';
import { color, font, letterSpacing } from '../theme/tokens';

const IDEAL_CARD_WIDTH = 170;

/**
 * Every installed app on the Mac, not just running ones. Tapping one
 * activates it if it's already running, or launches it if it isn't —
 * unlike Active Nodes, which only ever shows apps that are already open.
 * Pushed from the Active tab's Built-in Apps row (see
 * modules/builtInApps.ts) rather than being its own tab — hence the back
 * row here, same pattern as BuiltInAppScreen.
 */
export function AllNodesScreen() {
  const insets = useSafeAreaInsets();
  const navigation = useNavigation<NativeStackNavigationProp<ActiveStackParamList, 'AllApps'>>();
  const { numColumns, cardWidth, horizontalPadding } = useResponsiveGrid(IDEAL_CARD_WIDTH);

  const { discoveryStatus, deviceName, connectionStatus, installedApps, openApp, closeApp } =
    useMacLink();

  const linked = connectionStatus === 'open';
  const deviceLabel = linked
    ? (deviceName ?? 'MACBOOK').toUpperCase()
    : discoveryStatus === 'error'
      ? 'LINK ERROR'
      : 'RECONNECTING…';

  const renderItem = ({ item }: { item: MacApp }) => {
    const statusLabel = item.isFrontmost ? 'ACTIVE' : item.isRunning ? 'RUNNING' : 'OFFLINE';
    return (
      <AppTile
        app={item}
        active={item.isFrontmost}
        dim={!item.isRunning}
        statusLabel={statusLabel}
        width={cardWidth}
        onPress={() => openApp(item.bundleId)}
        onQuit={item.isRunning ? () => closeApp(item.bundleId) : undefined}
      />
    );
  };

  return (
    <ScreenBackground>
      <View style={{ paddingTop: insets.top }}>
        <Pressable onPress={navigation.goBack} style={[styles.backRow, horizontalPadding]} hitSlop={10}>
          <TabPrevIcon size={18} color={color.cyan} strokeWidth={2} />
          <Text style={styles.backText}>BACK</Text>
        </Pressable>

        <View style={[styles.hudRow, horizontalPadding]}>
          <View style={styles.linkGroup}>
            <PulseDot tint={linked ? color.cyan : color.muted1} />
            <Text style={styles.linkText}>LINK // {deviceLabel}</Text>
          </View>
          {linked ? <SignalBars /> : null}
        </View>

        <View style={[styles.titleBlock, horizontalPadding]}>
          <GlitchText style={styles.title} glowColor={color.cyan}>
            ALL NODES
          </GlitchText>
          <Text style={styles.subtitle}>
            {linked ? 'TAP TO LAUNCH :: HOLD TO QUIT' : 'RE-ESTABLISHING LINK…'}
          </Text>
        </View>
      </View>

      {linked && installedApps.length > 0 ? (
        <FlatList
          // FlatList can't change numColumns on the fly — remount when the
          // orientation/width change alters how many columns fit.
          key={numColumns}
          data={installedApps}
          keyExtractor={(app) => app.bundleId}
          renderItem={renderItem}
          numColumns={numColumns}
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
  backRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingTop: 14,
    paddingBottom: 4,
  },
  backText: {
    fontFamily: font.mono,
    fontSize: 11,
    letterSpacing: letterSpacing.wide,
    color: color.cyan,
  },
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
