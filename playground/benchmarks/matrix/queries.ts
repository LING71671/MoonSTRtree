import type { Bounds, Query } from "../../src/domain/types";

export type Workload = { id: string; query: Query; group: Query["mode"] };

export function makeQueries(coordinates: Float64Array): Workload[] {
  let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
  for (let i = 0; i < coordinates.length; i += 4) {
    minX = Math.min(minX, coordinates[i]); minY = Math.min(minY, coordinates[i + 1]);
    maxX = Math.max(maxX, coordinates[i + 2]); maxY = Math.max(maxY, coordinates[i + 3]);
  }
  const width = Math.max(1e-6, maxX - minX), height = Math.max(1e-6, maxY - minY);
  const span = Math.max(width, height);
  const anchors: [number, number][] = [[minX + width / 2, minY + height / 2]];
  const count = coordinates.length / 4;
  for (const fraction of [0.25, 0.75]) {
    const i = Math.min(count - 1, Math.floor(count * fraction)) * 4;
    anchors.push([(coordinates[i] + coordinates[i + 2]) / 2, (coordinates[i + 1] + coordinates[i + 3]) / 2]);
  }
  const workloads: Workload[] = [];
  const add = (id: string, mode: Query["mode"], bounds: Bounds, radius = span * 0.1, k = 10) =>
    workloads.push({ id, group: mode, query: { mode, bounds, radius, k } });
  for (const [index, [x, y]] of anchors.entries()) {
    for (const fraction of [0.02, 0.2]) {
      add(`range/anchor-${index}/scale-${fraction}`, "range", [x - width * fraction / 2, y - height * fraction / 2, x + width * fraction / 2, y + height * fraction / 2]);
    }
    add(`point/anchor-${index}`, "point", [x, y, x, y]);
    for (const fraction of [0.002, 0.02, 0.15]) add(`circle/anchor-${index}/scale-${fraction}`, "circle", [x, y, x, y], span * fraction);
    for (const k of [1, 10, 100]) add(`knn/anchor-${index}/k-${k}`, "knn", [x, y, x, y], 0, k);
  }
  add("range/broad", "range", [minX + width * 0.1, minY + height * 0.1, maxX - width * 0.1, maxY - height * 0.1]);
  add("range/full", "range", [minX - span * 0.01, minY - span * 0.01, maxX + span * 0.01, maxY + span * 0.01]);
  add("range/outside", "range", [maxX + span, maxY + span, maxX + span * 2, maxY + span * 2]);
  add("range/reversed", "range", [maxX - width * 0.1, maxY - height * 0.1, minX + width * 0.1, minY + height * 0.1]);
  add("range/degenerate", "range", [anchors[0][0], anchors[0][1], anchors[0][0], anchors[0][1]]);
  add("point/outside", "point", [maxX + span, maxY + span, maxX + span, maxY + span]);
  add("segment/diagonal-up", "segment", [minX, minY, maxX, maxY]);
  add("segment/diagonal-down", "segment", [minX, maxY, maxX, minY]);
  add("segment/horizontal", "segment", [minX, anchors[0][1], maxX, anchors[0][1]]);
  add("segment/vertical", "segment", [anchors[0][0], minY, anchors[0][0], maxY]);
  add("segment/degenerate", "segment", [anchors[0][0], anchors[0][1], anchors[0][0], anchors[0][1]]);
  return workloads;
}
