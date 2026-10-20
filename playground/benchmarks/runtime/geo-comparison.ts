import { appendFileSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { cpus, platform, release } from "node:os";
import { createHash } from "node:crypto";
import { spawnSync } from "node:child_process";
import type { Query } from "../../src/domain/types";
import { referenceQuery } from "../../src/engine/reference";
import { calibrateIterations, sampleBatch } from "../../src/engine/sampling";
import { median } from "./runner";
import { publicInput } from "./datasets";
import catalog from "../data/sources.json";
import { coordinateHash, exactGeoAnswer, GEO_PROFILES, GEO_PROVIDERS, GEO_VERSION, geoDescriptors, geoInput, geoQueries, type GeoProfile } from "./geo-model";
import type { GeoCase, GeoHeader, GeoRow } from "./geo-report";

type Engine = {
  build_moon: (coordinates: number[]) => unknown;
  build_geo: (coordinates: number[]) => unknown;
  [key: string]: (...args: any[]) => any;
};
const argument = (name: string, fallback = "") => process.argv.slice(2).find(value => value.startsWith(`--${name}=`))?.slice(name.length + 3) ?? fallback;
const profile = argument("profile", "diagnostic") as GeoProfile;
if (!(profile in GEO_PROFILES)) throw new Error(`Unknown geo profile: ${profile}`);
const parameters = GEO_PROFILES[profile];
const cache = resolve(argument("cache", ".bench/datasets"));
const output = resolve(argument("output", ".bench/reports/geo-comparison.ndjson"));
const artifact = resolve(".bench/geo-engine/engine.mjs");
const metadata = JSON.parse(readFileSync(resolve(".bench/geo-engine/metadata.json"), "utf8"));
const sha = (bytes: Uint8Array | string) => createHash("sha256").update(bytes).digest("hex");
if (metadata.geo.version !== GEO_VERSION || metadata.capacity !== 16 || metadata.artifactSha256 !== sha(readFileSync(artifact))) throw new Error("Compiled geo engine metadata does not match its artifact");
const engine = await import(pathToFileURL(artifact).href) as Engine;
const git = spawnSync("git", ["rev-parse", "HEAD"], { encoding: "utf8" });
const dirty = spawnSync("git", ["status", "--porcelain"], { encoding: "utf8" });
if (git.status !== 0 || dirty.status !== 0) throw new Error("Cannot record source state");
const publicCounts = Object.fromEntries(catalog.sources.map(source => [source.id, publicInput(source.id, 0, cache).count]));
const descriptors = geoDescriptors(profile, publicCounts);
const expectedCases = descriptors.length * geoQueries(new Float64Array([0, 0, 1, 1])).length;
const header: GeoHeader = { type: "header", schemaVersion: 1, kind: "moonbit-geo-comparison", profile, createdAt: new Date().toISOString(),
  expectedCases, publicCounts, parameters, engine: metadata,
  runtime: { node: process.version, v8: process.versions.v8, cpu: cpus()[0]?.model, platform: platform(), release: release() },
  harness: { commit: git.stdout.trim(), dirty: dirty.stdout.trim().length > 0, bundleSha256: sha(readFileSync(new URL(import.meta.url))) },
  methodology: {
    scope: "2D JavaScript release; both libraries compiled by one MoonBit toolchain; not a cross-target or memory benchmark",
    capacity: "16 for both providers; geo 0.1.3 hardcodes its maximum node entries to 16",
    construction: "common flat JavaScript input prepared outside timing; library-specific ingestion and construction included; one warmup and nine rotated samples",
    query: "ordinary result-owning APIs; same queries; warmups and calibrated per-provider iterations; rotated batches; full independent reference before and after timing",
    nearest: "geo query_nearest for k=1; native nearest_neighbors for k>1; k<=0 covered by integration tests; exact ordered distances checked, allowing tied IDs",
    segment: "MoonSTRtree measured; geo has no segment API in this bridge and is retained as unsupported with no score",
    boundaries: "identical bounds, nested bounds, empty and singleton inputs; all-hit/no-hit/touching cases retained; k<=0 checked in integration tests without contributing to speed scores",
    selection: "every declared case retained; equal case weights within common valid two-provider cohort; separate query/build/dataset summaries",
  } };
mkdirSync(dirname(output), { recursive: true });
writeFileSync(output, JSON.stringify(header) + "\n", { flag: "wx" });
let completed = 0, failures = 0;
const started = performance.now();

function run(tree: unknown, provider: number, query: Query): number[] | null {
  const suffix = provider === 0 ? "moon" : "geo";
  const [x1, y1, x2, y2] = query.bounds;
  switch (query.mode) {
    case "range": return engine[`range_${suffix}`](tree, x1, y1, x2, y2);
    case "point": return engine[`point_${suffix}`](tree, x1, y1);
    case "circle": return engine[`circle_${suffix}`](tree, x1, y1, query.radius);
    case "knn": return engine[`knn_${suffix}`](tree, x1, y1, query.k);
    case "segment": return provider === 0 ? engine.segment_moon(tree, x1, y1, x2, y2) : null;
  }
}

try {
  for (const descriptor of descriptors) {
    const input = geoInput(descriptor, cache);
    appendFileSync(output, JSON.stringify({ type: "dataset", ...descriptor, coordinateSha256: coordinateHash(input.coordinates), provenance: input.provenance }) + "\n");
    const coordinates = Array.from(input.coordinates);
    const trees: unknown[] = [], buildSamples: number[][] = [[], []], buildErrors: (string | null)[] = [null, null];
    for (let batch = -1; batch < 9; batch++) for (let step = 0; step < 2; step++) {
      const provider = (step + Math.max(0, batch) + completed) % 2;
      if (buildErrors[provider]) continue;
      try {
        const start = performance.now();
        trees[provider] = provider === 0 ? engine.build_moon(coordinates) : engine.build_geo(coordinates);
        const elapsed = performance.now() - start;
        if (batch >= 0) buildSamples[provider].push(elapsed);
      } catch (error) { buildErrors[provider] = String(error); }
    }
    for (const workload of geoQueries(input.coordinates)) {
      const expected = referenceQuery(input.coordinates, workload.query);
      const rows: GeoRow[] = GEO_PROVIDERS.map((name, provider) => ({ name, status: buildErrors[provider] ? "error" : provider === 1 && workload.group === "segment" ? "unsupported" : "mismatch",
        hits: null, iterations: 0, samples: [], medianMs: null, buildSamples: buildSamples[provider],
        buildMedianMs: buildErrors[provider] ? null : median(buildSamples[provider]), error: buildErrors[provider],
        path: provider === 1 && workload.group === "knn" ? workload.query.k === 1 ? "query_nearest" : "nearest_neighbors" : provider === 1 && workload.group === "segment" ? "no segment API; excluded from paired scores" : `${workload.group}_${provider === 0 ? "moon" : "geo"}` }));
      const validate = (provider: number) => {
        const actual = run(trees[provider], provider, workload.query);
        rows[provider].hits = actual?.length ?? null;
        return exactGeoAnswer(actual, expected, input, workload.query);
      };
      for (let provider = 0; provider < 2; provider++) {
        const row = rows[provider];
        if (row.status === "error" || row.status === "unsupported") continue;
        try {
          if (!validate(provider)) { row.error = "pre-timing answer differs from the exhaustive oracle"; continue; }
          const invoke = () => run(trees[provider], provider, workload.query)!;
          for (let warmup = 0; warmup < parameters.warmups; warmup++) invoke();
          row.iterations = calibrateIterations(invoke, undefined, parameters.targetBatchMs);
          row.status = "ok";
        } catch (error) { row.status = "error"; row.error = String(error); }
      }
      let checksum = 0;
      for (let batch = 0; batch < parameters.batches; batch++) for (let step = 0; step < 2; step++) {
        const provider = (step + batch + completed) % 2, row = rows[provider];
        if (row.status !== "ok") continue;
        try {
          const sample = sampleBatch(() => run(trees[provider], provider, workload.query)!, row.iterations);
          row.samples.push(sample.msPerQuery); checksum += sample.checksum;
        } catch (error) { row.status = "error"; row.error = String(error); }
      }
      for (let provider = 0; provider < 2; provider++) if (rows[provider].status === "ok") {
        const row = rows[provider];
        try {
          if (!validate(provider)) { row.status = "mismatch"; row.error = "post-timing answer differs from the exhaustive oracle"; }
          else row.medianMs = median(row.samples);
        } catch (error) { row.status = "error"; row.error = String(error); }
      }
      const item: GeoCase = { type: "case", id: `${descriptor.dataset}/${input.count}/capacity-16/seed-${input.seed}/${workload.id}`,
        dataset: descriptor.dataset, kind: descriptor.kind, count: input.count, capacity: 16, seed: input.seed,
        group: workload.group, workload: workload.id, query: workload.query, expectedHits: expected.length, checksum, rows };
      appendFileSync(output, JSON.stringify(item) + "\n");
      failures += rows.filter(row => row.status === "error" || row.status === "mismatch").length;
      completed++;
    }
    process.stderr.write(JSON.stringify({ completed, expectedCases, failures, dataset: input.id, count: input.count, elapsedSeconds: Math.round((performance.now() - started) / 1000) }) + "\n");
  }
} catch (error) {
  appendFileSync(output, JSON.stringify({ type: "aborted", completed, expectedCases, failures, error: String(error) }) + "\n");
  throw error;
}
const footer = { type: "complete", completed, expectedCases, failures, elapsedSeconds: (performance.now() - started) / 1000, finishedAt: new Date().toISOString() };
appendFileSync(output, JSON.stringify(footer) + "\n");
console.log(JSON.stringify({ ...footer, output }, null, 2));
if (failures || completed !== expectedCases) process.exitCode = 1;
