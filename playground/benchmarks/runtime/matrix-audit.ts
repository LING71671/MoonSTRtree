import { PROFILES, SYNTHETIC_DATASETS, type ProfileName } from "../matrix/profiles";
import { makeQueries } from "../matrix/queries";
import catalog from "../data/sources.json";
import type { CompactReport } from "../../src/domain/benchmark";

// Reconstruct the declared matrix independently of the runner's case counter.
// A complete footer alone cannot prove that a whole dataset was not skipped.
export function auditMatrix(report: CompactReport) {
  const { header } = report;
  const profile = PROFILES[header.profile as ProfileName];
  if (!profile || (Object.keys(profile) as (keyof typeof profile)[]).some(key => JSON.stringify(header.parameters[key]) !== JSON.stringify(profile[key]))) throw new Error("Report profile does not match the declared benchmark matrix");
  const known = ["all", "synthetic", "public", ...SYNTHETIC_DATASETS, ...catalog.sources.map(source => source.id)];
  if (header.selectedDatasets.some(id => !known.includes(id))) throw new Error("Unknown dataset selector in benchmark header");
  const include = (id: string, kind: string) => header.selectedDatasets.some(selector => selector === "all" || selector === kind || selector === id);
  const inputs = new Map<string, { id: string; count: number; seed: number }>();
  for (const id of SYNTHETIC_DATASETS.filter(id => include(id, "synthetic"))) for (const count of profile.counts) for (const seed of profile.seeds)
    inputs.set(`${id}/${count}/${seed}`, { id, count, seed });
  for (const source of catalog.sources.filter(source => include(source.id, "public"))) {
    const dataset = report.datasets.find(item => item.id === source.id);
    const provenance = dataset?.provenance as Record<string, unknown> | undefined;
    const count = provenance?.records;
    if (!Number.isInteger(count) || Number(count) < 1 || provenance?.rawSha256 !== source.sha256) throw new Error(`Missing or unpinned public dataset: ${source.id}`);
    for (const seed of profile.seeds) inputs.set(`${source.id}/${count}/${seed}`, { id: source.id, count: Number(count), seed });
  }
  const observed = new Set<string>();
  for (const dataset of report.datasets) {
    const key = `${dataset.id}/${dataset.count}/${dataset.seed}`;
    if (!inputs.has(key) || observed.has(key)) throw new Error(`Unexpected or duplicate input configuration: ${key}`);
    observed.add(key);
  }
  if (observed.size !== inputs.size) throw new Error("Benchmark skipped a declared input configuration");
  const workloads = makeQueries(new Float64Array([0, 0, 1, 1])).map(item => item.id);
  const expected = new Set<string>();
  for (const { id, count, seed } of inputs.values()) for (const capacity of profile.capacities) for (const workload of workloads)
    expected.add(`${id}/${count}/capacity-${capacity}/seed-${seed}/${workload}`);
  if (expected.size !== header.expectedCases || report.cases.length !== expected.size) throw new Error("Declared matrix size differs from the published report");
  for (const item of report.cases) if (!expected.delete(item.id)) throw new Error(`Unexpected or duplicate matrix case: ${item.id}`);
  if (expected.size) throw new Error("Benchmark skipped a declared query configuration");
}
