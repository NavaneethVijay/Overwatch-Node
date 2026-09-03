import React, { useEffect, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { ChamferView } from './ChamferView';
import { CornerBrackets } from './CornerBrackets';
import { ProjectIcon } from './icons';
import { Project } from '../net/protocol';
import { chamfer, color, font, letterSpacing } from '../theme/tokens';

/**
 * Shared Projects UI — a module's (or built-in module's) named custom
 * button groups. Originally lived only in ModuleScreen.tsx; pulled out here
 * so BuiltInAppScreen can offer the exact same "Projects row at the top,
 * tap one to expand its buttons inline on this same screen" behavior for a
 * built-in module (e.g. Window Management) without duplicating it.
 */

/** Tracks which Project's buttons are expanded inline. Falls back to the
 * Mac-persisted `currentProjectId` until the caller taps one locally, so
 * reopening a screen shows whichever Project was last active instead of
 * nothing. Resets whenever `resetKey` changes (a module's bundleId, or
 * whatever else means "this is now a different module's data"), same
 * reasoning ModuleScreen's `localActiveByProvider` already used. */
export function useSelectedProject(
  resetKey: string | undefined,
  projects: Project[],
  currentProjectId: string | null,
) {
  const [selectedProjectId, setSelectedProjectId] = useState<string | null>(null);

  useEffect(() => {
    setSelectedProjectId(null);
  }, [resetKey]);

  const effectiveProjectId = selectedProjectId ?? currentProjectId;
  const selectedProject = projects.find((p) => p.id === effectiveProjectId);

  return { effectiveProjectId, selectedProject, setSelectedProjectId };
}

export function ProjectsRow({
  projects,
  effectiveProjectId,
  onSelect,
}: {
  projects: Project[];
  effectiveProjectId: string | null;
  onSelect: (project: Project) => void;
}) {
  if (projects.length === 0) return null;

  return (
    <View style={styles.section}>
      <Text style={styles.sectionLabel}>PROJECTS</Text>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.projectRow}>
        {projects.map((project) => (
          <ProjectCard
            key={project.id}
            project={project}
            active={project.id === effectiveProjectId}
            onPress={() => onSelect(project)}
          />
        ))}
      </ScrollView>
    </View>
  );
}

const PROJECT_CARD_WIDTH = 150;
const PROJECT_CARD_HEIGHT = 64;

/** A tappable Project chip — deliberately mirrors ModuleControls.tsx's
 * TabCard styling (ChamferView + CornerBrackets + magenta "active"
 * treatment) rather than importing it directly, since a Project isn't a
 * DynamicListItem (no url/title shape to adapt). */
function ProjectCard({ project, active, onPress }: { project: Project; active: boolean; onPress: () => void }) {
  const labelColor = active ? color.white : color.mutedLabel;

  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [{ width: PROJECT_CARD_WIDTH, height: PROJECT_CARD_HEIGHT }, pressed && styles.pressed]}
    >
      <View style={{ width: PROJECT_CARD_WIDTH, height: PROJECT_CARD_HEIGHT }}>
        {active ? <CornerBrackets /> : null}
        <ChamferView
          width={PROJECT_CARD_WIDTH}
          height={PROJECT_CARD_HEIGHT}
          cut={chamfer.card}
          fill={active ? color.magentaDim : color.panelFill}
          borderColor={active ? color.magentaBorder : color.cyanBorder}
          glowColor={active ? color.magenta : undefined}
        >
          <View style={styles.projectCardRow}>
            <ProjectIcon size={18} color={active ? color.magenta : color.cyanDim} />
            <Text numberOfLines={1} style={[styles.projectCardLabel, { color: labelColor }]}>
              {project.name}
            </Text>
          </View>
        </ChamferView>
      </View>
    </Pressable>
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
  projectRow: {
    flexDirection: 'row',
    gap: 12,
  },
  pressed: {
    transform: [{ scale: 0.97 }],
  },
  projectCardRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 14,
    height: '100%',
  },
  projectCardLabel: {
    fontFamily: font.bodySemiBold,
    fontSize: 13,
    flexShrink: 1,
  },
});
