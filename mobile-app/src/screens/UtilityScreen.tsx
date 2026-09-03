import React, { useEffect, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, useWindowDimensions, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { ChamferView } from '../components/ChamferView';
import { GlitchText } from '../components/GlitchText';
import { HSlider } from '../components/HSlider';
import { BluetoothIcon, LockIcon, PowerIcon, SpeakerIcon, SunIcon, ViewfinderIcon } from '../components/icons';
import { PulseDot } from '../components/PulseDot';
import { ScreenBackground } from '../components/ScreenBackground';
import { SignalBars } from '../components/SignalBars';
import { useMacLink } from '../net/MacLinkContext';
import { chamfer, color, font, letterSpacing } from '../theme/tokens';

/**
 * Real system-level controls, not media playback — brightness and volume
 * here are the Mac's actual hardware/output levels (see macos-app's
 * SystemUtility.swift), distinct from the Music tab's per-track transport
 * controls.
 */
const H_PAD = 22;

export function UtilityScreen() {
  const insets = useSafeAreaInsets();
  const { width: windowWidth } = useWindowDimensions();
  const contentWidth = windowWidth - H_PAD * 2;
  const {
    discoveryStatus,
    deviceName,
    connectionStatus,
    brightness,
    setBrightness,
    volume,
    setVolume,
    bluetoothDevices,
    requestBluetooth,
    triggerScreenshot,
    triggerLockScreen,
    triggerShutdown,
  } = useMacLink();

  const linked = connectionStatus === 'open';
  const deviceLabel = linked
    ? (deviceName ?? 'MACBOOK').toUpperCase()
    : discoveryStatus === 'error'
      ? 'LINK ERROR'
      : 'RECONNECTING…';

  const [justCaptured, setJustCaptured] = useState(false);
  useEffect(() => {
    if (!justCaptured) return;
    const timer = setTimeout(() => setJustCaptured(false), 1600);
    return () => clearTimeout(timer);
  }, [justCaptured]);

  const handleScreenshot = () => {
    triggerScreenshot();
    setJustCaptured(true);
  };

  // Shutdown needs a deliberate second tap — unlike everything else on this
  // screen it isn't reversible from the phone. Arming auto-cancels after a
  // few seconds so a stray re-open of the app doesn't leave it primed.
  const [confirmingShutdown, setConfirmingShutdown] = useState(false);
  useEffect(() => {
    if (!confirmingShutdown) return;
    const timer = setTimeout(() => setConfirmingShutdown(false), 4000);
    return () => clearTimeout(timer);
  }, [confirmingShutdown]);

  const handleShutdownPress = () => {
    if (confirmingShutdown) {
      setConfirmingShutdown(false);
      triggerShutdown();
    } else {
      setConfirmingShutdown(true);
    }
  };

  return (
    <ScreenBackground>
      <View style={{ paddingTop: insets.top }}>
        <View style={[styles.hudRow, styles.hPad]}>
          <View style={styles.linkGroup}>
            <PulseDot tint={linked ? color.cyan : color.muted1} />
            <Text style={styles.linkText}>LINK // {deviceLabel}</Text>
          </View>
          {linked ? <SignalBars /> : null}
        </View>

        <View style={[styles.titleBlock, styles.hPad]}>
          <GlitchText style={styles.title} glowColor={color.cyan}>
            SYSTEM UTILITY
          </GlitchText>
          <Text style={styles.subtitle}>
            {linked ? 'LIVE SYSTEM CONTROLS' : 'RE-ESTABLISHING LINK…'}
          </Text>
        </View>
      </View>

      <ScrollView
        style={styles.hPad}
        contentContainerStyle={styles.scroll}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <SunIcon size={16} color={color.cyan} opacity={0.9} />
            <Text style={styles.sectionLabel}>BRIGHTNESS</Text>
            <Text style={styles.sectionValue}>{brightness ?? '--'}%</Text>
          </View>
          <HSlider value={brightness ?? 0} onChange={setBrightness} height={6} />
        </View>

        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <SpeakerIcon size={16} color={color.cyan} />
            <Text style={styles.sectionLabel}>VOLUME</Text>
            <Text style={styles.sectionValue}>{volume ?? '--'}%</Text>
          </View>
          <HSlider value={volume ?? 0} onChange={setVolume} height={6} />
        </View>

        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <ViewfinderIcon size={16} color={color.cyan} />
            <Text style={styles.sectionLabel}>SCREENSHOT</Text>
          </View>
          <Pressable onPress={handleScreenshot}>
            {({ pressed }) => (
              <View style={pressed ? styles.pressed : null}>
                <ChamferView
                  width={contentWidth}
                  height={68}
                  cut={chamfer.card}
                  fill={justCaptured ? color.magentaDim : color.panelFill}
                  borderColor={justCaptured ? color.magentaBorder : color.cyanBorder}
                  glowColor={justCaptured ? color.magenta : undefined}
                >
                  <View style={styles.screenshotButtonContent}>
                    <ViewfinderIcon size={20} color={justCaptured ? color.magenta : color.text} />
                    <Text
                      style={[styles.buttonLabel, { color: justCaptured ? color.magenta : color.text }]}
                    >
                      {justCaptured ? 'TRIGGERED ✓' : 'OPEN SCREENSHOT TOOL'}
                    </Text>
                  </View>
                </ChamferView>
              </View>
            )}
          </Pressable>
        </View>

        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <BluetoothIcon size={16} color={color.cyan} />
            <Text style={styles.sectionLabel}>BLUETOOTH</Text>
            <Pressable onPress={requestBluetooth} hitSlop={8}>
              <Text style={styles.refreshText}>REFRESH</Text>
            </Pressable>
          </View>
          {bluetoothDevices.length === 0 ? (
            <Text style={styles.emptyText}>NO DEVICES CONNECTED</Text>
          ) : (
            <View style={styles.deviceList}>
              {bluetoothDevices.map((device) => (
                <View key={device.name} style={styles.deviceRow}>
                  <View style={styles.deviceDot} />
                  <Text style={styles.deviceName} numberOfLines={1}>
                    {device.name}
                  </Text>
                </View>
              ))}
            </View>
          )}
        </View>

        <View style={[styles.section, styles.lastSection]}>
          <View style={styles.sectionHeader}>
            <PowerIcon size={16} color={color.cyan} />
            <Text style={styles.sectionLabel}>SYSTEM POWER</Text>
          </View>

          <Pressable onPress={triggerLockScreen}>
            {({ pressed }) => (
              <View style={pressed ? styles.pressed : null}>
                <ChamferView width={contentWidth} height={68} cut={chamfer.card} fill={color.panelFill} borderColor={color.cyanBorder}>
                  <View style={styles.screenshotButtonContent}>
                    <LockIcon size={20} color={color.text} />
                    <Text style={[styles.buttonLabel, { color: color.text }]}>LOCK SCREEN</Text>
                  </View>
                </ChamferView>
              </View>
            )}
          </Pressable>

          <Pressable onPress={handleShutdownPress}>
            {({ pressed }) => (
              <View style={pressed ? styles.pressed : null}>
                <ChamferView
                  width={contentWidth}
                  height={68}
                  cut={chamfer.card}
                  fill={confirmingShutdown ? color.magentaDim : color.panelFill}
                  borderColor={confirmingShutdown ? color.magentaBorder : color.cyanBorder}
                  glowColor={confirmingShutdown ? color.magenta : undefined}
                >
                  <View style={styles.screenshotButtonContent}>
                    <PowerIcon size={20} color={confirmingShutdown ? color.magenta : color.text} />
                    <Text
                      style={[styles.buttonLabel, { color: confirmingShutdown ? color.magenta : color.text }]}
                    >
                      {confirmingShutdown ? 'TAP AGAIN TO SHUT DOWN' : 'SHUT DOWN'}
                    </Text>
                  </View>
                </ChamferView>
              </View>
            )}
          </Pressable>
        </View>
      </ScrollView>
    </ScreenBackground>
  );
}

const styles = StyleSheet.create({
  hPad: {
    paddingHorizontal: H_PAD,
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
  scroll: {
    paddingTop: 14,
    paddingBottom: 30,
    gap: 26,
  },
  section: {
    gap: 12,
  },
  lastSection: {
    paddingBottom: 6,
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  sectionLabel: {
    flex: 1,
    fontFamily: font.bodySemiBold,
    fontSize: 12,
    letterSpacing: letterSpacing.label,
    color: color.mutedLabel,
    textTransform: 'uppercase',
  },
  sectionValue: {
    fontFamily: font.monoBold,
    fontSize: 13,
    letterSpacing: letterSpacing.wide,
    color: color.cyan,
  },
  pressed: {
    transform: [{ scale: 0.98 }],
  },
  screenshotButtonContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 10,
  },
  buttonLabel: {
    fontFamily: font.bodyBold,
    fontSize: 14,
    letterSpacing: letterSpacing.wide,
  },
  refreshText: {
    fontFamily: font.monoBold,
    fontSize: 9.5,
    letterSpacing: letterSpacing.wide,
    color: color.cyan,
  },
  emptyText: {
    fontFamily: font.mono,
    fontSize: 11,
    color: color.muted3,
    letterSpacing: letterSpacing.mono,
  },
  deviceList: {
    gap: 10,
  },
  deviceRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  deviceDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: color.cyan,
  },
  deviceName: {
    fontFamily: font.bodyMedium,
    fontSize: 13,
    color: color.mutedLabel,
    flexShrink: 1,
  },
});
