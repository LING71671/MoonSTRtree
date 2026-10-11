import type { Bounds, Query } from "../domain/types";

export function intersects(a: Bounds, b: Bounds) {
  return a[0] <= b[2] && a[2] >= b[0] && a[1] <= b[3] && a[3] >= b[1];
}
export function distanceSquared(rect: Bounds, x: number, y: number) {
  return distanceSquaredXY(rect[0], rect[1], rect[2], rect[3], x, y);
}
export function distanceSquaredXY(minX: number, minY: number, maxX: number, maxY: number, x: number, y: number) {
  const dx = Math.max(minX - x, 0, x - maxX);
  const dy = Math.max(minY - y, 0, y - maxY);
  return dx * dx + dy * dy;
}
export function segmentIntersectsXY(minX: number, minY: number, maxX: number, maxY: number, line: Bounds) {
  let enter = 0, exit = 1;
  const dx = line[2] - line[0], dy = line[3] - line[1];
  if (dx === 0) {
    if (line[0] < minX || line[0] > maxX) return false;
  } else {
    const a = (minX - line[0]) / dx, b = (maxX - line[0]) / dx;
    enter = Math.max(enter, Math.min(a, b));
    exit = Math.min(exit, Math.max(a, b));
    if (enter > exit) return false;
  }
  if (dy === 0) return line[1] >= minY && line[1] <= maxY;
  const a = (minY - line[1]) / dy, b = (maxY - line[1]) / dy;
  enter = Math.max(enter, Math.min(a, b));
  exit = Math.min(exit, Math.max(a, b));
  return enter <= exit;
}
export function queryEnvelope(query: Query): Bounds {
  const [x1, y1, x2, y2] = query.bounds;
  if (query.mode === "point") return [x1, y1, x1, y1];
  if (query.mode === "circle") return [x1 - query.radius, y1 - query.radius, x1 + query.radius, y1 + query.radius];
  return [Math.min(x1, x2), Math.min(y1, y2), Math.max(x1, x2), Math.max(y1, y2)];
}
export function segmentIntersects(rect: Bounds, line: Bounds) {
  let enter = 0,
    exit = 1;
  for (let axis = 0; axis < 2; axis++) {
    const delta = line[axis + 2] - line[axis];
    if (delta === 0) {
      if (line[axis] < rect[axis] || line[axis] > rect[axis + 2]) return false;
    } else {
      const a = (rect[axis] - line[axis]) / delta;
      const b = (rect[axis + 2] - line[axis]) / delta;
      enter = Math.max(enter, Math.min(a, b));
      exit = Math.min(exit, Math.max(a, b));
      if (enter > exit) return false;
    }
  }
  return true;
}
export function boundsAt(coordinates: Float64Array, id: number): Bounds {
  const i = id * 4;
  return [
    coordinates[i],
    coordinates[i + 1],
    coordinates[i + 2],
    coordinates[i + 3],
  ];
}
