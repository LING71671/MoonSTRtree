export type Distribution =
  "uniform" | "clustered" | "overlap" | "slender" | "grid"
  | "diagonal" | "points" | "duplicates" | "outliers" | "mixed";
export type Mode = "range" | "point" | "knn" | "circle" | "segment";
export type Bounds = [number, number, number, number];
export type Config = {
  count: number;
  capacity: number;
  seed: number;
  distribution: Distribution;
};
export type Query = { mode: Mode; bounds: Bounds; k: number; radius: number };
export type Provider = "MoonSTRtree" | "Flatbush" | "RBush" | "Linear scan";
export type Measurement = {
  name: Provider;
  buildMs: number;
  samples: number[];
  medianMs: number | null;
  hits: number | null;
  valid: boolean | null;
  supported: boolean;
  path: string;
};
export type Dataset = {
  coordinates: Float64Array;
  boxes: number[];
  stats: number[];
  measurements: Measurement[];
};
export type Comparison = {
  rows: Measurement[];
  query: Query;
  iterations: Partial<Record<Provider, number>>;
  batches: number;
  warmups: number;
  measuredAt: string;
  metadata: Record<string, unknown>;
};
export const DEFAULT_QUERY: Query = {
  mode: "range",
  bounds: [380, 310, 570, 490],
  k: 10,
  radius: 100,
};
export const DEFAULT_CONFIG: Config = {
  count: 10000,
  capacity: 16,
  seed: 42,
  distribution: "clustered",
};
export const DISTRIBUTIONS: {
  value: Distribution;
  label: string;
  note: string;
}[] = [
  { value: "diagonal", label: "Diagonal corridor", note: "Bounds follow a narrow diagonal corridor." },
  { value: "points", label: "Point objects", note: "Zero-area bounds use the same index interface." },
  { value: "duplicates", label: "Repeated bounds", note: "Distinct object IDs share repeated geometry." },
  { value: "outliers", label: "Distant outliers", note: "A dense group and a small distant population stretch the root. The canvas shows the 0–1,000 window." },
  { value: "mixed", label: "Mixed object sizes", note: "Mostly small bounds with occasional large enclosing objects." },
  {
    value: "uniform",
    label: "Uniform",
    note: "Objects spread across the whole field.",
  },
  {
    value: "clustered",
    label: "Clustered",
    note: "Eight hotspots with space between them.",
  },
  {
    value: "overlap",
    label: "Heavy overlap",
    note: "Most objects share a center. Pruning gets harder.",
  },
  {
    value: "slender",
    label: "Long rectangles",
    note: "Thin bounds span much of the field.",
  },
  {
    value: "grid",
    label: "Regular grid",
    note: "An evenly spaced cartographic pattern.",
  },
];
