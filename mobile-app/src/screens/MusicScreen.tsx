import React from 'react';
import { Image, Pressable, StyleSheet, Text, View, useWindowDimensions } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { ChamferView } from '../components/ChamferView';
import { CornerBrackets } from '../components/CornerBrackets';
import { GlitchText } from '../components/GlitchText';
import { MusicIcon, PauseIcon, PlayIcon, SkipBackIcon, SkipForwardIcon } from '../components/icons';
import { PulseDot } from '../components/PulseDot';
import { ScreenBackground } from '../components/ScreenBackground';
import { SignalBars } from '../components/SignalBars';
import { useMacLink } from '../net/MacLinkContext';
import { chamfer, color, font, letterSpacing } from '../theme/tokens';

const H_PAD = 22;
const ART_FRAME_SIZE = 260;
const TRANSPORT_SIZE = 62;
const PLAY_SIZE = 78;

/**
 * Now Playing + transport controls — any source (Music, Spotify, a browser
 * tab, ...), not just Apple Music, via the Mac's MediaRemote-through-perl
 * trick (see macos-app's NowPlaying.swift). Polled every 4s on the Mac side;
 * this screen just renders whatever `nowPlaying` currently holds.
 */
export function MusicScreen() {
  const insets = useSafeAreaInsets();

  const { discoveryStatus, deviceName, connectionStatus, nowPlaying, mediaPlayPause, mediaNext, mediaPrevious } =
    useMacLink();

  const linked = connectionStatus === 'open';
  const deviceLabel = linked
    ? (deviceName ?? 'MACBOOK').toUpperCase()
    : discoveryStatus === 'error'
      ? 'LINK ERROR'
      : 'RECONNECTING…';

  const hasTrack = Boolean(nowPlaying?.title);
  const playing = nowPlaying?.playing ?? false;
  const live = hasTrack && playing;
  const subtitle = [nowPlaying?.artist, nowPlaying?.album].filter(Boolean).join(' — ');

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
            MUSIC
          </GlitchText>
          <Text style={styles.subtitle}>
            {linked ? 'NOW PLAYING — ANY SOURCE' : 'RE-ESTABLISHING LINK…'}
          </Text>
        </View>
      </View>

      <View style={[styles.body, styles.hPad]}>
        <View style={styles.artCol}>
          <View style={styles.artFrameWrap}>
            {live ? <CornerBrackets /> : null}
            <ChamferView
              width={ART_FRAME_SIZE}
              height={ART_FRAME_SIZE}
              cut={chamfer.panel}
              fill={live ? color.magentaDim : color.panelFill}
              borderColor={live ? color.magentaBorder : color.cyanBorder}
              glowColor={live ? color.magenta : undefined}
            >
              {nowPlaying?.artworkPngBase64 ? (
                <Image
                  source={{ uri: `data:image/png;base64,${nowPlaying.artworkPngBase64}` }}
                  style={styles.artworkImage}
                  resizeMode="contain"
                />
              ) : (
                <MusicIcon size={40} color={hasTrack ? color.cyanDim : color.muted1} />
              )}
            </ChamferView>
          </View>

          <View style={styles.trackTextCol}>
            <Text
              numberOfLines={2}
              style={[styles.trackTitle, !hasTrack && styles.trackTitleMuted]}
            >
              {hasTrack ? nowPlaying?.title : linked ? 'NOTHING PLAYING' : 'AWAITING LINK…'}
            </Text>
            {subtitle ? (
              <Text numberOfLines={1} style={styles.trackSubtitle}>
                {subtitle}
              </Text>
            ) : null}
            {hasTrack ? (
              <View style={styles.statusRow}>
                <View style={[styles.statusDot, { backgroundColor: playing ? color.magenta : color.muted2 }]} />
                <Text style={[styles.statusText, { color: playing ? color.magenta : color.muted2 }]}>
                  {playing ? 'PLAYING' : 'PAUSED'}
                </Text>
              </View>
            ) : null}
          </View>
        </View>

        <View style={styles.transportRow}>
          <TransportButton size={TRANSPORT_SIZE} disabled={!linked} onPress={mediaPrevious}>
            <SkipBackIcon size={24} color={linked ? color.cyan : color.muted1} />
          </TransportButton>

          <TransportButton size={PLAY_SIZE} disabled={!linked} onPress={mediaPlayPause} primary>
            {playing ? (
              <PauseIcon size={28} color={color.textOnMagenta} />
            ) : (
              <PlayIcon size={28} color={color.textOnMagenta} />
            )}
          </TransportButton>

          <TransportButton size={TRANSPORT_SIZE} disabled={!linked} onPress={mediaNext}>
            <SkipForwardIcon size={24} color={linked ? color.cyan : color.muted1} />
          </TransportButton>
        </View>
      </View>
    </ScreenBackground>
  );
}

function TransportButton({
  size,
  disabled,
  primary = false,
  onPress,
  children,
}: {
  size: number;
  disabled: boolean;
  primary?: boolean;
  onPress: () => void;
  children: React.ReactNode;
}) {
  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      style={({ pressed }) => [{ opacity: disabled ? 0.4 : pressed ? 0.8 : 1 }, pressed && !disabled && styles.pressed]}
      hitSlop={8}
    >
      <ChamferView
        width={size}
        height={size}
        cut={chamfer.tile}
        fill={primary ? color.magenta : color.panelFill}
        borderColor={primary ? color.magentaBorder : color.cyanBorder}
        glowColor={primary ? color.magenta : undefined}
      >
        {children}
      </ChamferView>
    </Pressable>
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
  body: {
    flex: 1,
    justifyContent: 'center',
    gap: 36,
    paddingBottom: 60,
  },
  artCol: {
    alignItems: 'center',
    gap: 18,
  },
  artFrameWrap: {
    width: ART_FRAME_SIZE,
    height: ART_FRAME_SIZE,
  },
  artworkImage: {
    // The bounding box, not the image's actual rendered size — the Mac
    // already sends the artwork downscaled at its own true aspect ratio
    // (see NowPlayingArtwork.resizedPngBase64), so `contain` fits it
    // within this box without distortion, letterboxing within the frame
    // (not padding baked into the PNG itself) if it isn't square.
    width: ART_FRAME_SIZE,
    height: ART_FRAME_SIZE,
  },
  trackTextCol: {
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 30,
  },
  trackTitle: {
    fontFamily: font.bodySemiBold,
    fontSize: 17,
    letterSpacing: letterSpacing.label,
    color: color.text,
    textAlign: 'center',
  },
  trackTitleMuted: {
    fontFamily: font.mono,
    fontSize: 11,
    letterSpacing: letterSpacing.mono,
    color: color.muted3,
    textTransform: 'uppercase',
  },
  trackSubtitle: {
    fontFamily: font.mono,
    fontSize: 11,
    letterSpacing: letterSpacing.mono,
    color: color.mutedLabel,
    textAlign: 'center',
  },
  statusRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginTop: 2,
  },
  statusDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  statusText: {
    fontFamily: font.mono,
    fontSize: 10,
    letterSpacing: letterSpacing.wide,
  },
  transportRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 22,
  },
  pressed: {
    transform: [{ scale: 0.94 }],
  },
});
