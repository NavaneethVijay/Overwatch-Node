import { NavigationContainer, DarkTheme } from '@react-navigation/native';
import {
  ChakraPetch_400Regular,
  ChakraPetch_500Medium,
  ChakraPetch_600SemiBold,
  ChakraPetch_700Bold,
} from '@expo-google-fonts/chakra-petch';
import {
  JetBrainsMono_400Regular,
  JetBrainsMono_500Medium,
  JetBrainsMono_700Bold,
} from '@expo-google-fonts/jetbrains-mono';
import { Orbitron_700Bold, Orbitron_800ExtraBold, Orbitron_900Black } from '@expo-google-fonts/orbitron';
import { useFonts } from 'expo-font';
import { StatusBar } from 'expo-status-bar';
import * as SplashScreen from 'expo-splash-screen';
import React, { useEffect } from 'react';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { RootTabs } from './src/navigation/RootTabs';
import { MacLinkProvider, useMacLink } from './src/net/MacLinkContext';
import { ConnectScreen } from './src/screens/ConnectScreen';
import { PairingScreen } from './src/screens/PairingScreen';
import { color } from './src/theme/tokens';

SplashScreen.preventAutoHideAsync().catch(() => {});

const navTheme = {
  ...DarkTheme,
  colors: {
    ...DarkTheme.colors,
    background: color.bgTop,
    card: color.bgTop,
    border: color.cyanBorder,
    primary: color.magenta,
    text: color.text,
  },
};

export default function App() {
  const [fontsLoaded, fontError] = useFonts({
    Orbitron_700Bold,
    Orbitron_800ExtraBold,
    Orbitron_900Black,
    ChakraPetch_400Regular,
    ChakraPetch_500Medium,
    ChakraPetch_600SemiBold,
    ChakraPetch_700Bold,
    JetBrainsMono_400Regular,
    JetBrainsMono_500Medium,
    JetBrainsMono_700Bold,
  });

  useEffect(() => {
    if (fontsLoaded || fontError) {
      SplashScreen.hideAsync().catch(() => {});
    }
  }, [fontsLoaded, fontError]);

  if (!fontsLoaded && !fontError) {
    return null;
  }

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <MacLinkProvider>
          <RootSwitch />
        </MacLinkProvider>
        <StatusBar style="light" />
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}

/**
 * Gates the tab UI behind a successful connection (ConnectScreen), then a
 * second gate behind pairing (PairingScreen) — the Mac won't send anything
 * else until this device's id is trusted (see DevicePairing.swift).
 * `hasConnectedOnce` flips true as soon as the socket opens, before pairing
 * resolves, and never flips back for the session — a later drop reconnects
 * silently in the background instead of bouncing the user back to
 * ConnectScreen (see MacLinkContext). `pairingRequired` isn't sticky the
 * same way: it tracks live server state, so it clears the moment a code is
 * accepted and can reappear if a fresh connection needs pairing again.
 */
function RootSwitch() {
  const { hasConnectedOnce, pairingRequired } = useMacLink();

  if (!hasConnectedOnce) {
    return <ConnectScreen />;
  }

  if (pairingRequired) {
    return <PairingScreen />;
  }

  return (
    <NavigationContainer theme={navTheme}>
      <RootTabs />
    </NavigationContainer>
  );
}
