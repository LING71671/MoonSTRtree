import type {
  Comparison,
  Config,
  Dataset,
  Measurement,
  Query,
} from "../domain/types";
export type Request =
  | { type: "cancel"; id: number }
  | { type: "build"; config: Config }
  | { type: "query"; query: Query; id: number }
  | { type: "measure"; query: Query; id: number };
export type Response =
  | { type: "built"; dataset: Dataset }
  | {
      type: "queried";
      id: number;
      hits: number[];
      rows: Measurement[];
      audit: number[];
    }
  | { type: "progress"; id: number; completed: number; total: number }
  | { type: "measured"; id: number; comparison: Comparison }
  | { type: "error"; id?: number; message: string };
