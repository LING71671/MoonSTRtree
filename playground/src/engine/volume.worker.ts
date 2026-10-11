/// <reference lib="webworker" />
import * as moon from "../.generated/moon-engine.js";
import { generate, randomSource } from "../data/generate";
import type { VolumeDimension, VolumeRequest, VolumeResponse } from "./volume-protocol";

const scope = self as unknown as DedicatedWorkerGlobalScope;
let dimension: VolumeDimension = 3;
let coordinates = new Float64Array();
let tree3d: ReturnType<typeof moon.build_index_3d> | null = null;
let tree4d: ReturnType<typeof moon.build_index_4d> | null = null;
const send = (response: VolumeResponse, transfer: Transferable[] = []) => scope.postMessage(response, transfer);

scope.onmessage = ({ data }: MessageEvent<VolumeRequest>) => {
  try {
    if (data.type === "build") {
      dimension = data.dimension;
      const projection = generate({ distribution: "uniform", count: data.count, seed: data.seed, capacity: 16 });
      const random = randomSource(data.seed ^ 0x4d535452);
      const stride = dimension * 2;
      coordinates = new Float64Array(data.count * stride);
      for (let id = 0; id < data.count; id++) {
        const p = id * 4, offset = id * stride;
        const z = random() * 950, duration = 60 + random() * 100, time = random() * (1000 - duration);
        const endZ = Math.min(1000, z + 10 + random() * 45);
        coordinates.set(dimension === 3
          ? [projection[p], projection[p + 1], z, projection[p + 2], projection[p + 3], endZ]
          : [projection[p], projection[p + 1], z, time, projection[p + 2], projection[p + 3], endZ, time + duration], offset);
      }
      const display = coordinates.slice();
      const projectedBoxes: number[] = [];
      let stats: number[];
      if (dimension === 3) {
        tree3d = moon.build_index_3d(coordinates, 16); tree4d = null;
        stats = Array.from(moon.index_stats_3d(tree3d));
        const boxes = moon.index_boxes_3d(tree3d);
        for (let i = 0; i < boxes.length; i += 7) projectedBoxes.push(boxes[i], boxes[i + 1], boxes[i + 3], boxes[i + 4], boxes[i + 6]);
      } else {
        tree4d = moon.build_index_4d(coordinates, 16); tree3d = null;
        stats = Array.from(moon.index_stats_4d(tree4d));
        const boxes = moon.index_boxes_4d(tree4d);
        for (let i = 0; i < boxes.length; i += 9) projectedBoxes.push(boxes[i], boxes[i + 1], boxes[i + 4], boxes[i + 5], boxes[i + 8]);
      }
      send({ type: "built", coordinates: display, projection, stats, boxes: projectedBoxes }, [display.buffer, projection.buffer]);
      return;
    }
    const [x1, y1, x2, y2] = data.query.bounds;
    const [z1, z2] = data.query.height;
    const hits = dimension === 3
      ? moon.query_range_3d(tree3d!, x1, y1, z1, x2, y2, z2)
      : moon.query_time_slice(tree4d!, data.query.time, x1, y1, z1, x2, y2, z2);
    // Independent exhaustive 3D/4D predicate, outside any benchmark timing.
    const expected: number[] = [], stride = dimension * 2;
    for (let id = 0; id < coordinates.length / stride; id++) {
      const offset = id * stride;
      if (coordinates[offset] > Math.max(x1, x2) || coordinates[offset + dimension] < Math.min(x1, x2)
        || coordinates[offset + 1] > Math.max(y1, y2) || coordinates[offset + dimension + 1] < Math.min(y1, y2)
        || coordinates[offset + 2] > Math.max(z1, z2) || coordinates[offset + dimension + 2] < Math.min(z1, z2)) continue;
      if (dimension === 4 && (coordinates[offset + 3] > data.query.time || coordinates[offset + 7] < data.query.time)) continue;
      expected.push(id);
    }
    const actual = [...hits].sort((a, b) => a - b);
    const valid = actual.length === expected.length && actual.every((id, i) => id === expected[i]);
    send({ type: "queried", id: data.id, hits: Array.from(hits), valid, query: data.query });
  } catch (error) {
    send({ type: "error", message: error instanceof Error ? error.message : String(error) });
  }
};
