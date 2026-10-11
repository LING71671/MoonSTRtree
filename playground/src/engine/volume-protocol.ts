import type { Bounds, Query } from "../domain/types";
export type VolumeDimension = 3 | 4;
export type VolumeQuery = { bounds: Bounds; height: [number, number]; time: number };
export type VolumeRequest =
  | { type: "build"; dimension: VolumeDimension; count: number; seed: number }
  | { type: "query"; id: number; query: VolumeQuery };
export type VolumeResponse =
  | { type: "built"; coordinates: Float64Array; projection: Float64Array; stats: number[]; boxes: number[] }
  | { type: "queried"; id: number; hits: number[]; valid: boolean; query: VolumeQuery }
  | { type: "error"; message: string };
export const VOLUME_QUERY: VolumeQuery = { bounds: [250, 250, 750, 750], height: [350, 650], time: 500 };
export const projectionQuery = (query: VolumeQuery): Query => ({ mode: "range", bounds: query.bounds, k: 10, radius: 100 });
