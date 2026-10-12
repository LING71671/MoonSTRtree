import { expect, test } from "bun:test";
import { coalescedTask } from "../src/engine/coalesced-task";
import { prepareCanvas } from "../src/rendering/canvas";

test("continuous pointer input sends the newest query once per window without starvation", () => {
  let callback: (() => void) | null = null, scheduled = 0;
  const timers = { schedule: (run: () => void) => { callback = run; scheduled++; return scheduled as unknown as ReturnType<typeof setTimeout>; }, cancel: () => { callback = null; } };
  const sent: number[] = [];
  const task = coalescedTask((value: number) => sent.push(value), 60, timers);
  for (let value = 0; value < 40; value++) task.push(value);
  expect(scheduled).toBe(1);
  const first = callback!; callback = null; first();
  expect(sent).toEqual([39]);
  task.push(40); task.push(41);
  expect(scheduled).toBe(2);
  const second = callback!; callback = null; second();
  expect(sent).toEqual([39, 41]);
});

test("replacing an experiment cancels its queued query and supports a new window", () => {
  let callback: (() => void) | null = null;
  const timers = { schedule: (run: () => void) => { callback = run; return 1 as unknown as ReturnType<typeof setTimeout>; }, cancel: () => { callback = null; } };
  const sent: string[] = [];
  const task = coalescedTask((value: string) => sent.push(value), 60, timers);
  task.push("old dataset"); task.cancel();
  expect(callback).toBeNull();
  expect(sent).toEqual([]);
  task.push("new dataset");
  const run = callback!; run();
  expect(sent).toEqual(["new dataset"]);
});

test("unchanged canvas dimensions preserve the backing store; hidden boxes are skipped", () => {
  let width = 200, height = 100, writes = 0, clears = 0;
  let box = { width: 100, height: 50 };
  const context = { setTransform: () => {}, clearRect: () => { clears++; } };
  const element = { getBoundingClientRect: () => box, getContext: () => context,
    get width() { return width; }, set width(value: number) { writes++; width = value; },
    get height() { return height; }, set height(value: number) { writes++; height = value; } } as unknown as HTMLCanvasElement;
  prepareCanvas(element, 2); prepareCanvas(element, 2);
  expect(writes).toBe(0); expect(clears).toBe(2);
  box = { width: 0, height: 0 };
  expect(prepareCanvas(element, 2)).toBeNull();
  expect(writes).toBe(0); expect(clears).toBe(2);
  box = { width: 120, height: 60 };
  const result = prepareCanvas(element, 2);
  expect(writes).toBe(2);
  expect(result?.viewport.pixelWidth).toBe(240);
  expect(result?.viewport.pixelHeight).toBe(120);
});
