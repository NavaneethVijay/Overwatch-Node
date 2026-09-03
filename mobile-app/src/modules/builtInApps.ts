import { IconProps, LayersIcon, WindowTabIcon } from '../components/icons';

/**
 * Registry of "built-in apps" — controls that are part of OverwatchNode itself
 * rather than any per-frontmost-app module (see ModuleScreen.tsx /
 * DefaultModules.swift for that other kind). Surfaced as a row of cards on
 * the Active tab (WorkspaceGridScreen); tapping one pushes a screen inside
 * ActiveStack. Two kinds, since not every built-in app is just a button grid:
 * - `"sections"` — generic, rendered by the shared BuiltInAppScreen, which
 *   fetches this app's actual sections/Projects from the Mac on demand (see
 *   `requestBuiltinModule`/`builtinModules` in net/connection.ts) rather
 *   than reading a static client-owned constant — real Mac-JSON, editable
 *   via the Settings > Modules builder like any other module (see
 *   macos-app/Sources/OverwatchNode/DefaultModules.swift's `windowManagement` for
 *   Window Management's seeded content, and ModuleStore.protectedBundleIds
 *   for why it can't be deleted there).
 * - `"screen"` — a fully custom screen (e.g. All Apps' dynamic installed-
 *   apps list, driven by live Mac data) — `route` names an ActiveStack
 *   screen directly instead.
 */
export type BuiltInApp =
  | {
      id: string;
      displayName: string;
      subtitle: string;
      Icon: React.ComponentType<IconProps>;
      kind: 'sections';
      /** The pseudo bundleId this built-in module is seeded under on the
       * Mac (see DefaultModules.swift) — never a real app's bundle id. */
      bundleId: string;
    }
  | {
      id: string;
      displayName: string;
      subtitle: string;
      Icon: React.ComponentType<IconProps>;
      kind: 'screen';
      route: 'AllApps';
    };

export const BUILT_IN_APPS: BuiltInApp[] = [
  {
    id: 'all-apps',
    displayName: 'All Apps',
    subtitle: 'EVERY INSTALLED APP',
    Icon: LayersIcon,
    kind: 'screen',
    route: 'AllApps',
  },
  {
    id: 'window-management',
    displayName: 'Window Management',
    subtitle: 'TILING & SPACES — WORKS ON ANY FRONTMOST APP',
    Icon: WindowTabIcon,
    kind: 'sections',
    bundleId: 'com.overwatchnode.windowManagement',
  },
];

export function findBuiltInApp(id: string): BuiltInApp | undefined {
  return BUILT_IN_APPS.find((app) => app.id === id);
}
