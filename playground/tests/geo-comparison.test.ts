import { describe, expect, test } from "bun:test";
import { GEO_PROFILES, coordinateHash, exactGeoAnswer, geoDescriptors, geoInput, geoQueries } from "../benchmarks/runtime/geo-model";
import { auditGeoReport, summarizeGeoBuilds, summarizeGeoCases, type GeoCase, type GeoHeader, type GeoRow } from "../benchmarks/runtime/geo-report";
import catalog from "../benchmarks/data/sources.json";
import { referenceQuery } from "../src/engine/reference";

function fixture() {
  const profile = "diagnostic", parameters = GEO_PROFILES[profile];
  const publicCounts = Object.fromEntries(catalog.sources.map(source => [source.id, 1]));
  const descriptors = geoDescriptors(profile, publicCounts);
  const workloads = geoQueries(new Float64Array([0, 0, 1, 1]));
  const header: GeoHeader = { type: "header", schemaVersion: 1, kind: "moonbit-geo-comparison", profile, parameters, publicCounts,
    createdAt: "2026-10-20T00:00:00Z", expectedCases: descriptors.length * workloads.length,
    engine: { compiler: "fixture", target: "JavaScript", mode: "release", capacity: 16, artifactSha256: "a".repeat(64), moon: {sourceSha256: "b".repeat(64)}, geo: {version: "0.1.3", sourceSha256: "c".repeat(64)} }, runtime: {}, harness: {}, methodology: {} };
  const records: any[] = [header];
  for (const input of descriptors) {
    records.push({ type: "dataset", ...input, coordinateSha256: "d".repeat(64), provenance: input.kind === "public" ? { records: input.count, rawSha256: catalog.sources.find(source => source.id === input.dataset)!.sha256 } : {} });
    for (const workload of workloads) {
      const rows: GeoRow[] = ["MoonSTRtree", "totto2727/geo"].map((name, index) => ({ name: name as GeoRow["name"], status: index === 1 && workload.group === "segment" ? "unsupported" : "ok",
        hits: index === 1 && workload.group === "segment" ? null : 0,
        iterations: index === 1 && workload.group === "segment" ? 0 : 4,
        samples: index === 1 && workload.group === "segment" ? [] : Array(parameters.batches).fill(index + 1),
        medianMs: index === 1 && workload.group === "segment" ? null : index + 1,
        buildSamples: Array(9).fill(index + 1), buildMedianMs: index + 1, error: null, path: "fixture" }));
      records.push({ type: "case", id: `${input.dataset}/${input.count}/capacity-16/seed-${input.seed}/${workload.id}`, dataset: input.dataset, kind: input.kind, count: input.count, capacity: 16, seed: input.seed,
        group: workload.group, workload: workload.id, query: workload.query, expectedHits: 0, checksum: 0, rows } satisfies GeoCase);
    }
  }
  records.push({ type: "complete", completed: header.expectedCases, expectedCases: header.expectedCases, failures: 0, elapsedSeconds: 1, finishedAt: "2026-10-20T00:00:01Z" });
  return records;
}
const encode = (records: unknown[]) => records.map(item => JSON.stringify(item)).join("\n");

describe("direct geo comparison evidence", () => {
  test("complete declared matrix retains unsupported coverage and counts each build once", () => {
    const result = auditGeoReport(encode(fixture()));
    expect(result.cases).toHaveLength(640);
    const summary = summarizeGeoCases(result.cases);
    expect(summary.eligible).toBe(560);
    expect(summary.providers[1].unsupported).toBe(80);
    expect(summary.moonRelativeToGeo).toBeCloseTo(2);
    expect(summarizeGeoBuilds(result.cases).selected).toBe(16);
  });
  test("a missing case is rejected even with matching reduced footer counts", () => {
    const records = fixture(); records.splice(2, 1); records[0].expectedCases--; records.at(-1).completed--; records.at(-1).expectedCases--;
    expect(() => auditGeoReport(encode(records))).toThrow("Incomplete declared geo matrix");
  });
  test("duplicate IDs, changed k, forged medians and unpinned public data are rejected", () => {
    const duplicate = fixture(); duplicate.splice(3, 0, structuredClone(duplicate[2]));
    expect(() => auditGeoReport(encode(duplicate))).toThrow("duplicate geo case");
    const k = fixture(); k.find(item => item.type === "case" && item.group === "knn").query.k = 999;
    expect(() => auditGeoReport(encode(k))).toThrow("Invalid geo query");
    const median = fixture(); median[2].rows[0].medianMs = 7;
    expect(() => auditGeoReport(encode(median))).toThrow("Invalid geo raw samples");
    const source = fixture(); source.find(item => item.type === "dataset" && item.kind === "public").provenance.rawSha256 = "0".repeat(64);
    expect(() => auditGeoReport(encode(source))).toThrow("Unpinned geo public source");
  });
  test("unsupported rows cannot acquire scores or conceal supported work", () => {
    const scored = fixture(); const row = scored.find(item => item.type === "case" && item.group === "segment").rows[1]; row.medianMs = 1;
    expect(() => auditGeoReport(encode(scored))).toThrow("Invalid geo score retained");
    const excluded = fixture(); Object.assign(excluded[2].rows[0], {status:"unsupported", samples:[], medianMs:null, hits:null});
    expect(() => auditGeoReport(encode(excluded))).toThrow("Unexpected geo exclusion");
  });
  test("oracle accepts tied nearest IDs but rejects wrong order, duplicates and missing hits", () => {
    const input = { ...geoInput({dataset:"singleton",count:3,seed:0,kind:"boundary"}, "unused"), coordinates:new Float64Array([0,0,0,0,1,0,1,0,-1,0,-1,0]) };
    const query = { mode:"knn" as const, bounds:[0,0,0,0] as [number,number,number,number], radius:0, k:2 };
    expect(exactGeoAnswer([0,2],[0,1],input,query)).toBe(true);
    expect(exactGeoAnswer([1,0],[0,1],input,query)).toBe(false);
    expect(exactGeoAnswer([0,0],[0,1],input,query)).toBe(false);
    expect(exactGeoAnswer([0],[0,1],input,query)).toBe(false);
  });
  test("identical bounds and nested bounds are reproducible and include touching/all-hit/no-hit queries", () => {
    const input = geoInput({dataset:"identical-bounds",count:1000,seed:42,kind:"boundary"}, "unused");
    expect(Array.from(input.coordinates).every((value,index)=>value===[100,100,900,900][index%4])).toBe(true);
    expect(coordinateHash(input.coordinates)).toBe(coordinateHash(geoInput({dataset:"identical-bounds",count:1000,seed:42,kind:"boundary"}, "unused").coordinates));
    expect(geoQueries(input.coordinates).map(item=>item.id)).toContain("range/touch-first-lower");
    expect(geoQueries(input.coordinates).map(item=>item.id)).toContain("range/outside");
    expect(geoQueries(input.coordinates).map(item=>item.id)).toContain("range/full");
    for (const dataset of ["identical-bounds", "nested-bounds"]) {
      const input=geoInput({dataset,count:1000,seed:42,kind:"boundary"},"unused");
      for (const workload of geoQueries(input.coordinates).filter(item=>["range/full","range/outside","point/anchor-0"].includes(item.id))) {
        expect(referenceQuery(input.coordinates,workload.query).length).toBe(workload.id==="range/outside"?0:1000);
      }
    }
  });
});
