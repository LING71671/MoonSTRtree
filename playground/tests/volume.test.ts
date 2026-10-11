import { expect, test } from "bun:test";
import * as moon from "../src/.generated/moon-engine.js";

const sorted = (ids: number[]) => [...ids].sort((a, b) => a - b);

test("real 3D core distinguishes identical projections at different heights", () => {
  const tree = moon.build_index_3d(new Float64Array([
    0, 0, 0, 10, 10, 10,
    0, 0, 100, 10, 10, 110,
    20, 0, 50, 30, 10, 60,
  ]), 2);
  expect(moon.query_range_3d(tree, 0, 0, 0, 10, 10, 20)).toEqual([0]);
  expect(moon.query_range_3d(tree, 0, 0, 90, 10, 10, 120)).toEqual([1]);
  expect(moon.query_point_3d(tree, 5, 5, 5)).toEqual([0]);
  expect(moon.query_knn_3d(tree, 5, 5, 98, 1)).toEqual([1]);
  expect(moon.query_sphere(tree, 5, 5, 5, 1)).toEqual([0]);
  expect(sorted(moon.query_segment_3d(tree, 5, 5, 5, 5, 5, 105))).toEqual([0, 1]);
  expect(moon.index_stats_3d(tree)[0]).toBe(3);
  expect(moon.index_boxes_3d(tree).length % 7).toBe(0);
});

test("real 4D core distinguishes shared volumes by their active time interval", () => {
  const tree = moon.build_index_4d(new Float64Array([
    0, 0, 0, 0, 10, 10, 10, 10,
    0, 0, 0, 20, 10, 10, 10, 30,
    0, 0, 100, 0, 10, 10, 110, 30,
  ]), 2);
  expect(moon.query_time_slice(tree, 5, 0, 0, 0, 10, 10, 10)).toEqual([0]);
  expect(moon.query_time_slice(tree, 25, 0, 0, 0, 10, 10, 10)).toEqual([1]);
  expect(moon.query_time_slice(tree, 10, 0, 0, 0, 10, 10, 10)).toEqual([0]);
  expect(moon.query_time_slice(tree, -1, 0, 0, 0, 10, 10, 10)).toEqual([]);
  expect(moon.query_point_4d(tree, 5, 5, 5, 25)).toEqual([1]);
  expect(sorted(moon.query_range_4d(tree, 0, 0, 0, 0, 10, 10, 10, 30))).toEqual([0, 1]);
  expect(moon.query_range_4d(tree, 0, 0, 90, 5, 10, 10, 120, 5)).toEqual([2]);
  expect(moon.index_stats_4d(tree)[0]).toBe(3);
  expect(moon.index_boxes_4d(tree).length % 9).toBe(0);
});

test("volume host boundaries reject partial coordinate records", () => {
  expect(() => moon.build_index_3d([0, 1, 2], 16)).toThrow();
  expect(() => moon.build_index_4d([0, 1, 2, 3], 16)).toThrow();
});

test("4D coincident bounds retain all distinct IDs through multiple branch levels", () => {
  const count = 64, coordinates = new Float64Array(count * 8);
  for (let id = 0; id < count; id++) coordinates.set([0, 0, 0, 0, 10, 10, 10, 10], id * 8);
  const tree = moon.build_index_4d(coordinates, 4);
  const expected = Array.from({ length: count }, (_, id) => id);
  expect(sorted(moon.query_range_4d(tree, 0, 0, 0, 0, 10, 10, 10, 10))).toEqual(expected);
  expect(sorted(moon.query_time_slice(tree, 5, 0, 0, 0, 10, 10, 10))).toEqual(expected);
});
