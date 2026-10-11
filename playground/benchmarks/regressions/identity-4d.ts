import { readFileSync } from "node:fs";
import * as core from "../../src/.generated/moon-engine.js";

const count = 64, coordinates = new Float64Array(count * 8);
for (let id = 0; id < count; id++) coordinates.set([0, 0, 0, 0, 10, 10, 10, 10], id * 8);
const tree = core.build_index_4d(coordinates, 4);
const hits = core.query_range_4d(tree, 0, 0, 0, 0, 10, 10, 10, 10) as number[];
const uniqueIDs = new Set(hits).size;
const valid = hits.length === count && [...hits].sort((a, b) => a - b).every((id, index) => id === index);
console.log(JSON.stringify({ phase: process.argv[2] ?? "current", input: "64 distinct IDs with identical 4D bounds", capacity: 4,
  expected: count, hits: hits.length, uniqueIDs, valid, IDs: hits,
  metadata: JSON.parse(readFileSync(new URL("../../src/.generated/metadata.json", import.meta.url), "utf8")) }, null, 2));
if (!valid) process.exitCode = 1;
