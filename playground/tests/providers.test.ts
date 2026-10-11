import { describe, expect, test } from "bun:test";
import { referenceQuery } from "../src/engine/reference";
import { generate } from "../src/data/generate";
import { createProviders, matchesReference } from "../src/engine/providers";
import {
  DEFAULT_CONFIG,
  DEFAULT_QUERY,
  DISTRIBUTIONS,
  type Query,
} from "../src/domain/types";

test("seeded input is reproducible and accepts seed zero", () => {
  const config = { ...DEFAULT_CONFIG, count: 1000, seed: 0 };
  expect(generate(config)).toEqual(generate(config));
  expect(generate(config)).not.toEqual(generate({ ...config, seed: 1 }));
});

for (const { value: distribution } of DISTRIBUTIONS)
  describe(distribution, () => {
    const coordinates = generate({
      ...DEFAULT_CONFIG,
      count: 1000,
      distribution,
    });
    const { providers } = createProviders(coordinates, 16);
    const queries: Query[] = [
      DEFAULT_QUERY,
      { ...DEFAULT_QUERY, bounds: [1000, 1000, 0, 0] },
      { ...DEFAULT_QUERY, bounds: [-100, -100, -10, -10] },
      { ...DEFAULT_QUERY, mode: "point", bounds: [500, 500, 500, 500] },
      {
        ...DEFAULT_QUERY,
        mode: "circle",
        bounds: [500, 500, 500, 500],
        radius: 200,
      },
      { ...DEFAULT_QUERY, mode: "segment", bounds: [900, 100, 100, 900] },
      { ...DEFAULT_QUERY, mode: "knn", bounds: [500, 500, 500, 500], k: 30 },
    ];
    for (const [index, query] of queries.entries())
      test(`${query.mode} query ${index} matches complete reference`, () => {
        const expected = referenceQuery(coordinates, query);
        for (const provider of providers) {
          const result = provider.run(query);
          expect(matchesReference(result!, expected, query, coordinates)).toBe(true);
        }
      });
  });

test("100,000 objects: small and broad range queries agree across real implementations", () => {
  const coordinates = generate({ ...DEFAULT_CONFIG, count: 100000 });
  const { providers, stats } = createProviders(coordinates, 16);
  expect(stats[0]).toBe(100000);
  for (const bounds of [
    [0, 0, 1000, 1000],
    [470, 420, 475, 427],
  ] as Query["bounds"][]) {
    const query = { ...DEFAULT_QUERY, bounds };
    const expected = referenceQuery(coordinates, query);
    for (const provider of providers)
      expect(
        matchesReference(provider.run(query)!, expected, query, coordinates),
      ).toBe(true);
  }
});

test("bounds audit retains only intersecting nodes and stops at rejected branches", () => {
  const coordinates = generate({ ...DEFAULT_CONFIG, count: 1000 });
  const { audit, boxes } = createProviders(coordinates, 16);
  const all = audit({ ...DEFAULT_QUERY, bounds: [0, 0, 1000, 1000] });
  expect(all.length / 6).toBe(boxes.length / 5);
  for (let i = 0; i < all.length; i += 6) expect(all[i + 5]).toBe(1);
  const outside = audit({ ...DEFAULT_QUERY, bounds: [-100, -100, -10, -10] });
  expect(outside.length).toBe(6);
  expect(outside[5]).toBe(0);
  expect(audit({ ...DEFAULT_QUERY, mode: "knn" })).toEqual([]);
  const partial = audit(DEFAULT_QUERY);
  const [x1, y1, x2, y2] = DEFAULT_QUERY.bounds;
  for (let i = 0; i < partial.length; i += 6)
    expect(partial[i + 5] === 1).toBe(
      partial[i] <= x2 &&
        partial[i + 2] >= x1 &&
        partial[i + 1] <= y2 &&
        partial[i + 3] >= y1,
    );
});
