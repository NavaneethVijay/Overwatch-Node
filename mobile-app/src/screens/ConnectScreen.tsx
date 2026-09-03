import React from 'react';
import { ActivityIndicator, Pressable, StyleSheet, Text, View } from 'react-native';
import { ChamferView } from '../components/ChamferView';
import { GlitchText } from '../components/GlitchText';
import { PulseDot } from '../components/PulseDot';
import { ScreenBackground } from '../components/ScreenBackground';
import { useMacLink } from '../net/MacLinkContext';
import { chamfer, color, font, letterSpacing } from '../theme/tokens';

/**
 * Gates entry to the app: scans for the Mac over the local network and
 * requires an explicit tap to connect, rather than silently auto-connecting.
 * Shown only until the first successful connection — see MacLinkProvider.
 */
export function ConnectScreen() {
  const { discoveryStatus, deviceName, connectionStatus, connect } = useMacLink();

  const found = discoveryStatus === 'found';
  const connecting = connectionStatus === 'connecting';
  const canConnect = found && !connecting;

  const statusLine =
    discoveryStatus === 'error'
      ? 'NO SIGNAL — IS THE MAC APP RUNNING?'
      : found
        ? `NODE FOUND :: ${(deviceName ?? 'MACBOOK').toUpperCase()}`
        : 'SCANNING LOCAL NETWORK…';

  return (
    <ScreenBackground>
      <View style={styles.center}>
        <PulseDot tint={found ? color.cyan : color.muted1} />

        <GlitchText style={styles.title} glowColor={color.cyan}>
          ESTABLISH LINK
        </GlitchText>

        <Text style={styles.subtitle}>CONNECT TO YOUR MACBOOK TO CONTINUE</Text>
        <Text style={styles.status}>{statusLine}</Text>

        <Pressable onPress={connect} disabled={!canConnect} hitSlop={8}>
          {({ pressed }) => (
            <View style={pressed && canConnect ? styles.pressed : null}>
              <ChamferView
                width={210}
                height={54}
                cut={chamfer.card}
                fill={canConnect ? color.magentaDim : color.panelFill}
                borderColor={canConnect ? color.magentaBorder : color.cyanBorder}
                glowColor={canConnect ? color.magenta : undefined}
              >
                {connecting ? (
                  <ActivityIndicator color={color.magenta} />
                ) : (
                  <Text style={[styles.buttonLabel, { color: canConnect ? color.white : color.muted2 }]}>
                    {found ? 'CONNECT' : 'WAITING…'}
                  </Text>
                )}
              </ChamferView>
            </View>
          )}
        </Pressable>
      </View>
    </ScreenBackground>
  );
}

const styles = StyleSheet.create({
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 18,
    paddingHorizontal: 32,
  },
  title: {
    fontFamily: font.displayBlack,
    fontSize: 22,
    letterSpacing: 0.03 * 22,
    color: color.text,
    textAlign: 'center',
  },
  subtitle: {
    fontFamily: font.mono,
    fontSize: 10.5,
    letterSpacing: letterSpacing.wide,
    color: color.muted3,
    textAlign: 'center',
    marginTop: -8,
  },
  status: {
    fontFamily: font.mono,
    fontSize: 11,
    letterSpacing: letterSpacing.mono,
    color: color.cyan,
    textAlign: 'center',
    marginBottom: 6,
  },
  pressed: {
    transform: [{ scale: 0.97 }],
  },
  buttonLabel: {
    fontFamily: font.bodyBold,
    fontSize: 13,
    letterSpacing: letterSpacing.wide,
  },
});
