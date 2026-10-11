import { expect, test } from "bun:test";
import { measureInput, BUILD_SAMPLES } from "../benchmarks/runtime/runner";
import { referenceQuery } from "../src/engine/reference";
import { PROVIDER_NAMES, type Adapter } from "../src/engine/providers";
import type { Provider } from "../src/domain/types";
import type { Input } from "../benchmarks/runtime/datasets";
import { makeQueries, QUERY_VARIANT_COUNT } from "../benchmarks/matrix/queries";

const input: Input = { id: "fixture", kind: "synthetic", count: 1, seed: 0, order: "source", coordinates: new Float64Array([0, 0, 1, 1]), provenance: {} };
const parameters = { batches: 1, targetBatchMs: 1, warmups: 0 };
function fixture(override?: (name: Provider, adapter: Adapter) => Adapter) {
  let clock = 0;
  const order: Provider[] = [];
  const factory = (name: Provider): Adapter => {
    order.push(name);
    const adapter: Adapter = { name, buildMs: name === "Linear scan" ? 0 : 2, path: () => "test fixture",
      run: query => { clock++; return referenceQuery(input.coordinates, query); } };
    return override ? override(name, adapter) : adapter;
  };
  return { order, factory, now: () => clock };
}

test("benchmark rotates nine builds and preserves the complete declared query matrix", () => {
  const deps = fixture();
  const results = [...measureInput(input, 16, parameters, undefined, deps)];
  expect(results.length).toBe(QUERY_VARIANT_COUNT);
  expect(new Set(makeQueries(input.coordinates).map(query => query.id)).size).toBe(QUERY_VARIANT_COUNT);
  const buildOrder = deps.order.slice(PROVIDER_NAMES.length).filter(name => name !== "Linear scan");
  expect(buildOrder.slice(0, 9)).toEqual(["MoonSTRtree", "Flatbush", "RBush", "Flatbush", "RBush", "MoonSTRtree", "RBush", "MoonSTRtree", "Flatbush"]);
  expect(results.every(result => result.rows.every(row => row.status === "ok" && row.buildSamples.length === BUILD_SAMPLES && row.samples.length === 1 && row.medianMs === 1))).toBe(true);
});

test("a build exception remains visible in every case without blocking competitors", () => {
  const deps = fixture((name, adapter) => { if (name === "MoonSTRtree") throw new Error("build fixture failed"); return adapter; });
  const results = [...measureInput(input, 16, parameters, undefined, deps)];
  expect(results.length).toBe(QUERY_VARIANT_COUNT);
  for (const result of results) {
    expect(result.rows[0].error).toEqual({ phase: "build", message: "build fixture failed" });
    expect(result.rows[0].medianMs).toBeNull();
    expect(result.rows.slice(1).every(row => row.valid)).toBe(true);
  }
});

test("query exceptions and unsupported paths remain distinct", () => {
  const deps = fixture((name, adapter) => name === "MoonSTRtree" ? { ...adapter, run: () => { throw new Error("query fixture failed"); } } : name === "RBush" ? { ...adapter, run: () => null } : adapter);
  const first = measureInput(input, 16, parameters, undefined, deps).next().value!;
  expect(first.rows[0].error?.phase).toBe("validation");
  expect(first.rows[2].status).toBe("unsupported");
  expect(first.rows[2].supported).toBe(false);
  expect(first.rows[1].valid).toBe(true);
});

test("a changed answer after timing invalidates the score and retains raw samples", () => {
  let calls = 0;
  const deps = fixture((name, adapter) => name !== "MoonSTRtree" ? adapter : { ...adapter, run: query => {
    const result = adapter.run(query); calls++; return calls === 4 ? [] : result;
  } });
  const first = measureInput(input, 16, parameters, undefined, deps).next().value!;
  expect(first.expectedHits).toBe(1);
  expect(first.rows[0].status).toBe("mismatch");
  expect(first.rows[0].samples).toHaveLength(1);
  expect(first.rows[0].medianMs).toBeNull();
  expect(first.rows[1].valid).toBe(true);
});
