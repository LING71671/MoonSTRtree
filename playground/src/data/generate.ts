import type { Config } from "../domain/types";

export function randomSource(seed: number) {
  let state = seed >>> 0;
  return () => {
    state = (state + 0x6d2b79f5) >>> 0;
    let x = Math.imul(state ^ (state >>> 15), state | 1);
    x ^= x + Math.imul(x ^ (x >>> 7), x | 61);
    return ((x ^ (x >>> 14)) >>> 0) / 4294967296;
  };
}

export function generate(config: Config): Float64Array {
  const random = randomSource(config.seed);
  const coordinates = new Float64Array(config.count * 4);
  const centers = Array.from({ length: 8 }, () => [
    140 + random() * 720,
    140 + random() * 720,
  ]);
  const columns = Math.ceil(Math.sqrt(config.count));
  const clamp = (value: number) => Math.max(2, Math.min(978, value));
  for (let id = 0; id < config.count; id++) {
    let x = random() * 980,
      y = random() * 980;
    let width = 2 + random() * 12,
      height = 2 + random() * 12;
    if (config.distribution === "clustered") {
      const center = centers[id % centers.length];
      x = clamp(center[0] + (random() + random() + random() - 1.5) * 125);
      y = clamp(center[1] + (random() + random() + random() - 1.5) * 125);
    } else if (config.distribution === "overlap") {
      width = height = 120 + random() * 840;
      x = 500 - width / 2;
      y = 500 - height / 2;
    } else if (config.distribution === "slender") {
      width = 350 + random() * 600;
      height = 1 + random() * 3;
      x = random() * (1000 - width);
    } else if (config.distribution === "grid") {
      const step = 990 / columns;
      x = 5 + (id % columns) * step;
      y = 5 + Math.floor(id / columns) * step;
      width = height = step * 0.54;
    } else if (config.distribution === "diagonal") {
      x = random() * 970;
      y = clamp(x + (random() - 0.5) * 16);
      width = height = 1 + random() * 6;
    } else if (config.distribution === "points") {
      width = height = 0;
    } else if (config.distribution === "duplicates") {
      const center = centers[id % centers.length];
      x = center[0]; y = center[1]; width = height = 8;
    } else if (config.distribution === "outliers") {
      if (id % 20 === 0) {
        x = 100000 + random() * 900000;
        y = 100000 + random() * 900000;
      } else {
        x = 480 + random() * 40; y = 480 + random() * 40;
      }
    } else if (config.distribution === "mixed" && id % 100 === 0) {
      width = height = 350 + random() * 600;
      x = random() * (1000 - width); y = random() * (1000 - height);
    }
    const limit = config.distribution === "outliers" ? 2000000 : 1000;
    coordinates.set(
      [x, y, Math.min(limit, x + width), Math.min(limit, y + height)],
      id * 4,
    );
  }
  return coordinates;
}
