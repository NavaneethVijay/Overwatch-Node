import React, { useCallback, useEffect, useState } from 'react';
import { ScrollView, StyleSheet, Text, useWindowDimensions, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { AppGenericIcon } from '../components/icons';
import { ModuleSectionView } from '../components/ModuleControls';
import { ProjectsRow, useSelectedProject } from '../components/ModuleProjects';
import { GlitchText } from '../components/GlitchText';
import { PulseDot } from '../components/PulseDot';
import { ScreenBackground } from '../components/ScreenBackground';
import { SignalBars } from '../components/SignalBars';
import { useMacLink } from '../net/MacLinkContext';
import { Project } from '../net/protocol';
import { color, font, letterSpacing } from '../theme/tokens';

/**
 * Generic renderer for whatever app is currently frontmost on the Mac — the
 * schema (sections/controls/icons) is entirely server-driven (see
 * macos-app/Sources/OverwatchNode/DefaultModules.swift and ModuleStore.swift).
 * This screen has zero per-app knowledge; adding a new app's controls never
 * touches this file.
 */
const H_PAD = 22;
const BUTTON_COLUMNS = 3;
const BUTTON_GAP = 12;

export function ModuleScreen() {
  const insets = useSafeAreaInsets();
  const { width: windowWidth } = useWindowDimensions();
  const contentWidth = windowWidth - H_PAD * 2;
  const buttonWidth = (contentWidth - BUTTON_GAP * (BUTTON_COLUMNS - 1)) / BUTTON_COLUMNS;

  const { discoveryStatus, deviceName, connectionStatus, activeModule, invokeControlAction, selectProject } =
    useMacLink();

  // The Mac's own notion of "active" in a dynamic list only refreshes every
  // 10s regardless of provider. Tracking the last-tapped id per
  // provider here gives an immediate, locally-correct highlight instead of
  // waiting on (or never getting) server confirmation. Cleared whenever the
  // frontmost app changes, since a stale selection from a different app's
  // module would be meaningless.
  const [localActiveByProvider, setLocalActiveByProvider] = useState<Record<string, string>>({});

  useEffect(() => {
    setLocalActiveByProvider({});
  }, [activeModule?.bundleId]);

  const onSelectListItem = useCallback((provider: string, id: string) => {
    setLocalActiveByProvider((prev) => ({ ...prev, [provider]: id }));
  }, []);

  const { effectiveProjectId, selectedProject, setSelectedProjectId } = useSelectedProject(
    activeModule?.bundleId,
    activeModule?.projects ?? [],
    activeModule?.currentProjectId ?? null,
  );

  const onSelectProject = useCallback(
    (project: Project) => {
      if (!activeModule) return;
      setSelectedProjectId(project.id);
      selectProject(activeModule.bundleId, project.id);
    },
    [activeModule, selectProject, setSelectedProjectId],
  );

  const linked = connectionStatus === 'open';
  const deviceLabel = linked
    ? (deviceName ?? 'MACBOOK').toUpperCase()
    : discoveryStatus === 'error'
      ? 'LINK ERROR'
      : 'RECONNECTING…';

  const title = activeModule ? `${activeModule.displayName.toUpperCase()} MODULE` : 'CONTEXTUAL CONTROLS';
  const subtitle = !linked
    ? 'RE-ESTABLISHING LINK…'
    : !activeModule
      ? 'AWAITING MODULE DATA…'
      : activeModule.hasModule
        ? 'TOUCH BAR CONTROLS'
        : 'NO CONTROLS FOR THIS APP';

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
            {title}
          </GlitchText>
          <Text style={styles.subtitle}>{subtitle}</Text>
        </View>
      </View>

      {activeModule?.hasModule ? (
        <ScrollView
          style={styles.hPad}
          contentContainerStyle={styles.scroll}
          showsVerticalScrollIndicator={false}
        >
          <ProjectsRow
            projects={activeModule.projects}
            effectiveProjectId={effectiveProjectId}
            onSelect={onSelectProject}
          />

          {selectedProject
            ? selectedProject.sections.map((section) => (
                <ModuleSectionView
                  key={`${selectedProject.id}:${section.title}`}
                  section={section}
                  dynamicData={{}}
                  buttonWidth={buttonWidth}
                  contentWidth={contentWidth}
                  onInvoke={invokeControlAction}
                  localActiveByProvider={{}}
                  onSelectListItem={() => {}}
                />
              ))
            : null}

          {activeModule.sections.map((section) => (
            <ModuleSectionView
              key={section.title}
              section={section}
              dynamicData={activeModule.dynamicData}
              buttonWidth={buttonWidth}
              contentWidth={contentWidth}
              onInvoke={invokeControlAction}
              localActiveByProvider={localActiveByProvider}
              onSelectListItem={onSelectListItem}
            />
          ))}
        </ScrollView>
      ) : (
        <View style={styles.emptyState}>
          <AppGenericIcon size={40} color={color.muted1} />
          <Text style={styles.emptyText}>
            {activeModule ? 'THIS APP HAS NO MODULE YET' : 'WAITING FOR THE MAC…'}
          </Text>
        </View>
      )}
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
  emptyState: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 14,
    paddingHorizontal: 40,
  },
  emptyText: {
    fontFamily: font.mono,
    fontSize: 11,
    color: color.muted3,
    letterSpacing: letterSpacing.wide,
    textAlign: 'center',
  },
});
