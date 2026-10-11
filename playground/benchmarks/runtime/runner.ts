import { createProvider, matchesReference, PROVIDER_NAMES, type Adapter } from "../../src/engine/providers";
import { referenceQuery } from "../../src/engine/reference";
import { MAX_ITERATIONS, sampleBatch } from "../../src/engine/sampling";
import type { Provider, Query } from "../../src/domain/types";
import type * as Moon from "../../src/.generated/moon-engine.js";
import { makeQueries } from "../matrix/queries";
import type { Input } from "./datasets";

export type Parameters = { batches: number; targetBatchMs: number; warmups: number };
export const BUILD_SAMPLES = 9;
export const median = (samples: number[]) => [...samples].sort((a, b) => a - b)[Math.floor(samples.length / 2)];
export type Failure = { phase: "build" | "validation" | "warmup" | "calibration" | "measurement" | "revalidation"; message: string };
export type BenchmarkRow = {
  name: Provider; valid: boolean; supported: boolean;
  status: "ok" | "unsupported" | "mismatch" | "error";
  path: string; hits: number | null; iterations: number;
  buildSamples: number[]; buildMedianMs: number | null;
  samples: number[]; medianMs: number | null; error: Failure | null;
};
const message = (error: unknown) => error instanceof Error ? error.message : String(error);

export function* measureInput(input: Input, capacity: number, parameters: Parameters, engine?: typeof Moon,
  dependencies: { factory?: typeof createProvider; now?: () => number } = {}) {
  if (!Number.isInteger(parameters.batches) || parameters.batches < 1 || !Number.isInteger(parameters.warmups) || parameters.warmups < 0 || !Number.isFinite(parameters.targetBatchMs) || parameters.targetBatchMs <= 0)
    throw new Error("Invalid benchmark sampling parameters");
  const factory = dependencies.factory ?? createProvider;
  const now = dependencies.now ?? (() => performance.now());
  const builds = new Map<Provider, number[]>(), adapters = new Map<Provider, Adapter>(), failures = new Map<Provider, Failure>();
  // One warm construction, then nine samples. Rotate the indexed providers;
  // the scan has no index to construct and contributes no build time.
  const indexed = PROVIDER_NAMES.filter(name => name !== "Linear scan");
  for (let round = -1; round < BUILD_SAMPLES; round++) {
    const order = [...indexed.slice(Math.max(0, round) % indexed.length), ...indexed.slice(0, Math.max(0, round) % indexed.length), "Linear scan" as const];
    for (const name of order) {
      if (failures.has(name)) continue;
      try {
        const adapter = factory(name, input.coordinates, capacity, engine);
        if (!Number.isFinite(adapter.buildMs) || adapter.buildMs < 0) throw new Error("Invalid construction timing");
        adapters.set(name, adapter);
        if (round >= 0) { const samples = builds.get(name) ?? []; samples.push(adapter.buildMs); builds.set(name, samples); }
      } catch (error) { failures.set(name, { phase: "build", message: message(error) }); adapters.delete(name); }
    }
  }
  for (const workload of makeQueries(input.coordinates)) {
    const expected = referenceQuery(input.coordinates, workload.query);
    const rows: BenchmarkRow[] = PROVIDER_NAMES.map(name => {
      const error = failures.get(name) ?? null;
      const buildSamples = builds.get(name) ?? [];
      return { name, valid: false, supported: true, status: error ? "error" : "mismatch", path: "", hits: null,
        iterations: 0, buildSamples, buildMedianMs: error ? null : median(buildSamples), samples: [], medianMs: null, error };
    });
    const fail = (row: BenchmarkRow, phase: Failure["phase"], error: unknown) => {
      row.valid = false; row.status = "error"; row.error = { phase, message: message(error) }; row.medianMs = null;
    };
    const validate = (row: BenchmarkRow, query: Query) => {
      const adapter = adapters.get(row.name)!;
      const actual = adapter.run(query);
      row.path = adapter.path(query);
      row.supported = actual !== null;
      row.hits = actual?.length ?? null;
      row.valid = actual !== null && matchesReference(actual, expected, query, input.coordinates);
      row.status = !row.supported ? "unsupported" : row.valid ? "ok" : "mismatch";
      if (!row.valid) row.medianMs = null;
    };
    for (const row of rows) {
      if (row.error) continue;
      try { validate(row, workload.query); } catch (error) { fail(row, "validation", error); }
      if (!row.valid) continue;
      const run = () => {
        const result = adapters.get(row.name)!.run(workload.query);
        if (result === null) throw new Error("Provider became unsupported after validation");
        return result;
      };
      try { for (let warmup = 0; warmup < parameters.warmups; warmup++) run(); }
      catch (error) { fail(row, "warmup", error); continue; }
      try {
        let count = 1;
        for (;;) {
          const sample = sampleBatch(run, count, now);
          if (sample.elapsedMs >= parameters.targetBatchMs || count === MAX_ITERATIONS) {
            row.iterations = Math.max(1, Math.min(MAX_ITERATIONS, Math.ceil(count * parameters.targetBatchMs / Math.max(0.001, sample.elapsedMs))));
            break;
          }
          count = Math.min(MAX_ITERATIONS, count * 2);
        }
      } catch (error) { fail(row, "calibration", error); }
    }
    let checksum = 0;
    for (let batch = 0; batch < parameters.batches; batch++) {
      for (let step = 0; step < rows.length; step++) {
        const row = rows[(batch + step) % rows.length];
        if (!row.valid) continue;
        try {
          const sample = sampleBatch(() => {
            const result = adapters.get(row.name)!.run(workload.query);
            if (result === null) throw new Error("Provider became unsupported during measurement");
            return result;
          }, row.iterations, now);
          row.samples.push(sample.msPerQuery);
          checksum += sample.checksum;
        } catch (error) { fail(row, "measurement", error); }
      }
    }
    // Detect stateful result changes after timing, outside the measured region.
    for (const row of rows) if (row.valid) {
      try { validate(row, workload.query); } catch (error) { fail(row, "revalidation", error); }
      if (row.valid && row.samples.length === parameters.batches) row.medianMs = median(row.samples);
    }
    yield {
      id: `${input.id}/${input.count}/capacity-${capacity}/seed-${input.seed}/${workload.id}`,
      dataset: input.id, kind: input.kind, count: input.count, capacity, seed: input.seed, order: input.order,
      workload: workload.id, group: workload.group, query: workload.query, expectedHits: expected.length,
      parameters, checksum, rows,
    };
  }
}

export type BenchmarkCase = ReturnType<typeof measureInput> extends Generator<infer T> ? T : never;
