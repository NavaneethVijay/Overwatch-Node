import { RouteProp, useFocusEffect, useNavigation, useRoute } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import React, { useCallback } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, useWindowDimensions, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { ModuleSectionView } from '../components/ModuleControls';
import { ProjectsRow, useSelectedProject } from '../components/ModuleProjects';
import { TabPrevIcon } from '../components/icons';
import { ScreenBackground } from '../components/ScreenBackground';
import { findBuiltInApp } from '../modules/builtInApps';
import { ActiveStackParamList } from '../navigation/ActiveStack';
import { useMacLink } from '../net/MacLinkContext';
import { Project } from '../net/protocol';
import { color, font, letterSpacing } from '../theme/tokens';

type Nav = NativeStackNavigationProp<ActiveStackParamList, 'BuiltInApp'>;
type Rt = RouteProp<ActiveStackParamList, 'BuiltInApp'>;

/**
 * Generic screen for any entry in modules/builtInApps.ts — pushed from the
 * Active tab's Built-in Apps row (see WorkspaceGridScreen.tsx), not part
 * of the bottom-tab flow. Zero per-app knowledge, same as ModuleScreen: it
 * just looks up `appId` and renders that app's sections with the same
 * shared button-grid renderer Contextual Controls uses.
 *
 * Unlike a static built-in, a "sections" entry's actual data (sections,
 * Projects) now lives in real Mac-JSON (see DefaultModules.swift), fetched
 * on demand via `requestBuiltinModule` rather than pushed like a
 * per-frontmost-app module — refetched on every focus so an edit made in
 * the Mac's Settings while this screen was last open shows up on return.
 */
const H_PAD = 22;
const BUTTON_COLUMNS = 3;
const BUTTON_GAP = 12;

export function BuiltInAppScreen() {
  const insets = useSafeAreaInsets();
  const navigation = useNavigation<Nav>();
  const { params } = useRoute<Rt>();
  const { width: windowWidth } = useWindowDimensions();
  const contentWidth = windowWidth - H_PAD * 2;
  const buttonWidth = (contentWidth - BUTTON_GAP * (BUTTON_COLUMNS - 1)) / BUTTON_COLUMNS;

  const { invokeControlAction, selectProject, builtinModules, requestBuiltinModule } = useMacLink();
  const app = findBuiltInApp(params.appId);
  const bundleId = app?.kind === 'sections' ? app.bundleId : undefined;
  const moduleData = bundleId ? builtinModules[bundleId] : undefined;

  useFocusEffect(
    useCallback(() => {
      if (bundleId) requestBuiltinModule(bundleId);
    }, [bundleId, requestBuiltinModule]),
  );

  const { effectiveProjectId, selectedProject, setSelectedProjectId } = useSelectedProject(
    bundleId,
    moduleData?.projects ?? [],
    moduleData?.currentProjectId ?? null,
  );

  const onSelectProject = useCallback(
    (project: Project) => {
      if (!bundleId) return;
      setSelectedProjectId(project.id);
      selectProject(bundleId, project.id);
    },
    [bundleId, selectProject, setSelectedProjectId],
  );

  // This screen only ever renders a "sections" kind built-in app — a
  // "screen" kind (e.g. All Apps) is navigated to directly by route name
  // instead (see WorkspaceGridScreen's card onPress), never through here.
  if (!app || app.kind !== 'sections') return null;

  return (
    <ScreenBackground>
      <View style={{ paddingTop: insets.top }}>
        <Pressable onPress={navigation.goBack} style={[styles.backRow, styles.hPad]} hitSlop={10}>
          <TabPrevIcon size={18} color={color.cyan} strokeWidth={2} />
          <Text style={styles.backText}>BACK</Text>
        </Pressable>

        <View style={[styles.titleBlock, styles.hPad]}>
          <Text style={styles.title}>{app.displayName.toUpperCase()}</Text>
          <Text style={styles.subtitle}>{app.subtitle}</Text>
        </View>
      </View>

      {moduleData ? (
        <ScrollView
          style={styles.hPad}
          contentContainerStyle={styles.scroll}
          showsVerticalScrollIndicator={false}
        >
          <ProjectsRow
            projects={moduleData.projects}
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

          {moduleData.sections.map((section) => (
            <ModuleSectionView
              key={section.title}
              section={section}
              dynamicData={moduleData.dynamicData}
              buttonWidth={buttonWidth}
              contentWidth={contentWidth}
              onInvoke={invokeControlAction}
              localActiveByProvider={{}}
              onSelectListItem={() => {}}
            />
          ))}
        </ScrollView>
      ) : (
        <View style={styles.emptyState}>
          <Text style={styles.emptyText}>LOADING MODULE DATA…</Text>
        </View>
      )}
    </ScreenBackground>
  );
}

const styles = StyleSheet.create({
  hPad: {
    paddingHorizontal: H_PAD,
  },
  backRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingTop: 14,
  },
  backText: {
    fontFamily: font.mono,
    fontSize: 11,
    letterSpacing: letterSpacing.wide,
    color: color.cyan,
  },
  titleBlock: {
    paddingTop: 14,
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
