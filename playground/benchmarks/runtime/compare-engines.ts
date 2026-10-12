import { appendFileSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { createHash } from "node:crypto";
import { cpus, platform } from "node:os";
import { spawnSync } from "node:child_process";
import * as current from "../../src/.generated/moon-engine.js";
import metadata from "../../src/.generated/metadata.json";
import { createProvider, PROVIDER_NAMES, type Adapter } from "../../src/engine/providers";
import { referenceQuery } from "../../src/engine/reference";
import { boundsAt, distanceSquared } from "../../src/engine/geometry";
import { calibrateIterations, sampleBatch } from "../../src/engine/sampling";
import { PROFILES, SYNTHETIC_DATASETS, type ProfileName } from "../matrix/profiles";
import { makeQueries } from "../matrix/queries";
import { PUBLIC_DATASETS, publicInput, syntheticInput, type Input } from "./datasets";
import { median } from "./runner";

const argument = (name: string, fallback = "") => process.argv.slice(2).find(value => value.startsWith(`--${name}=`))?.slice(name.length + 3) ?? fallback;
const baselinePath = resolve(argument("baseline"));
if (!argument("baseline")) throw new Error("A frozen baseline module is required (--baseline=path.mjs)");
const profileName = argument("profile", "diagnostic") as ProfileName;
if (!(profileName in PROFILES)) throw new Error(`Unknown profile: ${profileName}`);
const profile = PROFILES[profileName];
const groups = argument("groups", "knn").split(",");
if (groups.some(group => !["all", "range", "point", "knn", "circle", "segment"].includes(group))) throw new Error("Unknown query group");
const baseline = await import(pathToFileURL(baselinePath).href) as typeof current;
const beforeMetadata = JSON.parse(readFileSync(resolve(dirname(baselinePath), "metadata.json"), "utf8"));
const output = resolve(argument("output", ".bench/reports/engine-comparison.ndjson"));
const cache = resolve(argument("cache", ".bench/datasets"));
const checksum = (bytes: Uint8Array | string) => createHash("sha256").update(bytes).digest("hex");
const git = spawnSync("git", ["rev-parse", "HEAD"], { encoding: "utf8" });
const dirty = spawnSync("git", ["status", "--porcelain"], { encoding: "utf8" });
if (git.status !== 0 || dirty.status !== 0) throw new Error("Cannot record repository state");
const variantCount = makeQueries(new Float64Array([0, 0, 1, 1])).filter(item => groups.includes("all") || groups.includes(item.group)).length;
const expectedCases = (SYNTHETIC_DATASETS.length * profile.counts.length + PUBLIC_DATASETS.length) * profile.seeds.length * profile.capacities.length * variantCount;
mkdirSync(dirname(output), { recursive: true });
writeFileSync(output, JSON.stringify({ type: "header", schemaVersion: 1, kind: "engine-comparison", profile: profileName, diagnostic: profileName === "diagnostic", groups, expectedCases,
  createdAt: new Date().toISOString(), runtime: { node: process.version, v8: process.versions.v8, platform: platform(), cpu: cpus()[0]?.model },
  before: { ...beforeMetadata, artifactSha256: checksum(readFileSync(baselinePath)) }, after: metadata,
  harness: { sha256: checksum(readFileSync(new URL(import.meta.url))), commit: git.stdout.trim(), dirty: dirty.stdout.trim().length > 0 },
  parameters: profile,
  methodology: { scope: "targeted same-process comparison; not a replacement for the full published matrix",
    construction: "excluded; each implementation builds its own index from identical coordinates",
    query: "profile-declared warmups and batch duration; per-provider calibration; rotated measured batches; complete oracle checks before and after timing",
    validation: "nearest results checked by exact squared-distance sequence, allowing tied IDs; other queries checked by exact complete ID sets" } }) + "\n", { flag: "wx" });
let completed = 0, failures = 0;
const started = performance.now();

function matches(actual: number[] | null, expected: number[], input: Input, query: ReturnType<typeof makeQueries>[number]["query"]) {
  if (!actual || actual.length !== expected.length || new Set(actual).size !== actual.length || actual.some(id => !Number.isInteger(id) || id < 0 || id >= input.count)) return false;
  if (query.mode === "knn") {
    const distances = (ids: number[]) => ids.map(id => distanceSquared(boundsAt(input.coordinates, id), query.bounds[0], query.bounds[1])).sort((a, b) => a - b);
    const a = distances(actual), b = distances(expected);
    return a.every((distance, index) => distance === b[index]);
  }
  const a = [...actual].sort((a, b) => a - b), b = [...expected].sort((a, b) => a - b);
  return a.every((id, index) => id === b[index]);
}

function run(input: Input) {
  appendFileSync(output, JSON.stringify({ type: "dataset", id: input.id, kind: input.kind, count: input.count, seed: input.seed, provenance: input.provenance }) + "\n");
  const workloads = makeQueries(input.coordinates).filter(item => groups.includes("all") || groups.includes(item.group));
  // Reference answers depend on input/query, never on capacity or provider.
  const expected = workloads.map(item => referenceQuery(input.coordinates, item.query));
  for (const capacity of profile.capacities) {
    const definitions = [
      { name: "MoonSTRtree before", build: () => createProvider("MoonSTRtree", input.coordinates, capacity, baseline) },
      { name: "MoonSTRtree after", build: () => createProvider("MoonSTRtree", input.coordinates, capacity, current) },
      ...PROVIDER_NAMES.slice(1).map(name => ({ name, build: () => createProvider(name, input.coordinates, capacity) })),
    ];
    const adapters = new Map<string, Adapter>(), errors = new Map<string, string>();
    for (let step = 0; step < definitions.length; step++) {
      const variant = definitions[(completed + step) % definitions.length];
      try { adapters.set(variant.name, variant.build()); } catch (error) { errors.set(variant.name, error instanceof Error ? error.message : String(error)); }
    }
    for (const [workloadIndex, workload] of workloads.entries()) {
      const answer = expected[workloadIndex];
      const rows = definitions.map(variant => ({ name: variant.name, valid: false, supported: true, error: errors.get(variant.name) ?? null,
        iterations: 0, hits: null as number | null, samples: [] as number[], medianMs: null as number | null }));
      for (const row of rows) {
        if (row.error) continue;
        try {
          const result = adapters.get(row.name)!.run(workload.query);
          row.supported = result !== null; row.hits = result?.length ?? null;
          row.valid = matches(result, answer, input, workload.query);
          if (!row.valid) continue;
          const invoke = () => {
            const result = adapters.get(row.name)!.run(workload.query);
            if (result === null) throw new Error("Provider became unsupported");
            return result;
          };
          for (let i = 0; i < profile.warmups; i++) invoke();
          row.iterations = calibrateIterations(invoke, undefined, profile.targetBatchMs);
        } catch (error) { row.valid = false; row.error = error instanceof Error ? error.message : String(error); }
      }
      let consumed = 0;
      for (let batch = 0; batch < profile.batches; batch++) for (let step = 0; step < rows.length; step++) {
        const row = rows[(completed + batch + step) % rows.length];
        if (!row.valid) continue;
        try {
          const sample = sampleBatch(() => {
            const result = adapters.get(row.name)!.run(workload.query);
            if (result === null) throw new Error("Provider became unsupported during timing");
            return result;
          }, row.iterations);
          row.samples.push(sample.msPerQuery); consumed += sample.checksum;
        } catch (error) { row.valid = false; row.error = error instanceof Error ? error.message : String(error); }
      }
      for (const row of rows) if (row.valid) {
        try { row.valid = matches(adapters.get(row.name)!.run(workload.query), answer, input, workload.query); }
        catch (error) { row.valid = false; row.error = error instanceof Error ? error.message : String(error); }
        if (row.valid && row.samples.length === profile.batches) row.medianMs = median(row.samples);
      }
      const id = `${input.id}/${input.count}/capacity-${capacity}/seed-${input.seed}/${workload.id}`;
      appendFileSync(output, JSON.stringify({ type: "case", id, dataset: input.id, kind: input.kind, count: input.count, capacity, seed: input.seed,
        workload: workload.id, group: workload.group, query: workload.query, expectedHits: answer.length, checksum: consumed, rows }) + "\n");
      completed++; failures += rows.filter(row => row.supported && !row.valid).length;
    }
    process.stderr.write(JSON.stringify({ completed, expectedCases, failures, dataset: input.id, count: input.count, capacity, elapsedSeconds: Math.round((performance.now() - started) / 1000) }) + "\n");
  }
}

try {
  for (const distribution of SYNTHETIC_DATASETS) for (const count of profile.counts) for (const seed of profile.seeds) run(syntheticInput(distribution, count, seed));
  for (const id of PUBLIC_DATASETS) for (const seed of profile.seeds) run(publicInput(id, seed, cache));
} catch (error) {
  appendFileSync(output, JSON.stringify({ type: "aborted", completed, expectedCases, failures, error: error instanceof Error ? error.message : String(error) }) + "\n");
  throw error;
}
const footer = { type: "complete", completed, expectedCases, failures, elapsedSeconds: (performance.now() - started) / 1000, finishedAt: new Date().toISOString() };
appendFileSync(output, JSON.stringify(footer) + "\n");
console.log(JSON.stringify({ ...footer, output }, null, 2));
if (failures || completed !== expectedCases) process.exitCode = 1;
