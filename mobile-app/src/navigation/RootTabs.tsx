import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { NavigatorScreenParams } from '@react-navigation/native';
import React from 'react';
import { ActiveStack, ActiveStackParamList } from './ActiveStack';
import { HudTabBar } from './HudTabBar';
import { ModuleScreen } from '../screens/ModuleScreen';
import { MusicScreen } from '../screens/MusicScreen';
import { UtilityScreen } from '../screens/UtilityScreen';

export type RootTabParamList = {
  // Named "Active" (not "WorkspaceGrid") specifically to avoid colliding
  // with ActiveStack's own "WorkspaceGrid" screen one level down — React
  // Navigation warns ("Found screens with the same name nested inside one
  // another") if a tab and a screen inside its nested stack share a name.
  Active: NavigatorScreenParams<ActiveStackParamList>;
  Music: undefined;
  Module: undefined;
  Utility: undefined;
};

const Tab = createBottomTabNavigator<RootTabParamList>();

export function RootTabs() {
  return (
    <Tab.Navigator
      tabBar={(props) => <HudTabBar {...props} />}
      screenOptions={{ headerShown: false }}
    >
      <Tab.Screen name="Active" component={ActiveStack} />
      <Tab.Screen name="Music" component={MusicScreen} />
      <Tab.Screen name="Module" component={ModuleScreen} />
      <Tab.Screen name="Utility" component={UtilityScreen} />
    </Tab.Navigator>
  );
}
