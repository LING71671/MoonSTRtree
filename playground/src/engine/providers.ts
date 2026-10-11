import Flatbush from "flatbush";
import RBush from "rbush";
import rbushKnn from "rbush-knn";
import { scanQuery } from "./scan";
import * as moon from "../.generated/moon-engine.js";
import type { Bounds, Measurement, Provider, Query } from "../domain/types";
import {
  boundsAt,
  distanceSquared,
  distanceSquaredXY,
  queryEnvelope,
  segmentIntersectsXY,
} from "./geometry";

type Item = {
  minX: number;
  minY: number;
  maxX: number;
  maxY: number;
  id: number;
};
export type Adapter = {
  name: Provider;
  buildMs: number;
  run: (query: Query) => number[] | null;
  path: (query: Query) => string;
};

const timeBuild = <T>(build: () => T): [T, number] => {
  const start = performance.now();
  const result = build();
  return [result, performance.now() - start];
};

function createMoonProvider(
  coordinates: Float64Array,
  capacity: number,
  engine: typeof moon = moon,
) {
  const [tree, moonMs] = timeBuild(() =>
    engine.build_index(coordinates, capacity),
  );
  return {
    name: "MoonSTRtree" as const,
    buildMs: moonMs,
    path: () => "MoonBit core → JS",
    run: (query: Query) => {
      const [x1, y1, x2, y2] = query.bounds;
      if (query.mode === "point") return engine.query_point(tree, x1, y1);
      if (query.mode === "knn") return engine.query_knn(tree, x1, y1, query.k);
      if (query.mode === "circle") return engine.query_circle(tree, x1, y1, query.radius);
      if (query.mode === "segment") return engine.query_segment(tree, x1, y1, x2, y2);
      return engine.query_range(tree, x1, y1, x2, y2);
    },
    audit: (query: Query): number[] => query.mode === "range"
      ? Array.from(engine.query_bounds(tree, ...query.bounds)) : [],
    stats: () => Array.from(engine.index_stats(tree)) as number[],
    boxes: () => Array.from(engine.index_boxes(tree)) as number[],
  };
}

function createFlatProvider(coordinates: Float64Array, capacity: number): Adapter {
  const count = coordinates.length / 4;
  const [flat, flatMs] = timeBuild(() => {
    const index = new Flatbush(count, capacity);
    for (let i = 0; i < coordinates.length; i += 4)
      index.add(
        coordinates[i],
        coordinates[i + 1],
        coordinates[i + 2],
        coordinates[i + 3],
      );
    index.finish();
    return index;
  });
  return {
    name: "Flatbush",
    buildMs: flatMs,
    path: (query) => ["circle", "segment"].includes(query.mode)
      ? "Range + in-index exact filter" : "Packed Hilbert R-tree",
    run: (query) => {
      if (query.mode === "knn") return query.k <= 0 ? [] : flat.neighbors(query.bounds[0], query.bounds[1], query.k);
      if (query.mode === "circle") {
        if (query.radius < 0) return [];
        return flat.search(...queryEnvelope(query), (_id, minX, minY, maxX, maxY) =>
          distanceSquaredXY(minX, minY, maxX, maxY, query.bounds[0], query.bounds[1]) <= query.radius ** 2);
      }
      if (query.mode === "segment") return flat.search(...queryEnvelope(query), (_id, minX, minY, maxX, maxY) =>
        segmentIntersectsXY(minX, minY, maxX, maxY, query.bounds));
      return flat.search(...queryEnvelope(query));
    },
  };
}

function createRbushProvider(coordinates: Float64Array, capacity: number): Adapter {
  const count = coordinates.length / 4;
  const [rbush, rbushMs] = timeBuild(() => {
    const index = new RBush<Item>(capacity);
    index.load(
      Array.from({ length: count }, (_, id) => {
        const [minX, minY, maxX, maxY] = boundsAt(coordinates, id);
        return { minX, minY, maxX, maxY, id };
      }),
    );
    return index;
  });
  return {
      name: "RBush",
      buildMs: rbushMs,
      path: (query) =>
        query.mode === "knn"
          ? "RBush + rbush-knn"
          : ["circle", "segment"].includes(query.mode)
            ? "Range + exact filter"
            : "Bulk-loaded dynamic R-tree",
      run: (query) => {
        if (query.mode === "knn") return query.k <= 0 ? [] : rbushKnn(rbush, query.bounds[0], query.bounds[1], query.k).map(item => item.id);
        if (query.mode === "circle" && query.radius < 0) return [];
        const [minX, minY, maxX, maxY] = queryEnvelope(query);
        const candidates = rbush.search({ minX, minY, maxX, maxY });
        const results: number[] = [];
        for (const item of candidates) {
          if (query.mode === "circle" && distanceSquaredXY(item.minX, item.minY, item.maxX, item.maxY, query.bounds[0], query.bounds[1]) > query.radius ** 2) continue;
          if (query.mode === "segment" && !segmentIntersectsXY(item.minX, item.minY, item.maxX, item.maxY, query.bounds)) continue;
          results.push(item.id);
        }
        return results;
      },
  };
}

export const PROVIDER_NAMES = ["MoonSTRtree", "Flatbush", "RBush", "Linear scan"] as const;

// Independent factories let the benchmark rotate construction order and retain
// other providers when one implementation fails to build.
export function createProvider(name: Provider, coordinates: Float64Array, capacity: number, engine: typeof moon = moon): Adapter {
  if (name === "MoonSTRtree") return createMoonProvider(coordinates, capacity, engine);
  if (name === "Flatbush") return createFlatProvider(coordinates, capacity);
  if (name === "RBush") return createRbushProvider(coordinates, capacity);
  return { name, buildMs: 0, path: () => "Optimized linear scan", run: query => scanQuery(coordinates, query) };
}

export function createProviders(coordinates: Float64Array, capacity: number, engine: typeof moon = moon) {
  const primary = createMoonProvider(coordinates, capacity, engine);
  const providers: Adapter[] = [primary, ...PROVIDER_NAMES.slice(1).map(name => createProvider(name, coordinates, capacity, engine))];
  return {
    providers,
    audit: primary.audit,
    stats: primary.stats(),
    boxes: primary.boxes(),
  };
}

export function matchesReference(
  actual: number[],
  expected: number[],
  query: Query,
  coordinates: Float64Array,
) {
  if (
    actual.length !== expected.length ||
    new Set(actual).size !== actual.length ||
    actual.some((id) => id < 0 || id >= coordinates.length / 4)
  )
    return false;
  if (query.mode === "knn") {
    const distances = (ids: number[]) =>
      ids
        .map((id) =>
          distanceSquared(
            boundsAt(coordinates, id),
            query.bounds[0],
            query.bounds[1],
          ),
        )
        .sort((a, b) => a - b);
    const a = distances(actual),
      b = distances(expected);
    return a.every(
      (distance, i) =>
        Math.abs(distance - b[i]) <= 1e-10 * Math.max(1, Math.abs(b[i])),
    );
  }
  const a = [...actual].sort((a, b) => a - b),
    b = [...expected].sort((a, b) => a - b);
  return a.every((id, i) => id === b[i]);
}

export function initialMeasurements(providers: Adapter[]): Measurement[] {
  return providers.map((provider) => ({
    name: provider.name,
    buildMs: provider.buildMs,
    samples: [],
    medianMs: null,
    hits: null,
    valid: null,
    supported: true,
    path: provider.path({
      mode: "range",
      bounds: [0, 0, 0, 0],
      k: 10,
      radius: 100,
    }),
  }));
}
