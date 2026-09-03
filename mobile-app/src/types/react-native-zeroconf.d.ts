/**
 * react-native-zeroconf ships no TypeScript types. This declares only the
 * surface this app actually uses — see net/discovery.ts.
 */
declare module 'react-native-zeroconf' {
  export interface Service {
    name: string;
    fullName?: string;
    host: string;
    port: number;
    addresses?: string[];
    txt?: Record<string, string>;
  }

  export type ZeroconfEvent =
    | 'start'
    | 'stop'
    | 'error'
    | 'found'
    | 'remove'
    | 'resolved'
    | 'update'
    | 'published'
    | 'unpublished';

  export default class Zeroconf {
    constructor();
    on(event: ZeroconfEvent, listener: (...args: any[]) => void): this;
    removeAllListeners(event?: ZeroconfEvent): this;
    getServices(): Record<string, Service>;
    scan(type?: string, protocol?: 'tcp' | 'udp', domain?: string): void;
    stop(): void;
    removeDeviceListeners(): void;
  }
}
