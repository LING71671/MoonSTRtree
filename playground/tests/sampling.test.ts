import { expect, test } from "bun:test";
import { calibrateIterations, MAX_ITERATIONS, sampleBatch } from "../src/engine/sampling";

test("calibration grows short batches and records per-query time", () => {
  let clock = 0;
  const run = () => { clock += 2; return [1, 2, 3]; };
  const iterations = calibrateIterations(run, () => clock);
  expect(iterations).toBe(6);
  const sample = sampleBatch(run, iterations, () => clock);
  expect(sample.elapsedMs).toBe(12);
  expect(sample.msPerQuery).toBe(2);
  expect(sample.hits).toBe(3);
  expect(sample.checksum).toBe(18);
});

test("calibration bounds a coarse clock and slow queries", () => {
  expect(calibrateIterations(() => [], () => 0)).toBe(MAX_ITERATIONS);
  let clock = 0;
  expect(calibrateIterations(() => { clock += 100; return []; }, () => clock)).toBe(1);
});

test("Node profiles can select shorter batches without changing the browser default", () => {
  let clock = 0;
  const run = () => { clock += 1; return []; };
  expect(calibrateIterations(run, () => clock, 3)).toBe(3);
  expect(() => calibrateIterations(run, () => clock, 0)).toThrow();
});
