import { BENCHMARK_PROVIDERS, quantile, type BenchmarkHeader, type CompactCase, type CompactReport, type CompactRow } from "../../src/domain/benchmark";
import type { BenchmarkCase } from "./runner";

const finite = (value: number) => typeof value === "number" && Number.isFinite(value);
export function compactReport(ndjson: string, artifact: CompactReport["artifact"]): CompactReport {
  const records = ndjson.trim().split(/\r?\n/).map((line, index) => {
    try { return JSON.parse(line); } catch { throw new Error(`Invalid JSON at report line ${index + 1}`); }
  });
  const header = records[0] as BenchmarkHeader, footer = records.at(-1);
  if (header.type !== "header" || header.schemaVersion !== 2 || !Number.isInteger(header.expectedCases) || header.expectedCases < 1) throw new Error("A version-2 benchmark header is required");
  if (footer?.type !== "complete" || footer.completed !== header.expectedCases || footer.expectedCases !== header.expectedCases) throw new Error("Incomplete benchmark: all declared cases must finish before publication");
  const cases: CompactCase[] = [], ids = new Set<string>(), datasets: Record<string, unknown>[] = [];
  let failures = 0;
  for (const record of records.slice(1, -1)) {
    if (record.type === "dataset") { datasets.push(record); continue; }
    if (record.type !== "case") throw new Error(`Unexpected benchmark record: ${record.type}`);
    const item = record as BenchmarkCase;
    if (ids.has(item.id)) throw new Error(`Duplicate benchmark case: ${item.id}`);
    if (item.id !== `${item.dataset}/${item.count}/capacity-${item.capacity}/seed-${item.seed}/${item.workload}`) throw new Error(`Case identity mismatch: ${item.id}`);
    ids.add(item.id);
    if (!Array.isArray(item.rows) || item.rows.length !== BENCHMARK_PROVIDERS.length) throw new Error(`Missing providers: ${item.id}`);
    const rows: CompactRow[] = item.rows.map((row, index) => {
      if (row.name !== BENCHMARK_PROVIDERS[index] || !["ok", "unsupported", "mismatch", "error"].includes(row.status)) throw new Error(`Invalid provider/status: ${item.id}`);
      if (row.valid !== (row.status === "ok") || row.supported !== (row.status !== "unsupported")) throw new Error(`Inconsistent validation flags: ${item.id}/${row.name}`);
      if (row.status === "ok") {
        if (row.samples.length !== header.parameters.batches || row.buildSamples.length !== 9 || !row.samples.every(value => finite(value) && value > 0) || !row.buildSamples.every(value => finite(value) && value >= 0) || !Number.isInteger(row.iterations) || row.iterations < 1) throw new Error(`Incomplete timing samples: ${item.id}/${row.name}`);
        if (quantile(row.samples, 0.5) !== row.medianMs || quantile(row.buildSamples, 0.5) !== row.buildMedianMs) throw new Error(`Median differs from raw samples: ${item.id}/${row.name}`);
      } else if (row.medianMs !== null) throw new Error(`Invalid result retained a score: ${item.id}/${row.name}`);
      if (row.supported && !row.valid) failures++;
      const compact: CompactRow = [row.status, row.medianMs, row.status === "ok" ? quantile(row.samples, 0.25) : null, row.status === "ok" ? quantile(row.samples, 0.75) : null, row.buildMedianMs];
      if (row.error) compact.push(`${row.error.phase}: ${row.error.message}`);
      return compact;
    });
    cases.push({ id: item.id, dataset: item.dataset, kind: item.kind, count: item.count, capacity: item.capacity, seed: item.seed, group: item.group, workload: item.workload, expectedHits: item.expectedHits, rows });
  }
  if (cases.length !== header.expectedCases || failures !== footer.failures) throw new Error("Report totals do not match retained case records");
  const groups = new Map<string, CompactCase[]>();
  for (const item of cases) { const key = `${item.dataset}/${item.count}/${item.capacity}/${item.seed}`; const group = groups.get(key) ?? []; group.push(item); groups.set(key, group); }
  for (const group of groups.values()) for (let provider = 0; provider < 4; provider++) {
    if (group.some(item => item.rows[provider][4] !== group[0].rows[provider][4])) throw new Error(`Inconsistent build observations: ${group[0].id}`);
  }
  const { completed, expectedCases, elapsedSeconds, finishedAt } = footer;
  return { schemaVersion: 1, header, datasets, cases, completion: { completed, expectedCases, failures, elapsedSeconds, finishedAt }, artifact };
}
