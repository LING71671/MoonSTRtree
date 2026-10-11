import type { Query } from "../domain/types";
import { distanceSquaredXY, queryEnvelope, segmentIntersectsXY } from "./geometry";

export function scanQuery(coordinates: Float64Array, query: Query): number[] {
  const count = coordinates.length / 4;
  if (query.mode === "knn") return nearestScan(coordinates, query);
  if (query.mode === "circle" && query.radius < 0) return [];
  const [x1, y1, x2, y2] = queryEnvelope(query);
  const results: number[] = [];
  for (let id = 0; id < count; id++) {
    const i = id * 4;
    const minX = coordinates[i], minY = coordinates[i + 1], maxX = coordinates[i + 2], maxY = coordinates[i + 3];
    if (minX > x2 || minY > y2 || maxX < x1 || maxY < y1) continue;
    if (query.mode === "circle" && distanceSquaredXY(minX, minY, maxX, maxY, query.bounds[0], query.bounds[1]) > query.radius ** 2) continue;
    if (query.mode === "segment" && !segmentIntersectsXY(minX, minY, maxX, maxY, query.bounds)) continue;
    results.push(id);
  }
  return results;
}

function nearestScan(coordinates: Float64Array, query: Query): number[] {
  const count = coordinates.length / 4;
  const limit = Math.max(0, Math.min(count, Math.trunc(query.k)));
  if (limit === 0) return [];
  const ids: number[] = [], distances: number[] = [];
  for (let id = 0; id < count; id++) {
    const i = id * 4;
    const distance = distanceSquaredXY(coordinates[i], coordinates[i + 1], coordinates[i + 2], coordinates[i + 3], query.bounds[0], query.bounds[1]);
    if (ids.length < limit) {
      let position = ids.length;
      ids.push(id); distances.push(distance);
      while (position > 0) {
        const parent = (position - 1) >> 1;
        if (distances[parent] >= distance) break;
        ids[position] = ids[parent]; distances[position] = distances[parent];
        position = parent;
      }
      ids[position] = id; distances[position] = distance;
    } else if (distance < distances[0]) {
      let position = 0;
      for (;;) {
        const left = position * 2 + 1;
        if (left >= limit) break;
        const right = left + 1;
        const child = right < limit && distances[right] > distances[left] ? right : left;
        if (distances[child] <= distance) break;
        ids[position] = ids[child]; distances[position] = distances[child];
        position = child;
      }
      ids[position] = id; distances[position] = distance;
    }
  }
  return ids.map((id, i) => ({ id, distance: distances[i] })).sort((a, b) => a.distance - b.distance).map(item => item.id);
}
