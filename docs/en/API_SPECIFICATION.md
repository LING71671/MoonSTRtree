# MoonSTRtree API Specification

[English](./API_SPECIFICATION.md) | [中文说明](../zh/API_SPECIFICATION.md)

This document defines the public API contracts, input/output types, invariants, and error behaviors for MoonSTRtree.

---

## 1. Top-Level Public APIs

All public APIs are exposed at the package root level under module `LING71671/moon_strtree`.

### 1.1 `Rect::new`

Constructs an axis-aligned bounding box (AABB) in continuous 2D space.

```moonbit
pub fn Rect::new(min_x : Double, min_y : Double, max_x : Double, max_y : Double) -> Rect
```

- **Parameters**:
  - `min_x : Double` — Lower bound along the X axis.
  - `min_y : Double` — Lower bound along the Y axis.
  - `max_x : Double` — Upper bound along the X axis.
  - `max_y : Double` — Upper bound along the Y axis.
- **Invariants**:
  - Automatically normalizes coordinates: if `min_x > max_x`, swaps values.
  - If `min_y > max_y`, swaps values.
  - Supports negative coordinates and zero-area degenerate boundaries.

---

### 1.2 `Rect::from_point`

Constructs a degenerate zero-area bounding box centered at `(x, y)`.

```moonbit
pub fn Rect::from_point(x : Double, y : Double) -> Rect
```

- **Parameters**: `x : Double`, `y : Double` — Point coordinates.
- **Returns**: `Rect` with `min_x == max_x == x` and `min_y == max_y == y`.

---

### 1.3 `StrTree::build`

Bulk-loads a packed R-tree using the Sort-Tile-Recursive (STR) algorithm.

```moonbit
pub fn StrTree::build(items : Array[(Rect, Int)], node_capacity~ : Int = 16) -> StrTree
```

- **Parameters**:
  - `items : Array[(Rect, Int)]` — Array of bounding box and integer object ID pairs.
  - `node_capacity : Int` — Maximum children per node (default: 16, must be $\ge 2$).
- **Invariants**:
  - Deterministic and pure construction.
  - Handles empty input arrays gracefully, producing an empty tree without panicking.
  - Flattens all tree levels into contiguous internal arrays.

---

### 1.4 `tree.query`

Executes an axis-aligned range intersection query against the packed spatial index.

```moonbit
pub fn query(self : StrTree, search_window : Rect) -> Array[Int]
```

- **Parameters**: `search_window : Rect` — The query bounding box.
- **Returns**: `Array[Int]` — Array of object IDs whose bounding boxes intersect `search_window`.
- **Complexity**: $O(\log_M N)$ average time, bounded by $O(N)$ in degenerate spatial overlap.

---

### 1.5 `tree.query_point`

Evaluates point containment against the packed spatial index.

```moonbit
pub fn query_point(self : StrTree, x : Double, y : Double) -> Array[Int]
```

- **Parameters**: `x : Double`, `y : Double` — Point coordinates.
- **Returns**: `Array[Int]` — Array of object IDs whose bounding boxes contain `(x, y)`.

---

### 1.6 `tree.query_knn`

Performs branch-and-bound K-Nearest Neighbor (k-NN) spatial search.

```moonbit
pub fn query_knn(self : StrTree, x : Double, y : Double, k : Int) -> Array[Int]
```

- **Parameters**:
  - `x : Double`, `y : Double` — Target query point coordinates.
  - `k : Int` — Maximum number of nearest neighbors to retrieve (returns empty array if $k \le 0$).
- **Returns**: `Array[Int]` — Object IDs sorted in ascending Euclidean distance to `(x, y)`.
- **Pruning**: Employs bounding box MinDist lower-bounding and a flat binary min-heap for optimal branch pruning.

---

### 1.7 `tree.query_segment`

Performs 2D line segment / ray-casting intersection traversal.

```moonbit
pub fn query_segment(self : StrTree, x1 : Double, y1 : Double, x2 : Double, y2 : Double) -> Array[Int]
```

- **Parameters**: `(x1, y1)` to `(x2, y2)` — Endpoints of the test line segment.
- **Returns**: `Array[Int]` — Object IDs of all items whose bounding boxes intersect the segment.
- **Mathematics**: Uses Liang-Barsky parametric clipping algorithm for exact intersection tests.

---

### 1.8 `tree.spatial_join`

Executes dual-tree hierarchical spatial join between two StrTree indexes.

```moonbit
pub fn spatial_join(self : StrTree, other : StrTree) -> Array[(Int, Int)]
```

- **Parameters**: `other : StrTree` — Second STR spatial index tree.
- **Returns**: `Array[(Int, Int)]` — All pairs `(id_a, id_b)` whose bounding boxes overlap.
- **Pruning**: Synchronous depth-first traversal of both hierarchies, pruning disjoint subtrees and avoiding $O(N_A \times N_B)$ cross product costs.

---

### 1.9 `tree.to_flat_buffers` & `StrTree::from_flat_buffers`

Contiguous raw array buffer serialization and zero-copy reconstruction.

```moonbit
pub fn to_flat_buffers(self : StrTree) -> FlatBuffers
pub fn StrTree::from_flat_buffers(buffers : FlatBuffers) -> StrTree
```

- **Features**: Fast snapshotting and deserialization across Wasm memory boundaries or disk persistence.

---

### 1.10 `tree.stats`

Calculates and returns tree structural diagnostics.

```moonbit
pub fn stats(self : StrTree) -> TreeStats
```

- **Returns**: `TreeStats` — Metrics on tree height, total node count, item count, fill factor, edge count, and memory footprint.

---

## 2. Type Definitions

### 2.1 `Rect`

```moonbit
pub struct Rect {
  min_x : Double
  min_y : Double
  max_x : Double
  max_y : Double
} derive(Eq, Debug, Default)
```

#### Member Methods
- `intersects(self : Rect, other : Rect) -> Bool` — Returns `true` if this box intersects or touches `other`.
- `contains_point(self : Rect, x : Double, y : Double) -> Bool` — Inclusive boundary containment test.
- `contains_rect(self : Rect, other : Rect) -> Bool` — Total rectangle containment test.
- `intersects_segment(self : Rect, x1 : Double, y1 : Double, x2 : Double, y2 : Double) -> Bool` — Segment intersection test.
- `distance_to_point(self : Rect, x : Double, y : Double) -> Double` — Euclidean distance from box to point.
- `distance_squared_to_point(self : Rect, x : Double, y : Double) -> Double` — Squared Euclidean distance.
- `union(self : Rect, other : Rect) -> Rect` — Computes the Minimum Bounding Rectangle of both boxes.
- `center_x(self : Rect) -> Double` — Center X coordinate.
- `center_y(self : Rect) -> Double` — Center Y coordinate.
- `width(self : Rect) -> Double` — Width.
- `height(self : Rect) -> Double` — Height.
- `area(self : Rect) -> Double` — Area.

---

### 2.2 `TreeStats`

```moonbit
pub struct TreeStats {
  num_items : Int
  num_nodes : Int
  height : Int
  node_capacity : Int
  fill_factor : Double
  leaf_nodes : Int
  branch_nodes : Int
  total_edges : Int
  estimated_memory_bytes : Int
} derive(Eq, Debug, Default)
```

---

### 2.3 `FlatBuffers`

```moonbit
pub struct FlatBuffers {
  // Raw contiguous flat array slices
} derive(Eq, Debug, Default)
```

---

## 3. Synthetic Spatial Generators

The root package provides 5 standardized synthetic data distribution generators for benchmarking and fuzzing:

1. `generate_uniform(rng : Rng, count : Int, ...) -> Array[(Rect, Int)]` — Uniform random distribution.
2. `generate_clustered(rng : Rng, count : Int, ...) -> Array[(Rect, Int)]` — Multi-cluster Gaussian distribution.
3. `generate_diagonal(rng : Rng, count : Int, ...) -> Array[(Rect, Int)]` — Degenerate diagonal collinear distribution.
4. `generate_concentric(count : Int, ...) -> Array[(Rect, Int)]` — Nested concentric rectangle distribution.
5. `generate_grid(rows : Int, cols : Int, ...) -> Array[(Rect, Int)]` — Regular GIS tile grid distribution.

