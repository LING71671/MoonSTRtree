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
### 1.7 `tree.query_knn_with_distance`

Performs branch-and-bound k-Nearest Neighbor (k-NN) search, returning sorted item IDs paired with exact squared Euclidean distances.

```moonbit
pub fn query_knn_with_distance(self : StrTree, x : Double, y : Double, k : Int) -> Array[(Int, Double)]
```

- **Parameters**:
  - `x : Double`, `y : Double` — Target query point coordinates.
  - `k : Int` — Maximum number of nearest neighbors to retrieve (returns empty array if $k \le 0$).
- **Returns**: `Array[(Int, Double)]` — Pairs `(item_id, squared_distance)` sorted in ascending Euclidean distance to `(x, y)`.
- **Advantage**: Eliminates redundant distance re-computation by consumers, providing direct access to the branch-and-bound distance metric.

---

### 1.8 `tree.query_knn_with_predicate`

Performs branch-and-bound k-Nearest Neighbor (k-NN) search filtered by a user-supplied predicate callback.

```moonbit
pub fn query_knn_with_predicate(self : StrTree, x : Double, y : Double, k : Int, predicate : (Int) -> Bool) -> Array[Int]
```

- **Parameters**:
  - `x : Double`, `y : Double` — Target query point coordinates.
  - `k : Int` — Maximum number of nearest neighbors to retrieve.
  - `predicate : (Int) -> Bool` — Item ID filter predicate.
- **Returns**: `Array[Int]` — Up to $k$ matching item IDs sorted in ascending Euclidean distance to `(x, y)`.

---

### 1.9 `tree.query_knn_with_predicate_and_distance`

Performs branch-and-bound k-NN search with predicate filtering, returning item IDs with exact squared distances.

```moonbit
pub fn query_knn_with_predicate_and_distance(self : StrTree, x : Double, y : Double, k : Int, predicate : (Int) -> Bool) -> Array[(Int, Double)]
```

- **Parameters**: `x : Double`, `y : Double` — Target query point; `k : Int` — Neighbor count; `predicate : (Int) -> Bool` — Filter function.
- **Returns**: `Array[(Int, Double)]` — Up to $k$ pairs `(item_id, squared_distance)` satisfying the predicate, sorted by ascending distance.

---

### 1.10 `tree.query_segment`

Performs 2D line segment / ray-casting intersection traversal.

```moonbit
pub fn query_segment(self : StrTree, x1 : Double, y1 : Double, x2 : Double, y2 : Double) -> Array[Int]
```

- **Parameters**: `(x1, y1)` to `(x2, y2)` — Endpoints of the test line segment.
- **Returns**: `Array[Int]` — Object IDs of all items whose bounding boxes intersect the segment.
- **Mathematics**: Uses Liang-Barsky parametric clipping algorithm for exact intersection tests.

---

### 1.11 `tree.spatial_join`

Executes dual-tree hierarchical spatial join between two StrTree indexes.

```moonbit
pub fn spatial_join(self : StrTree, other : StrTree) -> Array[(Int, Int)]
```

- **Parameters**: `other : StrTree` — Second STR spatial index tree.
- **Returns**: `Array[(Int, Int)]` — All pairs `(id_a, id_b)` whose bounding boxes overlap.
- **Pruning**: Synchronous depth-first traversal of both hierarchies, pruning disjoint subtrees and avoiding $O(N_A \times N_B)$ cross product costs.

---

### 1.12 `tree.query_count`

Performs zero-allocation count of items intersecting a bounding box search window.

```moonbit
pub fn query_count(self : StrTree, search_window : Rect) -> Int
```

- **Parameters**: `search_window : Rect` — Search bounding box.
- **Returns**: `Int` — Total count of indexed items intersecting the window.
- **Advantage**: Zero heap allocations for ID arrays, yielding zero GC pause overhead.

---

### 1.13 `tree.query_point_count`

Performs zero-allocation count of items containing a target point.

```moonbit
pub fn query_point_count(self : StrTree, x : Double, y : Double) -> Int
```

- **Parameters**: `x : Double`, `y : Double` — Point coordinates.
- **Returns**: `Int` — Total count of indexed items containing the point.

---

### 1.14 `tree.query_first`

Returns the first item ID intersecting the search window that satisfies a custom predicate.

```moonbit
pub fn query_first(self : StrTree, search_window : Rect, predicate : (Int) -> Bool) -> Int?
```

- **Parameters**:
  - `search_window : Rect` — Search bounding box.
  - `predicate : (Int) -> Bool` — Item ID filter predicate.
- **Returns**: `Int?` — The first matching item ID, or `None` if no elements match.
- **Optimization**: Traversal terminates immediately upon finding the first matching element.

---

### 1.15 `tree.query_with_predicate`

Performs range query filtering items with a user-supplied predicate callback.

```moonbit
pub fn query_with_predicate(self : StrTree, search_window : Rect, predicate : (Int) -> Bool) -> Array[Int]
```

- **Parameters**:
  - `search_window : Rect` — Search bounding box.
  - `predicate : (Int) -> Bool` — Item ID filter predicate.
- **Returns**: `Array[Int]` — All matching item IDs.

---

### 1.16 `tree.query_circle`

Performs circular / radius range intersection query (Circle Range Query).

```moonbit
pub fn query_circle(self : StrTree, cx : Double, cy : Double, radius : Double) -> Array[Int]
```

- **Parameters**:
  - `cx : Double`, `cy : Double` — Circle center coordinates.
  - `radius : Double` — Search radius (negative radius immediately returns empty array).
- **Returns**: `Array[Int]` — All item IDs whose bounding boxes intersect the circle.
- **Pruning**: Squared distance bounding box metric prunes disjoint subtrees immediately.

---

### 1.17 `tree.query_circle_count`

Performs zero-allocation count of items intersecting a circle.

```moonbit
pub fn query_circle_count(self : StrTree, cx : Double, cy : Double, radius : Double) -> Int
```

- **Parameters**: `cx : Double`, `cy : Double` — Circle center; `radius : Double` — Search radius.
- **Returns**: `Int` — Total count of indexed items intersecting the circle with zero heap allocation.

---

### 1.18 `tree.to_flat_buffers` & `StrTree::from_flat_buffers`

Contiguous raw array buffer serialization and zero-copy reconstruction.

```moonbit
pub fn to_flat_buffers(self : StrTree) -> FlatBuffers
pub fn StrTree::from_flat_buffers(buffers : FlatBuffers) -> StrTree
```

- **Features**: Fast snapshotting and deserialization across Wasm memory boundaries or disk persistence.

---

### 1.19 `tree.stats`

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
- `intersects_circle(self : Rect, cx : Double, cy : Double, radius : Double) -> Bool` — Circle intersection test.
- `distance_to_point(self : Rect, x : Double, y : Double) -> Double` — Euclidean distance from box to point.
- `distance_squared_to_point(self : Rect, x : Double, y : Double) -> Double` — Squared Euclidean distance.
- `union(self : Rect, other : Rect) -> Rect` — Computes the Minimum Bounding Rectangle of both boxes.
- `center_x(self : Rect) -> Double` — Center X coordinate.
- `center_y(self : Rect) -> Double` — Center Y coordinate.
- `width(self : Rect) -> Double` — Width.
- `height(self : Rect) -> Double` — Height.
- `area(self : Rect) -> Double` — Area.
- `intersection(self : Rect, other : Rect) -> Option[Rect]` — Computes the intersection rectangle of two boxes (returns `None` if disjoint).
- `expand(self : Rect, delta : Double) -> Rect` — Uniformly expands (or shrinks if negative) the bounding box boundaries.
- `distance_to_rect(self : Rect, other : Rect) -> Double` — Minimum Euclidean distance between two rectangles (`0.0` if intersecting).
- `distance_squared_to_rect(self : Rect, other : Rect) -> Double` — Minimum squared Euclidean distance between two rectangles.
- `iou(self : Rect, other : Rect) -> Double` — Computes Intersection over Union metric in $[0.0, 1.0]$.

---

### 2.2 `Box3D`

Axis-Aligned Bounding Box (3D AABB) in 3-dimensional Euclidean space.

```moonbit
pub struct Box3D {
  min_x : Double
  min_y : Double
  min_z : Double
  max_x : Double
  max_y : Double
  max_z : Double
} derive(Eq, Debug, Default)
```

#### Member Methods
- `Box3D::new(min_x, min_y, min_z, max_x, max_y, max_z) -> Box3D` — Constructs a normalized 3D bounding box.
- `Box3D::from_point(x, y, z) -> Box3D` — Constructs a degenerate zero-volume box centered at a point.
- `intersects(self : Box3D, other : Box3D) -> Bool` — Returns `true` if this box intersects or touches `other`.
- `contains_point(self : Box3D, x : Double, y : Double, z : Double) -> Bool` — 3D point boundary containment test.
- `contains_box(self : Box3D, other : Box3D) -> Bool` — 3D box total enclosure test.
- `union(self : Box3D, other : Box3D) -> Box3D` — Computes Minimum Bounding Box (MBB) enclosing both 3D boxes.
- `intersection(self : Box3D, other : Box3D) -> Option[Box3D]` — Computes the intersection box (or `None` if disjoint).
- `volume(self : Box3D) -> Double` — Volume $\Delta x \times \Delta y \times \Delta z$.
- `surface_area(self : Box3D) -> Double` — Surface area $2(\Delta x \Delta y + \Delta y \Delta z + \Delta z \Delta x)$.
- `center_x(self : Box3D) -> Double`, `center_y(self : Box3D) -> Double`, `center_z(self : Box3D) -> Double` — Center coordinates.
- `expand(self : Box3D, delta : Double) -> Box3D` — Uniform 6-face buffer expansion.
- `distance_squared_to_point(self : Box3D, x : Double, y : Double, z : Double) -> Double` — Squared Euclidean distance to point.
- `distance_to_box(self : Box3D, other : Box3D) -> Double` — Minimum Euclidean distance between two 3D boxes (0.0 if intersecting).
- `iou(self : Box3D, other : Box3D) -> Double` — Volumetric Intersection over Union metric in $[0.0, 1.0]$.
- `intersects_sphere(self : Box3D, cx : Double, cy : Double, cz : Double, radius : Double) -> Bool` — Returns `true` if this 3D box intersects or encloses a sphere.

---

### 2.3 `TreeStats`

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

### 2.4 `FlatBuffers`

```moonbit
pub struct FlatBuffers {
  // Raw contiguous flat array slices
} derive(Eq, Debug, Default)
```

---

## 3. Synthetic Spatial Generators

The root package provides standardized synthetic data distribution generators for benchmarking and fuzzing:

1. `generate_uniform(rng : Rng, count : Int, ...) -> Array[(Rect, Int)]` — Uniform random distribution.
2. `generate_clustered(rng : Rng, count : Int, ...) -> Array[(Rect, Int)]` — Multi-cluster Gaussian distribution.
3. `generate_diagonal(rng : Rng, count : Int, ...) -> Array[(Rect, Int)]` — Degenerate diagonal collinear distribution.
4. `generate_concentric(count : Int, ...) -> Array[(Rect, Int)]` — Nested concentric rectangle distribution.
5. `generate_grid(rows : Int, cols : Int, ...) -> Array[(Rect, Int)]` — Regular GIS tile grid distribution.
6. `generate_boxes_3d_uniform(rng : Rng, count : Int, ...) -> Array[(Box3D, Int)]` — Uniform random 3D bounding box distribution.
7. `generate_boxes_3d_clustered(rng : Rng, count : Int, ...) -> Array[(Box3D, Int)]` — Multi-cluster Gaussian 3D bounding box distribution.

---

## 4. 3D Spatial Index (`StrTree3D`)

### 4.1 `StrTree3D::build`

Bulk loads a packed 3D Sort-Tile-Recursive spatial index with contiguous flat memory buffers.

```moonbit
pub fn StrTree3D::build(items : Array[(Box3D, Int)], node_capacity? : Int = 16) -> StrTree3D
```

- **Parameters**: `items : Array[(Box3D, Int)]` — Array of 3D bounding boxes and IDs; `node_capacity` — Maximum node branching factor.
- **Algorithm**: Slices along X via $S_x = \lceil P^{1/3} \rceil$, partitions Y columns via $S_y = \lceil \sqrt{P_x} \rceil$, and sorts Z coordinates locally before chunking into leaf nodes.

---

### 4.2 `tree3d.query`

Performs 3D bounding box range intersection query using iterative stack traversal.

```moonbit
pub fn query(self : StrTree3D, search_box : Box3D) -> Array[Int]
```

- **Parameters**: `search_box : Box3D` — Target 3D search bounding box.
- **Returns**: `Array[Int]` — IDs of all items whose bounding boxes intersect the search box.

---

### 4.3 `tree3d.query_count`

Zero-heap allocation count of items intersecting a 3D search box.

```moonbit
pub fn query_count(self : StrTree3D, search_box : Box3D) -> Int
```

- **Returns**: `Int` — Number of intersecting items without heap array allocation.

---

### 4.4 `tree3d.query_point`

Performs 3D point containment query.

```moonbit
pub fn query_point(self : StrTree3D, x : Double, y : Double, z : Double) -> Array[Int]
```

- **Returns**: `Array[Int]` — All item IDs enclosing the 3D target point `(x, y, z)`.

---

### 4.5 `tree3d.query_sphere`

Performs 3D spherical range query.

```moonbit
pub fn query_sphere(self : StrTree3D, cx : Double, cy : Double, cz : Double, radius : Double) -> Array[Int]
```

- **Returns**: `Array[Int]` — All item IDs intersecting the target sphere, with squared distance bounding box pruning.

---

### 4.6 `tree3d.stats`

Retrieves 3D tree structural diagnostics and memory metrics.

```moonbit
pub fn stats(self : StrTree3D) -> TreeStats3D
```

