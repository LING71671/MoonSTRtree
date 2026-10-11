import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { createHash } from "node:crypto";
import { generate, randomSource } from "../../src/data/generate";
import type { Distribution } from "../../src/domain/types";
import catalog from "../data/sources.json";

export type Input = {
  id: string; kind: "synthetic" | "public"; count: number; seed: number;
  order: "source" | "shuffled"; coordinates: Float64Array; provenance: Record<string, unknown>;
};

export function syntheticInput(distribution: Distribution, count: number, seed: number): Input {
  return { id: distribution, kind: "synthetic", count, seed, order: "source",
    coordinates: generate({ distribution, count, seed, capacity: 16 }),
    provenance: { generator: "playground/src/data/generate.ts", coordinates: "dimensionless planar units", selection: "all generated records" } };
}

export function publicInput(id: string, seed: number, cache: string): Input {
  const source = catalog.sources.find(item => item.id === id);
  if (!source) throw new Error(`Unknown public source: ${id}`);
  const metadata = JSON.parse(readFileSync(resolve(cache, `${id}.json`), "utf8"));
  const bytes = readFileSync(resolve(cache, `${id}.f64`));
  const digest = createHash("sha256").update(bytes).digest("hex");
  if (digest !== metadata.coordinatesSha256 || metadata.rawSha256 !== source.sha256 || bytes.length !== metadata.records * 32) throw new Error(`${id}: pinned dataset integrity check failed`);
  const coordinates = new Float64Array(bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength));
  // Shuffle record order, never sample or delete rows. Seed zero preserves source order.
  if (seed !== 0) {
    const random = randomSource(seed);
    for (let i = coordinates.length / 4 - 1; i > 0; i--) {
      const other = Math.floor(random() * (i + 1));
      for (let axis = 0; axis < 4; axis++) {
        const value = coordinates[i * 4 + axis];
        coordinates[i * 4 + axis] = coordinates[other * 4 + axis];
        coordinates[other * 4 + axis] = value;
      }
    }
  }
  return { id, kind: "public", count: metadata.records, seed, order: seed === 0 ? "source" : "shuffled", coordinates, provenance: metadata };
}

export const PUBLIC_DATASETS = catalog.sources.map(source => source.id);
