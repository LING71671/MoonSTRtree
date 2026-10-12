export const TARGET_BATCH_MS = 12;
export const MAX_ITERATIONS = 65536;

type Run = () => number[];

// Calibrate outside the measured batches. Long batches reduce the influence
// of the browser's rounded timer without adding clock reads to each query.
export function calibrateIterations(run: Run, now = () => performance.now(), targetBatchMs = TARGET_BATCH_MS) {
  if (!Number.isFinite(targetBatchMs) || targetBatchMs <= 0) throw new Error("Batch duration must be finite and positive");
  let count = 1;
  for (;;) {
    const sample = sampleBatch(run, count, now);
    if (sample.elapsedMs >= targetBatchMs || count === MAX_ITERATIONS) {
      return Math.max(1, Math.min(MAX_ITERATIONS, Math.ceil(
        count * targetBatchMs / Math.max(0.001, sample.elapsedMs),
      )));
    }
    count = Math.min(MAX_ITERATIONS, count * 2);
  }
}

export function sampleBatch(run: Run, iterations: number, now = () => performance.now()) {
  let hits = 0;
  let checksum = 0;
  const start = now();
  for (let i = 0; i < iterations; i++) {
    hits = run().length;
    checksum += hits;
  }
  const elapsedMs = now() - start;
  return { elapsedMs, msPerQuery: elapsedMs / iterations, hits, checksum };
}
