import { DISTRIBUTIONS } from "../../src/domain/types";

export const PROFILES = {
  diagnostic: { counts: [10000], capacities: [16], seeds: [42], batches: 3, targetBatchMs: 1, warmups: 16 },
  standard: { counts: [1000, 10000, 100000], capacities: [4, 16, 64], seeds: [0, 42, 2026], batches: 9, targetBatchMs: 3, warmups: 64 },
  exhaustive: { counts: [100, 1000, 10000, 100000, 1000000], capacities: [4, 8, 16, 32, 64], seeds: [0, 7, 42, 71671, 2026], batches: 9, targetBatchMs: 3, warmups: 64 },
} as const;
export type ProfileName = keyof typeof PROFILES;
export const SYNTHETIC_DATASETS = DISTRIBUTIONS.map(item => item.value);
