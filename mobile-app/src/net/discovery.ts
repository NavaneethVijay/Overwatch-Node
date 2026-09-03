import { useEffect, useRef, useState } from 'react';
import Zeroconf, { Service } from 'react-native-zeroconf';
import { macService } from '../theme/tokens';

export type DiscoveryStatus = 'searching' | 'found' | 'error';

export interface MacDiscoveryState {
  status: DiscoveryStatus;
  host: string | null;
  port: number | null;
  deviceName: string | null;
  error: string | null;
}

/**
 * Browses the LAN for the Mac app's advertised _overwatchnode._tcp Bonjour/NSD
 * service and resolves to its host/port. Re-scans automatically if the
 * service disappears (e.g. the Mac sleeps or leaves the network).
 */
export function useMacDiscovery(): MacDiscoveryState {
  const [state, setState] = useState<MacDiscoveryState>({
    status: 'searching',
    host: null,
    port: null,
    deviceName: null,
    error: null,
  });

  useEffect(() => {
    const zeroconf = new Zeroconf();

    const onResolved = (service: Service) => {
      if (!service.host || !service.port) return;
      setState({
        status: 'found',
        host: service.host,
        port: service.port,
        deviceName: service.name ?? null,
        error: null,
      });
    };

    const onRemove = () => {
      setState((prev) => ({ ...prev, status: 'searching', host: null, port: null }));
    };

    const onError = (err: unknown) => {
      setState((prev) => ({
        ...prev,
        status: 'error',
        error: err instanceof Error ? err.message : String(err),
      }));
    };

    zeroconf.on('resolved', onResolved);
    zeroconf.on('remove', onRemove);
    zeroconf.on('error', onError);

    zeroconf.scan(macService.type, macService.protocol, macService.domain);

    return () => {
      zeroconf.stop();
      zeroconf.removeAllListeners();
      zeroconf.removeDeviceListeners();
    };
  }, []);

  return state;
}
