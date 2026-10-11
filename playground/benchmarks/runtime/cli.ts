import { appendFileSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { dirname, resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { cpus, platform, release } from "node:os";
import { createHash } from "node:crypto";
import type * as Moon from "../../src/.generated/moon-engine.js";
import metadata from "../../src/.generated/metadata.json";
import { PROFILES, SYNTHETIC_DATASETS, type ProfileName } from "../matrix/profiles";
import { PUBLIC_DATASETS, publicInput, syntheticInput } from "./datasets";
import { BUILD_SAMPLES, measureInput } from "./runner";
import { QUERY_VARIANT_COUNT } from "../matrix/queries";

const argument = (name: string, fallback: string) => process.argv.slice(2).find(value => value.startsWith(`--${name}=`))?.slice(name.length + 3) ?? fallback;
const profileName = argument("profile", "diagnostic") as ProfileName;
if (!(profileName in PROFILES)) throw new Error(`Unknown profile: ${profileName}`);
const profile = PROFILES[profileName];
const selected = argument("datasets", "all").split(",");
const known = ["all", "synthetic", "public", ...SYNTHETIC_DATASETS, ...PUBLIC_DATASETS];
if (selected.some(name => !known.includes(name))) throw new Error(`Unknown datasets: ${selected.filter(name => !known.includes(name)).join(", ")}`);
const include = (name: string) => selected.includes("all") || selected.includes(name);
const output = resolve(argument("output", `.bench/reports/${profileName}.ndjson`));
const cache = resolve(argument("cache", ".bench/datasets"));
const baseline = argument("baseline", "");
let engine: typeof Moon | undefined;
let engineMetadata: Record<string, unknown> = metadata;
if (baseline) {
  const path = resolve(baseline);
  engine = (await import(pathToFileURL(path).href)).core as typeof Moon;
  engineMetadata = { artifact: path.split(/[\\/]/).pop(), artifactSha256: createHash("sha256").update(readFileSync(path)).digest("hex"), scope: "frozen local compiled MoonBit baseline; same current competitor adapters" };
}
mkdirSync(dirname(output), { recursive: true });
const harnessFiles = ["src/data/generate.ts", "src/domain/types.ts", "src/engine/geometry.ts", "src/engine/providers.ts", "src/engine/reference.ts", "src/engine/sampling.ts", "src/engine/scan.ts",
  "benchmarks/data/fetch_public.py", "benchmarks/data/sources.json", "benchmarks/matrix/profiles.ts", "benchmarks/matrix/queries.ts", "benchmarks/runtime/datasets.ts", "benchmarks/runtime/runner.ts", "benchmarks/runtime/cli.ts"];
const harnessHash = createHash("sha256");
for (const path of harnessFiles.sort()) harnessHash.update(path + "\0").update(readFileSync(path)).update("\0");
const syntheticCases = SYNTHETIC_DATASETS.filter(name => include(name) || selected.includes("synthetic")).length * profile.counts.length;
const publicCases = PUBLIC_DATASETS.filter(name => include(name) || selected.includes("public")).length;
const expectedCases = (syntheticCases + publicCases) * profile.seeds.length * profile.capacities.length * QUERY_VARIANT_COUNT;
const git = (args: string[]) => { const result = spawnSync("git", args, { encoding: "utf8" }); if (result.status !== 0) throw new Error("Cannot record repository state"); return result.stdout.trim(); };
const sourceState = { commit: git(["rev-parse", "HEAD"]), dirty: git(["status", "--porcelain"]).length > 0 };
writeFileSync(output, JSON.stringify({ type: "header", schemaVersion: 2, profile: profileName, diagnostic: profileName === "diagnostic", selectedDatasets: selected, expectedCases, createdAt: new Date().toISOString(), runtime: { name: "Node / V8", node: process.version, v8: process.versions.v8, platform: platform(), release: release(), cpu: cpus()[0]?.model, logicalCores: cpus().length }, engine: engineMetadata, harness: { sha256: harnessHash.digest("hex"), files: harnessFiles, ...sourceState }, parameters: profile, methodology: { build: `one warmup then ${BUILD_SAMPLES} host-ingestion plus construction samples; indexed provider order rotated across samples`, query: "per-provider iteration calibration; provider order rotated per batch; complete oracle validation before and after timing", oracle: "independent exhaustive scan and full nearest-distance sort", scope: "2D planar queries; public geographic coordinates are not geodesic distances", selection: "all declared matrix cases, including no-hit and slower cases; errors and unsupported rows retained" } }) + "\n", { flag: "wx" });
let completed = 0, failures = 0;
const started = performance.now();
function run(input: ReturnType<typeof syntheticInput>) {
  appendFileSync(output, JSON.stringify({ type: "dataset", id: input.id, kind: input.kind, count: input.count, seed: input.seed, order: input.order, provenance: input.provenance }) + "\n");
  for (const capacity of profile.capacities) {
    for (const result of measureInput(input, capacity, profile, engine)) {
      appendFileSync(output, JSON.stringify({ type: "case", ...result }) + "\n");
      completed++;
      failures += result.rows.filter(row => row.supported && !row.valid).length;
      if (completed % 38 === 0) process.stderr.write(JSON.stringify({ completed, failures, elapsedSeconds: Math.round((performance.now() - started) / 1000), dataset: input.id, capacity, seed: input.seed }) + "\n");
    }
  }
}
try {
  for (const distribution of SYNTHETIC_DATASETS) if (include(distribution) || selected.includes("synthetic")) {
    for (const count of profile.counts) for (const seed of profile.seeds) run(syntheticInput(distribution, count, seed));
  }
  for (const id of PUBLIC_DATASETS) if (include(id) || selected.includes("public")) {
    for (const seed of profile.seeds) run(publicInput(id, seed, cache));
  }
} catch (error) {
  appendFileSync(output, JSON.stringify({ type: "aborted", completed, expectedCases, failures, error: error instanceof Error ? error.message : String(error), finishedAt: new Date().toISOString() }) + "\n");
  throw error;
}
const footer = { type: "complete", completed, expectedCases, failures, elapsedSeconds: (performance.now() - started) / 1000, finishedAt: new Date().toISOString() };
appendFileSync(output, JSON.stringify(footer) + "\n");
console.log(JSON.stringify({ ...footer, output }, null, 2));
if (failures || completed !== expectedCases || completed === 0) process.exitCode = 1;
