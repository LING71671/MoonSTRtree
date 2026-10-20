import type { Query } from "../../src/domain/types";
import catalog from "../data/sources.json";
import { GEO_PROFILES, GEO_PROVIDERS, GEO_VERSION, geoDescriptors, geoQueries, type GeoProfile } from "./geo-model";
import { median } from "./runner";

export type GeoRow = {
  name: typeof GEO_PROVIDERS[number]; status: "ok" | "mismatch" | "error" | "unsupported";
  hits: number | null; iterations: number; samples: number[]; medianMs: number | null;
  buildSamples: number[]; buildMedianMs: number | null; error: string | null; path: string;
};
export type GeoCase = { type: "case"; id: string; dataset: string; kind: string; count: number; capacity: number; seed: number;
  group: Query["mode"]; workload: string; query: Query; expectedHits: number; checksum: number; rows: GeoRow[] };
export type GeoHeader = { type: "header"; schemaVersion: number; kind: string; profile: GeoProfile; createdAt: string;
  expectedCases: number; publicCounts: Record<string, number>; parameters: typeof GEO_PROFILES[GeoProfile];
  engine: { compiler: string; target: string; mode: string; capacity: number; artifactSha256: string; moon: {sourceSha256: string}; geo: {version: string; sourceSha256: string} };
  runtime: Record<string, unknown>; harness: Record<string, unknown>; methodology: Record<string, string> };

const positive = (value: unknown): value is number => typeof value === "number" && Number.isFinite(value) && value > 0;
const hash = (value: unknown) => typeof value === "string" && /^[a-f0-9]{64}$/.test(value);
const geometricMean = (values: number[]) => values.length ? Math.exp(values.reduce((sum, value) => sum + Math.log(value), 0) / values.length) : null;

export function auditGeoReport(ndjson: string) {
  const records = ndjson.trim().split(/\r?\n/).map(line => JSON.parse(line));
  const header = records[0] as GeoHeader, footer = records.at(-1);
  if (header.type !== "header" || header.schemaVersion !== 1 || header.kind !== "moonbit-geo-comparison" || footer?.type !== "complete") throw new Error("A complete geo-comparison report is required");
  if (!(header.profile in GEO_PROFILES) || JSON.stringify(header.parameters) !== JSON.stringify(GEO_PROFILES[header.profile])) throw new Error("Geo profile differs from the declared protocol");
  if (header.engine.capacity !== 16 || header.engine.geo.version !== GEO_VERSION || header.engine.target !== "JavaScript" || header.engine.mode !== "release" || !hash(header.engine.artifactSha256) || !hash(header.engine.moon.sourceSha256) || !hash(header.engine.geo.sourceSha256)) throw new Error("Invalid engine fingerprints or settings");
  const descriptors = geoDescriptors(header.profile, header.publicCounts);
  const inputs = new Map(descriptors.map(item => [`${item.dataset}/${item.count}/${item.seed}`, item]));
  const workloads = geoQueries(new Float64Array([0, 0, 1, 1]));
  const identities = new Set(descriptors.flatMap(item => workloads.map(query => `${item.dataset}/${item.count}/capacity-16/seed-${item.seed}/${query.id}`)));
  const cases: GeoCase[] = [], datasets: Record<string, any>[] = [], seenInputs = new Set<string>(), builds = new Map<string, string>();
  let failures = 0;
  for (const record of records.slice(1, -1)) {
    if (record.type === "dataset") {
      const key = `${record.dataset}/${record.count}/${record.seed}`, expected = inputs.get(key);
      if (!expected || seenInputs.has(key) || record.kind !== expected.kind || !hash(record.coordinateSha256)) throw new Error(`Unexpected or duplicate geo input: ${key}`);
      if (record.kind === "public") {
        const source = catalog.sources.find(source => source.id === record.dataset)!;
        if (record.provenance?.records !== record.count || record.provenance?.rawSha256 !== source.sha256) throw new Error(`Unpinned geo public source: ${key}`);
      }
      seenInputs.add(key);
      datasets.push(record);
      continue;
    }
    if (record.type !== "case") throw new Error(`Unexpected geo record: ${record.type}`);
    const item = record as GeoCase;
    const key = `${item.dataset}/${item.count}/${item.seed}`;
    const descriptor = inputs.get(key);
    if (!descriptor || item.kind !== descriptor.kind || !seenInputs.has(key) || item.capacity !== 16 || item.id !== `${item.dataset}/${item.count}/capacity-16/seed-${item.seed}/${item.workload}` || !identities.delete(item.id)) throw new Error(`Unexpected or duplicate geo case: ${item.id}`);
    const workload = workloads.find(workload => workload.id === item.workload);
    if (!workload || item.group !== workload.group || item.query.mode !== workload.group || !Array.isArray(item.query.bounds) || item.query.bounds.length !== 4 || !item.query.bounds.every(Number.isFinite) || item.query.k !== workload.query.k || !Number.isFinite(item.query.radius) || item.query.radius < 0) throw new Error(`Invalid geo query: ${item.id}`);
    if (!Number.isInteger(item.expectedHits) || item.expectedHits < 0 || item.expectedHits > item.count || item.rows.length !== 2) throw new Error(`Invalid geo answer coverage: ${item.id}`);
    item.rows.forEach((row, provider) => {
      if (row.name !== GEO_PROVIDERS[provider] || !["ok", "unsupported", "mismatch", "error"].includes(row.status)) throw new Error(`Invalid geo provider/status: ${item.id}`);
      if (row.status === "unsupported" && !(provider === 1 && item.group === "segment")) throw new Error(`Unexpected geo exclusion: ${item.id}`);
      if (provider === 1 && item.group === "segment" && row.status !== "unsupported" && row.status !== "error") throw new Error(`Undeclared geo segment path: ${item.id}`);
      if (row.status === "ok") {
        if (row.error !== null || row.hits !== item.expectedHits || !Number.isInteger(row.iterations) || row.iterations < 1 || row.samples.length !== header.parameters.batches || !row.samples.every(positive) || median(row.samples) !== row.medianMs) throw new Error(`Invalid geo raw samples: ${item.id}/${row.name}`);
      } else if (row.medianMs !== null || (row.status === "unsupported" && (row.samples.length !== 0 || row.hits !== null))) throw new Error(`Invalid geo score retained: ${item.id}/${row.name}`);
      if (row.status === "error" || row.status === "mismatch") failures++;
      if (((row.status === "ok" || row.status === "unsupported") && row.buildMedianMs === null) || (row.buildMedianMs !== null && (row.buildSamples.length !== 9 || !row.buildSamples.every(value => typeof value === "number" && Number.isFinite(value) && value >= 0) || median(row.buildSamples) !== row.buildMedianMs))) throw new Error(`Invalid geo construction samples: ${item.id}/${row.name}`);
    });
    const serialized = JSON.stringify(item.rows.map(row => [row.buildSamples, row.buildMedianMs]));
    if (builds.has(key) && builds.get(key) !== serialized) throw new Error(`Inconsistent geo build observations: ${key}`);
    builds.set(key, serialized);
    cases.push(item);
  }
  if (seenInputs.size !== inputs.size || identities.size || cases.length !== header.expectedCases || footer.completed !== header.expectedCases || footer.expectedCases !== header.expectedCases || footer.failures !== failures || !positive(footer.elapsedSeconds)) throw new Error("Incomplete declared geo matrix or inconsistent footer");
  return { header, datasets, cases, footer };
}

export function summarizeGeoCases(cases: GeoCase[]) {
  const common = cases.filter(item => item.rows.every(row => row.status === "ok" && positive(row.medianMs)));
  const ratios = common.map(item => item.rows[1].medianMs! / item.rows[0].medianMs!);
  return { selected: cases.length, eligible: common.length, moonRelativeToGeo: geometricMean(ratios),
    moonFaster: ratios.filter(value => value > 1.05).length,
    close: ratios.filter(value => value >= 1 / 1.05 && value <= 1.05).length,
    moonSlower: ratios.filter(value => value < 1 / 1.05).length,
    providers: GEO_PROVIDERS.map((name, index) => ({ name, errors: cases.filter(item => item.rows[index].status === "error").length,
      mismatches: cases.filter(item => item.rows[index].status === "mismatch").length,
      unsupported: cases.filter(item => item.rows[index].status === "unsupported").length })) };
}

export function summarizeGeoBuilds(cases: GeoCase[]) {
  const builds = new Map<string, GeoCase>();
  for (const item of cases) builds.set(`${item.dataset}/${item.count}/${item.seed}`, item);
  const common = [...builds.values()].filter(item => item.rows.every(row => positive(row.buildMedianMs)));
  return { selected: builds.size, eligible: common.length, moonRelativeToGeo: geometricMean(common.map(item => item.rows[1].buildMedianMs! / item.rows[0].buildMedianMs!)) };
}
