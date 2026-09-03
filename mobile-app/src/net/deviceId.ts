import AsyncStorage from '@react-native-async-storage/async-storage';

const STORAGE_KEY = 'overwatchnode.deviceId';

/**
 * A stable identity for this phone, generated once and persisted forever
 * — this is what the Mac's pairing trust store (DevicePairing.swift) keys
 * on. Not a secret (it's sent in plaintext on every client_hello); the
 * pairing code is what actually gates trust on first use. Not a real
 * cryptographic UUID generator — Math.random() is adequate here since
 * this only needs to be unique-enough to identify one phone, not
 * unguessable.
 */
export async function getOrCreateDeviceId(): Promise<string> {
  const existing = await AsyncStorage.getItem(STORAGE_KEY);
  if (existing) return existing;

  const id = generateId();
  await AsyncStorage.setItem(STORAGE_KEY, id);
  return id;
}

function generateId(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}
