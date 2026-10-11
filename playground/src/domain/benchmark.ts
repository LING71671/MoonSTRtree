import type { Mode, Provider } from "./types";

// Positions are part of the published compact-report schema, not a ranking.
export const BENCHMARK_PROVIDERS: readonly Provider[] = ["MoonSTRtree", "Flatbush", "RBush", "Linear scan"];
export type RowStatus = "ok" | "unsupported" | "mismatch" | "error";
export type CompactRow = [status: RowStatus, medianMs: number | null, q1Ms: number | null, q3Ms: number | null, buildMedianMs: number | null, error?: string];
export type CompactCase = {
  id: string; dataset: string; kind: "synthetic" | "public"; count: number; capacity: number; seed: number;
  group: Mode; workload: string; expectedHits: number; rows: CompactRow[];
};
export type BenchmarkHeader = {
  type: "header"; schemaVersion: 2; profile: string; diagnostic: boolean; expectedCases: number; selectedDatasets: string[]; createdAt: string;
  parameters: { batches: number; warmups: number; targetBatchMs: number; counts: number[]; capacities: number[]; seeds: number[] };
  runtime: { name: string; node: string; v8: string; platform: string; release: string; cpu: string; logicalCores: number };
  engine: { compiler: string; sourceSha256: string; versions: Record<string, string>; [key: string]: unknown };
  harness: { sha256: string; files: string[]; commit: string; dirty: boolean };
  methodology: Record<string, string>;
};
export type CompactReport = {
  schemaVersion: 1; header: BenchmarkHeader; datasets: Record<string, unknown>[]; cases: CompactCase[];
  completion: { completed: number; expectedCases: number; failures: number; elapsedSeconds: number; finishedAt: string };
  artifact: { rawFile: string; rawSha256: string; uncompressedSha256: string };
};
export type BenchmarkFilters = { dataset: string; kind: string; count: string; capacity: string; seed: string; group: string };
export const ALL_FILTERS: BenchmarkFilters = { dataset: "all", kind: "all", count: "all", capacity: "all", seed: "all", group: "all" };
export function selectCases(cases: CompactCase[], filters: BenchmarkFilters) {
  return cases.filter(item => Object.entries(filters).every(([key, value]) => value === "all" || String(item[key as keyof CompactCase]) === value));
}
export function quantile(values: number[], fraction: number): number | null {
  if (!values.length) return null;
  const sorted = [...values].sort((a, b) => a - b), position = (sorted.length - 1) * fraction;
  const low = Math.floor(position), high = Math.ceil(position);
  return sorted[low] + (sorted[high] - sorted[low]) * (position - low);
}
const positive = (value: number | null): value is number => value !== null && Number.isFinite(value) && value > 0;
const geometricMean = (values: number[]) => values.length ? Math.exp(values.reduce((sum, value) => sum + Math.log(value), 0) / values.length) : null;
export type AggregateRow = { name: Provider; score: number | null; medianMs: number | null; eligible: number; total: number; failed: number; unsupported: number };
export function querySummary(cases: CompactCase[]): AggregateRow[] {
  // Every displayed score uses the same four-provider cohort. Incorrect,
  // unsupported and missing observations remain in the reported denominator.
  const common = cases.filter(item => item.rows.length === BENCHMARK_PROVIDERS.length && item.rows.every(row => row[0] === "ok" && positive(row[1])));
  return BENCHMARK_PROVIDERS.map((name, index) => ({ name,
    score: geometricMean(common.map(item => item.rows[1][1]! / item.rows[index][1]!)),
    medianMs: quantile(common.map(item => item.rows[index][1]!), 0.5), eligible: common.length, total: cases.length,
    failed: cases.filter(item => ["error", "mismatch"].includes(item.rows[index][0])).length,
    unsupported: cases.filter(item => item.rows[index][0] === "unsupported").length,
  }));
}
export function constructionSummary(cases: CompactCase[]): AggregateRow[] {
  const distinct = new Map<string, CompactCase>();
  for (const item of cases) distinct.set(`${item.dataset}/${item.count}/${item.capacity}/${item.seed}`, item);
  const builds = [...distinct.values()];
  const common = builds.filter(item => item.rows.slice(0, 3).every(row => positive(row[4])));
  return BENCHMARK_PROVIDERS.slice(0, 3).map((name, index) => ({ name,
    score: geometricMean(common.map(item => item.rows[1][4]! / item.rows[index][4]!)),
    medianMs: quantile(common.map(item => item.rows[index][4]!), 0.5), eligible: common.length, total: builds.length,
    failed: builds.filter(item => !positive(item.rows[index][4])).length, unsupported: 0,
  }));
}
export function pairedSummary(cases: CompactCase[]) {
  return BENCHMARK_PROVIDERS.slice(1).map((name, offset) => {
    const index = offset + 1;
    const pairs = cases.filter(item => item.rows[0][0] === "ok" && item.rows[index][0] === "ok" && positive(item.rows[0][1]) && positive(item.rows[index][1]));
    const ratios = pairs.map(item => item.rows[index][1]! / item.rows[0][1]!);
    return { name, eligible: pairs.length, total: cases.length, speedup: geometricMean(ratios),
      faster: ratios.filter(ratio => ratio > 1.05).length, slower: ratios.filter(ratio => ratio < 1 / 1.05).length,
      close: ratios.filter(ratio => ratio >= 1 / 1.05 && ratio <= 1.05).length,
      p10: quantile(ratios, 0.1), p90: quantile(ratios, 0.9),
    };
  });
}
