/// <reference lib="webworker" />
import { generate } from "../data/generate";
import metadata from "../.generated/metadata.json";
import {
  createProviders,
  initialMeasurements,
  matchesReference,
  type Adapter,
} from "./providers";
import type { Request, Response } from "./protocol";
import type { Query, Measurement } from "../domain/types";
import { referenceQuery } from "./reference";
import { calibrateIterations, sampleBatch, TARGET_BATCH_MS } from "./sampling";

const scope = self as unknown as DedicatedWorkerGlobalScope;
let coordinates: Float64Array = new Float64Array();
let providers: Adapter[] = [];
let audit: (query: Query) => number[] = () => [];
let operation = 0;
const send = (message: Response, transfer: Transferable[] = []) =>
  scope.postMessage(message, transfer);
const pause = () => new Promise<void>((resolve) => setTimeout(resolve, 0));
const median = (samples: number[]) =>
  [...samples].sort((a, b) => a - b)[Math.floor(samples.length / 2)];

function evaluate(query: Query) {
  const expected = referenceQuery(coordinates, query);
  const answers = providers.map((provider) => provider.run(query));
  const rows: Measurement[] = providers.map((provider, i) => ({
    name: provider.name,
    buildMs: provider.buildMs,
    samples: [],
    medianMs: null,
    hits: answers[i]?.length ?? null,
    supported: answers[i] !== null,
    valid:
      answers[i] === null
        ? null
        : matchesReference(answers[i]!, expected, query, coordinates),
    path: provider.path(query),
  }));
  return { rows, hits: answers[0]! };
}

scope.onmessage = async ({ data }: MessageEvent<Request>) => {
  const token = ++operation;
  if (data.type === "cancel") return;
  try {
    if (data.type === "build") {
      coordinates = generate(data.config);
      const indexes = createProviders(coordinates, data.config.capacity);
      providers = indexes.providers;
      audit = indexes.audit;
      const displayCoordinates = coordinates.slice();
      send(
        {
          type: "built",
          dataset: {
            coordinates: displayCoordinates,
            boxes: indexes.boxes,
            stats: indexes.stats,
            measurements: initialMeasurements(providers),
          },
        },
        [displayCoordinates.buffer],
      );
      return;
    }
    if (!providers.length) throw new Error("Build the index before querying.");
    const evaluated = evaluate(data.query);
    if (data.type === "query") {
      send({
        type: "queried",
        id: data.id,
        ...evaluated,
        audit: audit(data.query),
      });
      return;
    }
    const warmups = 16, batches = 9;
    const iterations: Partial<Record<Adapter["name"], number>> = {};
    const localProviders = providers;
    const rows = evaluated.rows;
    for (const provider of localProviders) {
      if (rows.find((row) => row.name === provider.name)?.supported) {
        for (let i = 0; i < warmups; i++) {
          provider.run(data.query);
          if (i % 4 === 3) {
            await pause();
            if (token !== operation) return;
          }
        }
        iterations[provider.name] = calibrateIterations(() => provider.run(data.query)!);
        await pause();
        if (token !== operation) return;
      }
    }
    for (let batch = 0; batch < batches; batch++) {
      for (let offset = 0; offset < localProviders.length; offset++) {
        const index = (batch + offset) % localProviders.length;
        if (!rows[index].supported) continue;
        const provider = localProviders[index];
        const sample = sampleBatch(() => provider.run(data.query)!, iterations[provider.name]!);
        rows[index].samples.push(sample.msPerQuery);
        rows[index].hits = sample.hits;
        // Yield outside timing, so a new query can cancel the old measurement.
        await pause();
        if (token !== operation) return;
      }
      send({
        type: "progress",
        id: data.id,
        completed: batch + 1,
        total: batches,
      });
      await pause();
      if (token !== operation) return;
    }
    for (const row of rows)
      if (row.samples.length) row.medianMs = median(row.samples);
    // Complete validation remains outside timing and is repeated after sampling.
    const checked = evaluate(data.query);
    for (const [index, row] of rows.entries()) {
      row.valid = checked.rows[index].valid;
      row.hits = checked.rows[index].hits;
      if (row.valid !== true) row.medianMs = null;
    }
    send({
      type: "measured",
      id: data.id,
      comparison: {
        rows,
        query: data.query,
        warmups,
        iterations,
        batches,
        measuredAt: new Date().toISOString(),
        metadata: {
          ...metadata,
          timer: "performance.now",
          unit: "milliseconds per query",
          buildScope: "host ingestion and index construction",
          order: "rotated each batch",
          sampling: "per-provider iterations calibrated before timing",
          targetBatchMs: TARGET_BATCH_MS,
          equality:
            data.query.mode === "knn"
              ? "complete sorted distance sequence; tied IDs may differ"
              : "complete sorted ID arrays",
        },
      },
    });
  } catch (error) {
    send({
      type: "error",
      id: data.type === "build" ? undefined : data.id,
      message: error instanceof Error ? error.message : String(error),
    });
  }
};
