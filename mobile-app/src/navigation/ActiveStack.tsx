import { createNativeStackNavigator } from '@react-navigation/native-stack';
import React from 'react';
import { AllNodesScreen } from '../screens/AllNodesScreen';
import { BuiltInAppScreen } from '../screens/BuiltInAppScreen';
import { WorkspaceGridScreen } from '../screens/WorkspaceGridScreen';

/**
 * A stack nested INSIDE the Active tab (see RootTabs.tsx), not a stack
 * above the tab navigator — that's what keeps HudTabBar visible while a
 * built-in app card (modules/builtInApps.ts) pushes its detail screen.
 * A stack above the tabs would cover them entirely while pushed.
 */
export type ActiveStackParamList = {
  WorkspaceGrid: undefined;
  BuiltInApp: { appId: string };
  AllApps: undefined;
};

const Stack = createNativeStackNavigator<ActiveStackParamList>();

export function ActiveStack() {
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      <Stack.Screen name="WorkspaceGrid" component={WorkspaceGridScreen} />
      <Stack.Screen name="BuiltInApp" component={BuiltInAppScreen} />
      <Stack.Screen name="AllApps" component={AllNodesScreen} />
    </Stack.Navigator>
  );
}
