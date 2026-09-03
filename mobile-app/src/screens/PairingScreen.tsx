import React, { useState } from 'react';
import { ActivityIndicator, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { ChamferView } from '../components/ChamferView';
import { GlitchText } from '../components/GlitchText';
import { PulseDot } from '../components/PulseDot';
import { ScreenBackground } from '../components/ScreenBackground';
import { useMacLink } from '../net/MacLinkContext';
import { chamfer, color, font, letterSpacing } from '../theme/tokens';

const CODE_LENGTH = 6;

/**
 * Blocking screen shown between a successful WebSocket connection and
 * actual trust — the Mac doesn't recognize this device's id yet (see
 * DevicePairing.swift) and is showing a one-time code in a system
 * notification (or its menu bar, as a fallback). Nothing else in the app
 * is reachable while this is up; see MacLinkContext's pairingRequired.
 */
export function PairingScreen() {
  const { pairingError, submitPairingCode, connectionStatus } = useMacLink();
  const [code, setCode] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const canSubmit = code.length === CODE_LENGTH && connectionStatus === 'open';

  const handleChange = (text: string) => {
    setCode(text.replace(/[^0-9]/g, '').slice(0, CODE_LENGTH));
    setSubmitting(false);
  };

  const handleSubmit = () => {
    if (!canSubmit) return;
    setSubmitting(true);
    submitPairingCode(code);
  };

  return (
    <ScreenBackground>
      <View style={styles.center}>
        <PulseDot tint={color.cyan} />

        <GlitchText style={styles.title} glowColor={color.cyan}>
          PAIR THIS DEVICE
        </GlitchText>

        <Text style={styles.subtitle}>ENTER THE CODE SHOWN ON YOUR MAC</Text>
        <Text style={styles.hint}>Check for a notification, or the Overwatch Node menu bar icon.</Text>

        <TextInput
          value={code}
          onChangeText={handleChange}
          keyboardType="number-pad"
          maxLength={CODE_LENGTH}
          autoFocus
          style={styles.codeInput}
          placeholder="000000"
          placeholderTextColor={color.muted1}
        />

        {pairingError ? <Text style={styles.error}>{pairingError.toUpperCase()}</Text> : null}

        <Pressable onPress={handleSubmit} disabled={!canSubmit} hitSlop={8}>
          {({ pressed }) => (
            <View style={pressed && canSubmit ? styles.pressed : null}>
              <ChamferView
                width={180}
                height={54}
                cut={chamfer.card}
                fill={canSubmit ? color.magentaDim : color.panelFill}
                borderColor={canSubmit ? color.magentaBorder : color.cyanBorder}
                glowColor={canSubmit ? color.magenta : undefined}
              >
                {submitting && !pairingError ? (
                  <ActivityIndicator color={color.magenta} />
                ) : (
                  <Text style={[styles.buttonLabel, { color: canSubmit ? color.white : color.muted2 }]}>PAIR</Text>
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
    gap: 16,
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
  hint: {
    fontFamily: font.mono,
    fontSize: 10,
    letterSpacing: letterSpacing.mono,
    color: color.muted3,
    textAlign: 'center',
    marginBottom: 4,
  },
  codeInput: {
    fontFamily: font.displayBlack,
    fontSize: 30,
    letterSpacing: 12,
    color: color.text,
    textAlign: 'center',
    minWidth: 220,
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: color.cyanBorder,
  },
  error: {
    fontFamily: font.mono,
    fontSize: 11,
    letterSpacing: letterSpacing.mono,
    color: color.magenta,
    textAlign: 'center',
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
