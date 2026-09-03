import { useCallback, useEffect, useRef } from 'react';

/**
 * Leading+trailing throttle: fires immediately if `delayMs` has elapsed
 * since the last call, otherwise schedules exactly one trailing call with
 * the latest argument so the final value is never dropped. Used for
 * gesture-driven network sends (brightness/volume sliders) where firing on
 * every touch-move event would flood the socket — and, in this app's case,
 * the Mac's AppleScript-backed volume call, which is slow enough per-call
 * that flooding it causes real, visible lag.
 */
export function useThrottledCallback<T>(callback: (value: T) => void, delayMs: number): (value: T) => void {
  const callbackRef = useRef(callback);
  callbackRef.current = callback;

  const lastCallAtRef = useRef(0);
  const pendingRef = useRef<T | null>(null);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(
    () => () => {
      if (timerRef.current) clearTimeout(timerRef.current);
    },
    [],
  );

  return useCallback(
    (value: T) => {
      pendingRef.current = value;
      const elapsed = Date.now() - lastCallAtRef.current;

      const flush = () => {
        timerRef.current = null;
        if (pendingRef.current === null) return;
        lastCallAtRef.current = Date.now();
        callbackRef.current(pendingRef.current);
        pendingRef.current = null;
      };

      if (elapsed >= delayMs) {
        if (timerRef.current) {
          clearTimeout(timerRef.current);
        }
        flush();
      } else if (!timerRef.current) {
        timerRef.current = setTimeout(flush, delayMs - elapsed);
      }
    },
    [delayMs],
  );
}
