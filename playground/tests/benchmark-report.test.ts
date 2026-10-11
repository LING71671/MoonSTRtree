import { expect, test } from "bun:test";
import { compactReport } from "../benchmarks/runtime/report";
import { auditMatrix } from "../benchmarks/runtime/matrix-audit";
import { PROFILES } from "../benchmarks/matrix/profiles";
import { makeQueries } from "../benchmarks/matrix/queries";
import { ALL_FILTERS, BENCHMARK_PROVIDERS, constructionSummary, pairedSummary, querySummary, selectCases, type CompactCase } from "../src/domain/benchmark";

function caseAt(workload: string, times = [2, 1, 4, 8]): CompactCase {
  return { id: `uniform/1000/capacity-16/seed-0/${workload}`, dataset: "uniform", kind: "synthetic", count: 1000, capacity: 16, seed: 0,
    group: "range", workload, expectedHits: 1, rows: times.map(ms => ["ok", ms, ms, ms, ms * 10]) };
}

test("scores use geometric means on one common cohort, not arithmetic speedup averages", () => {
  const a = caseAt("a", [2, 1, 4, 8]), b = caseAt("b", [0.5, 1, 4, 8]);
  const summary = querySummary([a, b]);
  expect(summary[0].score).toBeCloseTo(1);
  expect(summary[1].score).toBeCloseTo(1);
  expect(summary[2].score).toBeCloseTo(0.25);
  expect(summary[0].eligible).toBe(2);
});

test("failed and unsupported rows stay in denominators and never acquire scores", () => {
  const valid = caseAt("valid"), failed = caseAt("failed"), unsupported = caseAt("unsupported");
  failed.rows[0] = ["mismatch", null, null, null, 20];
  unsupported.rows[2] = ["unsupported", null, null, null, 40];
  const summary = querySummary([valid, failed, unsupported]);
  expect(summary[0].total).toBe(3);
  expect(summary.every(row => row.eligible === 1)).toBe(true);
  expect(summary[0].failed).toBe(1);
  expect(summary[2].unsupported).toBe(1);
  expect(querySummary([failed])[0].score).toBeNull();
});

test("construction is counted once per index, not once per query", () => {
  const cases = [caseAt("a"), caseAt("b"), { ...caseAt("c"), capacity: 4 }];
  expect(constructionSummary(cases)[0].total).toBe(2);
  expect(constructionSummary(cases)[0].score).toBeCloseTo(0.5);
});

test("filters preserve empty selections and paired wins retain losses and the 5% band", () => {
  const cases = [caseAt("fast", [1, 2, 4, 8]), caseAt("slow", [2, 1, 4, 8]), caseAt("close", [1, 1.04, 4, 8])];
  expect(selectCases(cases, { ...ALL_FILTERS, kind: "public" })).toHaveLength(0);
  expect(selectCases(cases, { ...ALL_FILTERS, capacity: "16", seed: "0" })).toHaveLength(3);
  const paired = pairedSummary(cases)[0];
  expect([paired.faster, paired.close, paired.slower]).toEqual([1, 1, 1]);
  expect(paired.total).toBe(3);
});

function rawFixture() {
  const compact = caseAt("a");
  const rows = BENCHMARK_PROVIDERS.map((name, index) => ({ name, valid: true, supported: true, status: "ok", medianMs: compact.rows[index][1], buildMedianMs: compact.rows[index][4],
    samples: Array(3).fill(compact.rows[index][1]), buildSamples: Array(9).fill(compact.rows[index][4]), iterations: 2, hits: 1, path: "fixture", error: null }));
  return [{ type: "header", schemaVersion: 2, expectedCases: 1, parameters: { batches: 3 } }, { type: "case", ...compact, rows }, { type: "complete", completed: 1, expectedCases: 1, failures: 0 }];
}
const artifact = { rawFile: "fixture.ndjson.gz", rawSha256: "fixture", uncompressedSha256: "fixture" };
const serialize = (records: unknown[]) => records.map(record => JSON.stringify(record)).join("\n");
test("publication verifies sample medians and preserves every declared case", () => {
  const records = rawFixture();
  expect(compactReport(serialize(records), artifact).cases).toHaveLength(1);
  (records[1] as any).rows[0].medianMs = 99;
  expect(() => compactReport(serialize(records), artifact)).toThrow("Median differs");
});
test("publication rejects incomplete, duplicate and falsely successful reports", () => {
  const records = rawFixture();
  expect(() => compactReport(serialize(records.slice(0, -1)), artifact)).toThrow("Incomplete benchmark");
  expect(() => compactReport(serialize([records[0], records[1], records[1], records[2]]), artifact)).toThrow("Duplicate benchmark case");
  (records[1] as any).rows[0].status = "mismatch";
  expect(() => compactReport(serialize(records), artifact)).toThrow("Inconsistent validation flags");
});

test("matrix audit catches a skipped query even when the footer and counts agree", () => {
  const report = compactReport(serialize(rawFixture()), artifact);
  report.header.profile = "diagnostic";
  report.header.parameters = { ...PROFILES.diagnostic, counts: [...PROFILES.diagnostic.counts], capacities: [...PROFILES.diagnostic.capacities], seeds: [...PROFILES.diagnostic.seeds] };
  report.header.selectedDatasets = ["uniform"];
  report.header.expectedCases = 38;
  report.datasets = [{ id: "uniform", count: 10000, seed: 42 }];
  report.cases = makeQueries(new Float64Array([0, 0, 1, 1])).map(query => ({ ...caseAt(query.id), count: 10000, seed: 42, id: `uniform/10000/capacity-16/seed-42/${query.id}` }));
  expect(() => auditMatrix(report)).not.toThrow();
  report.cases[0] = { ...report.cases[0], id: report.cases[1].id };
  expect(() => auditMatrix(report)).toThrow("Unexpected or duplicate matrix case");
});
