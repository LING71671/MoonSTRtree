import type { Query } from "../domain/types";
import { boundsAt, distanceSquared, intersects, queryEnvelope, segmentIntersects } from "./geometry";

// Independent, exhaustive oracle. Keep the full sort for nearest results;
// the timed scan uses a separate bounded heap and never supplies its own oracle.
export function referenceQuery(coordinates: Float64Array, query: Query): number[] {
  const count = coordinates.length / 4;
  if (query.mode === "circle" && query.radius < 0) return [];
  if (query.mode === "knn") {
    return Array.from({ length: count }, (_, id) => ({
      id, distance: distanceSquared(boundsAt(coordinates, id), query.bounds[0], query.bounds[1]),
    })).sort((a, b) => a.distance - b.distance).slice(0, Math.max(0, query.k)).map(item => item.id);
  }
  const bounds = queryEnvelope(query);
  const results: number[] = [];
  for (let id = 0; id < count; id++) {
    const rect = boundsAt(coordinates, id);
    const match = query.mode === "circle"
      ? distanceSquared(rect, query.bounds[0], query.bounds[1]) <= query.radius ** 2
      : query.mode === "segment" ? segmentIntersects(rect, query.bounds) : intersects(rect, bounds);
    if (match) results.push(id);
  }
  return results;
}
