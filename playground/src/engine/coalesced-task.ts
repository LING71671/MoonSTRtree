type Timer = ReturnType<typeof setTimeout>;
type Timers = { schedule: (callback: () => void, delay: number) => Timer; cancel: (timer: Timer) => void };
const defaults: Timers = { schedule: (callback, delay) => setTimeout(callback, delay), cancel: timer => clearTimeout(timer) };

// A trailing throttle: continuous input sends the newest value once per window.
// Unlike debounce, an ongoing drag does not postpone queries indefinitely.
export function coalescedTask<T>(run: (value: T) => void, delay: number, timers: Timers = defaults) {
  let timer: Timer | null = null;
  let pending: { value: T } | null = null;
  return {
    push(value: T) {
      pending = { value };
      if (timer !== null) return;
      timer = timers.schedule(() => {
        timer = null;
        const next = pending;
        pending = null;
        if (next) run(next.value);
      }, delay);
    },
    cancel() {
      if (timer !== null) timers.cancel(timer);
      timer = null;
      pending = null;
    },
  };
}
