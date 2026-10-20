import { createHash } from "node:crypto";
import type { Query } from "../../src/domain/types";
import { DISTRIBUTIONS } from "../../src/domain/types";
import { boundsAt, distanceSquared } from "../../src/engine/geometry";
import { makeQueries, type Workload } from "../matrix/queries";
import catalog from "../data/sources.json";
import { publicInput, syntheticInput, type Input } from "./datasets";

export const GEO_PROVIDERS = ["MoonSTRtree", "totto2727/geo"] as const;
export const GEO_PROFILES = {
  diagnostic: { counts: [1000], seeds: [42], warmups: 8, batches: 3, targetBatchMs: 1 },
  standard: { counts: [1000, 10000, 100000], seeds: [0, 42, 2026], warmups: 16, batches: 9, targetBatchMs: 5 },
} as const;
export type GeoProfile = keyof typeof GEO_PROFILES;
export const GEO_BOUNDARIES = ["identical-bounds", "nested-bounds"] as const;
export const GEO_SYNTHETIC = DISTRIBUTIONS.map(item => item.value);
export const GEO_VERSION = "0.1.3";

export function geoDescriptors(profile: GeoProfile, publicCounts: Record<string, number>) {
  const parameters = GEO_PROFILES[profile];
  const result: { dataset: string; count: number; seed: number; kind: string }[] = [];
  for (const dataset of [...GEO_SYNTHETIC, ...GEO_BOUNDARIES]) for (const count of parameters.counts) for (const seed of parameters.seeds)
    result.push({ dataset, count, seed, kind: GEO_BOUNDARIES.includes(dataset as typeof GEO_BOUNDARIES[number]) ? "boundary" : "synthetic" });
  for (const source of catalog.sources) {
    const count = publicCounts[source.id];
    if (!Number.isInteger(count) || count < 1) throw new Error(`Missing public count: ${source.id}`);
    for (const seed of parameters.seeds) result.push({ dataset: source.id, count, seed, kind: "public" });
  }
  result.push({ dataset: "empty", count: 0, seed: 0, kind: "boundary" }, { dataset: "singleton", count: 1, seed: 0, kind: "boundary" });
  return result;
}

export function geoInput(descriptor: ReturnType<typeof geoDescriptors>[number], cache: string): Input {
  const { dataset, count, seed, kind } = descriptor;
  if (kind === "public") return publicInput(dataset, seed, cache);
  if (kind === "synthetic") return syntheticInput(dataset as typeof GEO_SYNTHETIC[number], count, seed);
  const coordinates = new Float64Array(count * 4);
  for (let id = 0; id < count; id++) {
    const extent = dataset === "nested-bounds" ? 1 + (id + seed) % count : 400;
    coordinates.set([500 - extent, 500 - extent, 500 + extent, 500 + extent], id * 4);
  }
  return { id: dataset, kind: "synthetic", count, seed, order: "source", coordinates,
    provenance: { generator: "playground/benchmarks/runtime/geo-model.ts", selection: "all generated records", boundary: dataset, coordinates: "dimensionless planar units" } };
}

export function geoQueries(coordinates: Float64Array): Workload[] {
  const input = coordinates.length ? coordinates : new Float64Array([0, 0, 1, 1]);
  const queries = makeQueries(input);
  const [x1, y1, x2, y2] = input;
  queries.push(
    { id: "range/touch-first-lower", group: "range", query: { mode: "range", bounds: [x1, y1, x1, y1], radius: 0, k: 10 } },
    { id: "range/touch-first-upper", group: "range", query: { mode: "range", bounds: [x2, y2, x2, y2], radius: 0, k: 10 } },
  );
  return queries;
}

export function exactGeoAnswer(actual: unknown, expected: number[], input: Input, query: Query): actual is number[] {
  if (!Array.isArray(actual) || actual.length !== expected.length || new Set(actual).size !== actual.length || actual.some(id => !Number.isInteger(id) || id < 0 || id >= input.count)) return false;
  if (query.mode === "knn") {
    // Verify output order as well as the exact distance sequence. Tied IDs may
    // differ, but an unsorted nearest result is not accepted by this oracle.
    const actualDistances = actual.map(id => distanceSquared(boundsAt(input.coordinates, id), query.bounds[0], query.bounds[1]));
    const expectedDistances = expected.map(id => distanceSquared(boundsAt(input.coordinates, id), query.bounds[0], query.bounds[1]));
    return actualDistances.every((distance, index) => distance === expectedDistances[index]);
  }
  const sorted = [...actual].sort((a, b) => a - b);
  return sorted.every((id, index) => id === expected[index]);
}

export const coordinateHash = (coordinates: Float64Array) => createHash("sha256").update(new Uint8Array(coordinates.buffer, coordinates.byteOffset, coordinates.byteLength)).digest("hex");
