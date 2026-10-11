import { createProviders, matchesReference } from "../../src/engine/providers";
import { referenceQuery } from "../../src/engine/reference";
import { sampleBatch } from "../../src/engine/sampling";
import type * as Moon from "../../src/.generated/moon-engine.js";
import { makeQueries } from "../matrix/queries";
import type { Input } from "./datasets";

export type Parameters = { batches: number; targetBatchMs: number; warmups: number };
const median = (samples: number[]) => [...samples].sort((a, b) => a - b)[Math.floor(samples.length / 2)];

export function* measureInput(input: Input, capacity: number, parameters: Parameters, engine?: typeof Moon) {
  const builds: Record<string, number[]> = {};
  let suite = createProviders(input.coordinates, capacity, engine);
  // First construction is a warmup. Retain five independently observed builds.
  for (let i = 0; i < 5; i++) {
    suite = createProviders(input.coordinates, capacity, engine);
    for (const provider of suite.providers) (builds[provider.name] ??= []).push(provider.buildMs);
  }
  for (const workload of makeQueries(input.coordinates)) {
    const expected = referenceQuery(input.coordinates, workload.query);
    const rows = suite.providers.map(provider => {
      const actual = provider.run(workload.query);
      const valid = actual !== null && matchesReference(actual, expected, workload.query, input.coordinates);
      return { name: provider.name, valid, supported: actual !== null, path: provider.path(workload.query), hits: actual?.length ?? null, iterations: 0, buildSamples: builds[provider.name], buildMedianMs: median(builds[provider.name]), samples: [] as number[], medianMs: null as number | null };
    });
    for (let i = 0; i < rows.length; i++) {
      if (!rows[i].valid) continue;
      const run = () => suite.providers[i].run(workload.query)!;
      for (let warmup = 0; warmup < parameters.warmups; warmup++) run();
      let count = 1;
      for (;;) {
        const sample = sampleBatch(run, count);
        if (sample.elapsedMs >= parameters.targetBatchMs || count === 65536) {
          rows[i].iterations = Math.max(1, Math.min(65536, Math.ceil(count * parameters.targetBatchMs / Math.max(0.001, sample.elapsedMs))));
          break;
        }
        count = Math.min(65536, count * 2);
      }
    }
    let checksum = 0;
    for (let batch = 0; batch < parameters.batches; batch++) {
      for (let step = 0; step < rows.length; step++) {
        const index = (batch + step) % rows.length;
        if (!rows[index].valid) continue;
        const sample = sampleBatch(() => suite.providers[index].run(workload.query)!, rows[index].iterations);
        rows[index].samples.push(sample.msPerQuery);
        checksum += sample.checksum;
      }
    }
    for (const row of rows) if (row.samples.length) row.medianMs = median(row.samples);
    yield {
      id: `${input.id}/${input.count}/capacity-${capacity}/seed-${input.seed}/${workload.id}`,
      dataset: input.id, kind: input.kind, count: input.count, capacity, seed: input.seed, order: input.order,
      workload: workload.id, group: workload.group, query: workload.query, expectedHits: expected.length,
      parameters, checksum, rows,
    };
  }
}
