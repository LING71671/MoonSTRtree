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
- `intersects_segment(self : Box3D, x1 : Double, y1 : Double, z1 : Double, x2 : Double, y2 : Double, z2 : Double) -> Bool` — Returns `true` if this 3D box intersects a 3D line segment / ray via Liang-Barsky slab clipping.

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

### 2.4 `TreeStats3D`

```moonbit
pub struct TreeStats3D {
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

### 2.5 `FlatBuffers`

```moonbit
pub struct FlatBuffers {
  // Raw contiguous flat array slices
} derive(Eq, Debug, Default)
```

---

### 2.6 `FlatBuffers3D`

```moonbit
pub struct FlatBuffers3D {
  // 3D contiguous flat array slices
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

### 4.5 `tree3d.query_point_count`

Performs zero-allocation count of items enclosing 3D point `(x, y, z)`.

```moonbit
pub fn query_point_count(self : StrTree3D, x : Double, y : Double, z : Double) -> Int
```

- **Returns**: `Int` — Number of enclosing items without heap array allocation.

---

### 4.6 `tree3d.query_sphere`

Performs 3D spherical range query.

```moonbit
pub fn query_sphere(self : StrTree3D, cx : Double, cy : Double, cz : Double, radius : Double) -> Array[Int]
```

- **Returns**: `Array[Int]` — All item IDs intersecting the target sphere, with squared distance bounding box pruning.

---

### 4.7 `tree3d.query_sphere_count`

Performs zero-allocation count of items intersecting a 3D sphere.

```moonbit
pub fn query_sphere_count(self : StrTree3D, cx : Double, cy : Double, cz : Double, radius : Double) -> Int
```

- **Returns**: `Int` — Number of items intersecting the sphere without heap array allocation.

---

### 4.8 `tree3d.query_knn`

Performs branch-and-bound k-Nearest Neighbor (k-NN) search in 3D Euclidean space.

```moonbit
pub fn query_knn(self : StrTree3D, x : Double, y : Double, z : Double, k : Int) -> Array[Int]
```

- **Parameters**: `x, y, z : Double` — Query point coordinates; `k : Int` — Maximum number of nearest items.
- **Algorithm**: Branch-and-bound pruning using flat binary min-heap and MinDist squared metrics. Returns item IDs sorted by ascending distance.

---

### 4.9 `tree3d.query_knn_with_distance`

Performs 3D k-NN search returning pairs of `(item_id, squared_distance)`.

```moonbit
pub fn query_knn_with_distance(self : StrTree3D, x : Double, y : Double, z : Double, k : Int) -> Array[(Int, Double)]
```

- **Returns**: `Array[(Int, Double)]` — Tuples of IDs and squared Euclidean distances in ascending order.

---

### 4.10 `tree3d.query_knn_with_predicate` & `query_knn_with_predicate_and_distance`

Performs predicate-filtered 3D k-NN search.

```moonbit
pub fn query_knn_with_predicate(self : StrTree3D, x : Double, y : Double, z : Double, k : Int, predicate : (Int) -> Bool) -> Array[Int]
pub fn query_knn_with_predicate_and_distance(self : StrTree3D, x : Double, y : Double, z : Double, k : Int, predicate : (Int) -> Bool) -> Array[(Int, Double)]
```

- **Features**: Evaluates business predicates in-flight during leaf inspection, pruning candidate heaps accordingly.

---

### 4.11 `tree3d.query_segment`

Performs 3D line segment / ray intersection query (Ray-Casting).

```moonbit
pub fn query_segment(self : StrTree3D, x1 : Double, y1 : Double, z1 : Double, x2 : Double, y2 : Double, z2 : Double) -> Array[Int]
```

- **Parameters**: Line segment endpoints `(x1, y1, z1)` and `(x2, y2, z2)`.
- **Algorithm**: 3D Liang-Barsky parametric axis slab clipping across the packed hierarchical R-tree structure.

---

### 4.12 `tree3d.query_first`

Performs early-exit 3D range intersection query.

```moonbit
pub fn query_first(self : StrTree3D, search_box : Box3D, predicate : (Int) -> Bool) -> Int?
```

- **Parameters**: `search_box : Box3D` — 3D search space; `predicate : (Int) -> Bool` — Item filter.
- **Returns**: `Int?` — Short-circuits and returns `Some(id)` on the first match, or `None` if no elements satisfy the predicate.

---

### 4.13 `tree3d.query_with_predicate`

Performs 3D range intersection query with item filter predicate.

```moonbit
pub fn query_with_predicate(self : StrTree3D, search_box : Box3D, predicate : (Int) -> Bool) -> Array[Int]
```

- **Returns**: `Array[Int]` — IDs of intersecting elements that satisfy the predicate closure.

---

### 4.14 `tree3d.spatial_join`

Performs dual-tree hierarchical spatial join in 3D Euclidean space.

```moonbit
pub fn spatial_join(self : StrTree3D, other : StrTree3D) -> Array[(Int, Int)]
```

- **Parameters**: `other : StrTree3D` — Target 3D tree index.
- **Returns**: `Array[(Int, Int)]` — All pairs of intersecting leaf item IDs `(id_a, id_b)`.
- **Algorithm**: Dual-stack synchronous depth-first traversal with bidirectional subtree pruning.

---

### 4.15 `tree3d.to_flat_buffers` & `StrTree3D::from_flat_buffers`

Exports and reconstructs 3D flat contiguous array buffers.

```moonbit
pub fn to_flat_buffers(self : StrTree3D) -> FlatBuffers3D
pub fn StrTree3D::from_flat_buffers(buffers : FlatBuffers3D) -> StrTree3D
```

- **Features**: Exports 6 coordinate arrays and CSR topology vectors for zero-copy Wasm transfer and persistence.

---

### 4.16 `tree3d.stats`

Retrieves 3D tree structural diagnostics and memory metrics.

```moonbit
pub fn stats(self : StrTree3D) -> TreeStats3D
```

---

## 5. 3D Triangular Mesh Geometry & Spatial Indexing (`Triangle3D` & `StrMeshTree3D`)

### 5.1 `Triangle3D` Geometric Primitive

Triangular facet primitive defined by three 3D vertices in continuous space:

```moonbit
pub struct Triangle3D {
  p0_x : Double
  p0_y : Double
  p0_z : Double
  p1_x : Double
  p1_y : Double
  p1_z : Double
  p2_x : Double
  p2_y : Double
  p2_z : Double
} derive(Eq, Debug, Default)
```

- `Triangle3D::new(p0_x, p0_y, p0_z, p1_x, p1_y, p1_z, p2_x, p2_y, p2_z) -> Triangle3D`: Constructs a 3D triangle facet.
- `tri.to_box() -> Box3D`: Computes the tightest Axis-Aligned Bounding Box (Box3D).
- `tri.centroid() -> (Double, Double, Double)`: Computes arithmetic centroid center of the triangle.
- `tri.normal() -> (Double, Double, Double)`: Computes unit surface normal vector.
- `tri.area() -> Double`: Computes 3D Euclidean surface area.
- `tri.ray_intersection(ox, oy, oz, dx, dy, dz) -> Double?`: Evaluates ray intersection using two-sided Möller–Trumbore algorithm, returning distance $t \ge 0.0$ if hit.
- `tri.intersects_segment(x1, y1, z1, x2, y2, z2) -> Bool`: Determines if a finite 3D line segment pierces the triangle.

---

### 5.2 `StrMeshTree3D` Triangle Mesh Index

Hierarchical bounding volume spatial index engineered for 3D polygon meshes and ray-tracing:

```moonbit
pub struct StrMeshTree3D { ... }
```

- `StrMeshTree3D::build(triangles : Array[Triangle3D], node_capacity? : Int = 16) -> StrMeshTree3D`: Bulk-packs 3D triangle mesh facets.
- `mesh.num_triangles() -> Int`: Returns total number of indexed mesh facets.
- `mesh.get_triangle(id : Int) -> Triangle3D`: Retrieves triangle primitive by index.
- `mesh.query_box(search_box : Box3D) -> Array[Int]`: Retrieves candidate triangle IDs intersecting a 3D bounding box.
- `mesh.query_segment(x1, y1, z1, x2, y2, z2) -> Array[Int]`: Two-stage intersection search: fast AABB pruning followed by exact Möller–Trumbore pierced tests.
- `mesh.query_first_ray_hit(ox, oy, oz, dx, dy, dz, max_distance? : Double = 1000000.0) -> (Int, Double)?`: Accelerated ray tracing returning closest pierced triangle ID and distance $t$.
- `mesh.query_all_ray_hits(ox, oy, oz, dx, dy, dz, max_distance? : Double = 1000000.0) -> Array[(Int, Double)]`: Returns all pierced triangles and distances sorted in ascending order.

---

## 6. 4D Spatiotemporal Hypervolume & Trajectory Indexing (`Box4D` & `StrTree4D`)

### 6.1 `Box4D` Spatiotemporal Geometric Primitive

Axis-aligned hypervolume primitive across continuous $(x, y, z, t)$ space:

```moonbit
pub struct Box4D {
  min_x : Double
  min_y : Double
  min_z : Double
  min_t : Double
  max_x : Double
  max_y : Double
  max_z : Double
  max_t : Double
} derive(Eq, Debug, Default)
```

- `Box4D::new(min_x, min_y, min_z, min_t, max_x, max_y, max_z, max_t) -> Box4D`: Constructs a normalized 4D hypervolume bounding box.
- `box4d.intersects(other : Box4D) -> Bool`: Determines 4-axis hypervolume overlap.
- `box4d.contains_point(x, y, z, t) -> Bool`: Tests 4D spatiotemporal point containment.
- `box4d.contains_box(other : Box4D) -> Bool`: Tests complete 4D hypervolume enclosure.
- `box4d.union(other : Box4D) -> Box4D`: Computes minimum enclosing 4D bounding hypervolume.
- `box4d.intersection(other : Box4D) -> Box4D?`: Computes intersection hypervolume of two 4D boxes.
- `box4d.hyper_volume() -> Double`: Evaluates 4D hypervolume measure ($\Delta x \times \Delta y \times \Delta z \times \Delta t$).
- `box4d.to_box3d() -> Box3D`: Extracts spatial 3D bounding box projection.
- `box4d.expand(dx, dy, dz, dt) -> Box4D`: Expands hypervolume along all four dimensions.
- `box4d.intersects_at_time(other : Box4D, t : Double) -> Bool`: Tests if two moving trajectories overlap at exact timestamp $t$.

---

### 6.2 `StrTree4D` 4-Way Recursive Slicing Index

Bulk-loaded spatiotemporal spatial index engineered for dynamic entities, continuous trajectory intersections, and moving object simulations:

```moonbit
pub struct StrTree4D { ... }
```

- `StrTree4D::build(items : Array[(Box4D, Int)], node_capacity? : Int = 16) -> StrTree4D`: 4-way recursive slicing bulk-loader ($S_x = \lceil P^{1/4} \rceil, S_y = \lceil P_x^{1/3} \rceil, S_z = \lceil \sqrt{P_{xy}} \rceil$).
- `tree4d.query(search_box : Box4D) -> Array[Int]`: 4D hypervolume range query.
- `tree4d.query_point(x, y, z, t) -> Array[Int]`: 4D point containment search.
- `tree4d.query_count(search_box : Box4D) -> Int`: Zero-allocation 4D hypervolume item counter.
- `tree4d.query_time_slice(t : Double, box_3d : Box3D) -> Array[Int]`: Instantaneous temporal slice query (retrieves all moving items active at timestamp $t$ within spatial 3D window).
- `tree4d.stats() -> TreeStats4D`: Evaluates structural diagnostic metrics.

---

## 7. DE-9IM Topological Model & Adaptive Spatial Join (`SpatialPredicate`, `relate` & `spatial_join_predicate`)

### 7.1 `SpatialPredicate` Named OGC Topological Predicates Enum

```moonbit
pub(all) enum SpatialPredicate {
  Intersects
  Contains
  Within
  Touches
  Overlaps
  Disjoint
  Equals
  Covers
  CoveredBy
} derive(Eq, Debug)
```

- `SpatialPredicate::from_string(name : String) -> SpatialPredicate?`: Parses predicate string identifier.
- `predicate.to_string() -> String`: Converts predicate to standard lowercase string identifier.

### 7.2 `Rect` DE-9IM Matrix & Topological Evaluation

- `rect.touches(other : Rect) -> Bool`: Tests if boundaries intersect and interiors are disjoint.
- `rect.covers(other : Rect) -> Bool`: Tests if every point of other is contained within rect.
- `rect.covered_by(other : Rect) -> Bool`: Tests if rect is topologically covered by other.
- `rect.contains(other : Rect) -> Bool`: Tests containment with non-empty interior intersection.
- `rect.within(other : Rect) -> Bool`: Tests if rect is contained within other.
- `rect.equals_exact(other : Rect) -> Bool`: Tests exact equivalence of all four coordinate bounds.
- `rect.disjoint(other : Rect) -> Bool`: Tests complete geometric separation (no common points).
- `rect.overlaps(other : Rect) -> Bool`: Tests interior intersection without either geometry covering the other.
- `rect.evaluate_predicate(other : Rect, predicate : SpatialPredicate) -> Bool`: Evaluates a named topological predicate dynamically.
- `rect.relate(other : Rect) -> String`: Computes the 9-character Dimensionally Extended 9-Intersection Model (DE-9IM) matrix string (e.g. `"2FFF1FFF2"`, `"FF2FF1212"`, `"212101212"`).
- `matches_de9im_pattern(matrix : String, pattern : String) -> Bool`: Pattern matching against DE-9IM wildcards (`*`, `T`, `F`, `0`, `1`, `2`).

### 7.3 `StrTree` Predicate Query & Dual-Tree Spatial Join

- `tree.query_spatial_predicate(rect : Rect, predicate : SpatialPredicate) -> Array[Int]`: Range query filtered by named DE-9IM topological predicate.
- `tree.spatial_join(other : StrTree) -> Array[(Int, Int)]`: Hierarchical spatial join evaluating intersection between two trees.
- `tree.spatial_join_predicate(other : StrTree, predicate : SpatialPredicate) -> Array[(Int, Int)]`: Hierarchical spatial join filtering candidate pairs by named topological predicate.

---

## 8. Spatial Density Clustering & Grid Heatmap Aggregation (`ClusterResult`, `GridCell` & `GridDensitySummary`)

### 8.1 Spatial Index-Accelerated DBSCAN Clustering

Leverages spatial circular/spherical range queries (`query_circle` / `query_sphere`) to accelerate traditional $O(N^2)$ DBSCAN down to $O(N \log N)$:

```moonbit
pub struct ClusterResult {
  labels : Array[Int]
  num_clusters : Int
  num_noise : Int
  cluster_sizes : Array[Int]
} derive(Eq, Debug, Default)
```

- `tree.dbscan(eps : Double, min_pts : Int) -> ClusterResult`: Evaluates 2D DBSCAN clustering using spatial tree pruning.
- `tree3d.dbscan(eps : Double, min_pts : Int) -> ClusterResult`: Evaluates 3D DBSCAN clustering using 3D spherical tree pruning.

### 8.2 Spatial Grid Density Heatmap Aggregation (`GridCell` & `GridDensitySummary`)

```moonbit
pub struct GridCell {
  col : Int
  row : Int
  count : Int
  bounds : Rect
} derive(Eq, Debug, Default)

pub struct GridDensitySummary {
  cells : Array[GridCell]
  total_cells : Int
  max_density : Int
  avg_density : Double
  hotspot_cells : Array[GridCell]
} derive(Eq, Debug, Default)
```

- `tree.aggregate_grid(cell_width : Double, cell_height : Double, hotspot_threshold? : Int = 1) -> GridDensitySummary`: Aggregates spatial entities into uniform 2D grid cells, computing cell distribution histograms, peak density, and hotspot areas.






