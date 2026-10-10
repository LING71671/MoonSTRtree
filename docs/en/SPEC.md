# MoonSTRtree Technical Specification

[English](./SPEC.md) | [中文说明](../zh/SPEC.md)

This specification defines the formal mathematical foundations, algorithmic invariants, memory layouts, and conformance requirements of the MoonSTRtree spatial indexing engine.

---

## 1. Mathematical Foundation

### 1.1 Coordinate Space
All geometries exist within continuous two-dimensional Euclidean space $\mathbb{R}^2$. Coordinates are represented using IEEE 754 double-precision floating-point numbers (`Double`).

### 1.2 Axis-Aligned Bounding Box (AABB)
An AABB $R$ is defined by a closed orthogonal interval:
$$R = [x_{\min}, x_{\max}] \times [y_{\min}, y_{\max}]$$
Subject to the invariant:
$$x_{\min} \le x_{\max} \quad \text{and} \quad y_{\min} \le y_{\max}$$

If an unnormalized tuple $(x_1, y_1, x_2, y_2)$ is supplied, the normalized bounds are computed as:
$$x_{\min} = \min(x_1, x_2), \quad x_{\max} = \max(x_1, x_2)$$
$$y_{\min} = \min(y_1, y_2), \quad y_{\max} = \max(y_1, y_2)$$

### 1.3 Geometric Predicates

#### 1.3.1 Intersection
Two bounding boxes $A$ and $B$ intersect ($A \cap B \ne \emptyset$) if and only if they overlap along both axes:
$$\text{intersects}(A, B) \iff \neg (A.x_{\max} < B.x_{\min} \lor A.x_{\min} > B.x_{\max} \lor A.y_{\max} < B.y_{\min} \lor A.y_{\min} > B.y_{\max})$$

#### 1.3.2 Point Containment
A point $p = (x, y)$ is contained in $B$ ($p \in B$) if and only if:
$$\text{contains\_point}(B, x, y) \iff B.x_{\min} \le x \le B.x_{\max} \land B.y_{\min} \le y \le B.y_{\max}$$

#### 1.3.3 Bounding Box Union
The Minimum Bounding Rectangle enclosing two rectangles $A$ and $B$ is:
$$\text{union}(A, B) = [\min(A.x_{\min}, B.x_{\min}), \max(A.x_{\max}, B.x_{\max})] \times [\min(A.y_{\min}, B.y_{\min}), \max(A.y_{\max}, B.y_{\max})]$$

---

## 2. Sort-Tile-Recursive (STR) Partitioning Formalism

Given $N$ geometric items and maximum node capacity $M \ge 2$:

1. **Leaf Page Count**:
   $$P = \left\lceil \frac{N}{M} \right\rceil$$
2. **Vertical Slice Count**:
   $$S = \left\lceil \sqrt{P} \right\rceil$$
3. **Pages per Slice**:
   $$P_{\text{slice}} = \left\lceil \frac{P}{S} \right\rceil$$
4. **Slice Item Capacity**:
   $$C_{\text{slice}} = P_{\text{slice}} \times M$$
5. **Horizontal Partitioning**:
   Items are ordered along the X-axis by their geometric center:
   $$\text{center}_x = \frac{x_{\min} + x_{\max}}{2.0}$$
   The array is partitioned into $S$ contiguous slices of at most $C_{\text{slice}}$ items.
6. **Vertical Tiling**:
   Within each slice, items are sorted along the Y-axis by their geometric center:
   $$\text{center}_y = \frac{y_{\min} + y_{\max}}{2.0}$$
   Items are grouped into consecutive nodes of at most $M$ items.
7. **Bottom-Up Level Recursion**:
   The resulting parent nodes form the input to the next level. The procedure recurses until a single root node remains.

---

## 3. Flat Memory Layout and Packed Array Storage

To eliminate pointer indirection, cache misses, and runtime garbage collection:

### 3.1 Primary Coordinate Buffers
- `boxes_min_x: Array[Double]` — Minimum X coordinate per node.
- `boxes_min_y: Array[Double]` — Minimum Y coordinate per node.
- `boxes_max_x: Array[Double]` — Maximum X coordinate per node.
- `boxes_max_y: Array[Double]` — Maximum Y coordinate per node.

### 3.2 Topology and Adjacency Buffers (CSR)
- `child_offset: Array[Int]` — Starting index into `child_indices` for node $i$.
- `child_count: Array[Int]` — Number of child nodes for node $i$ (0 for leaf items).
- `child_indices: Array[Int]` — Packed array of child node indices.
- `item_ids: Array[Int]` — User-assigned integer identifier (valid for leaf items, -1 for internal nodes).

---

## 4. Query Pruning Engine

### 4.1 Iterative Stack Traversal
- Search executes without language-level recursive function calls.
- Traversal maintains an integer stack of node offsets.
- When evaluating node $k$:
  - If $k$ is a leaf item (`child_count[k] == 0`), its `item_ids[k]` is added to the output.
  - If $k$ is an internal node (`child_count[k] > 0`), each child is tested against the query window. Only children whose MBR intersects the query window are pushed onto the stack.

### 4.2 Allocation Invariant
- **Zero Heap Allocations**: The inner traversal loop performs zero allocations.

### 4.3 Branch-and-Bound k-NN Search & Distance Metrics
- **MinDist Lower Bounding**: For any query point $p = (x, y)$ and node AABB $R$, the lower bound Euclidean distance is computed as:
  $$\text{MinDist}(p, R)^2 = \Delta x^2 + \Delta y^2$$
  where $\Delta x = \max(R.x_{\min} - x, 0, x - R.x_{\max})$ and $\Delta y = \max(R.y_{\min} - y, 0, y - R.y_{\max})$.
- **Priority Queue Pruning**: A flat binary min-heap orders candidate nodes. Traversal immediately terminates when the heap top's $\text{MinDist}$ exceeds the distance to the $k$-th best candidate found so far.
- **Direct Metric Delivery**: `query_knn_with_distance` directly yields ascending `(item_id, squared_distance)` tuples throughout branch-and-bound pruning, eliminating downstream distance calculations.
- **In-Flight Predicate Filtering**: `query_knn_with_predicate` and `query_knn_with_predicate_and_distance` evaluate user predicate filters directly at leaf discovery, maintaining the tightest possible pruning bounds without post-filtering allocations.

### 4.4 Parametric Ray-Casting & Line Segment Query
- **Liang-Barsky Clipping**: Line segments are parameterized as $P(t) = P_1 + t(P_2 - P_1)$ for $t \in [0, 1]$.
- **Recursion-Free Slab Clipping**: Segment entry/exit parameters $[t_1, t_2]$ are evaluated along $X$ and $Y$ axes. Subtrees where $t_{\min} > t_{\max}$ are pruned immediately.

### 4.5 Dual-Tree Hierarchical Spatial Join
- **Synchronous DFS Traversal**: Traverses two STR trees concurrently via an explicit pair stack $[(u_A, v_B)]$.
- **Bidirectional Subtree Pruning**: If $\text{intersects}(\text{MBR}(u_A), \text{MBR}(v_B)) = \text{false}$, both subtrees are pruned, reducing cross-set collision overhead from $O(N_A \times N_B)$ to sub-quadratic.

### 4.6 Native Flat Array Buffer Serialization (FlatBuffers)
- **Zero-Copy Snapshots**: Coordinate arrays, CSR offsets, and item ID buffers are exported as contiguous native flat arrays, enabling fast serialization across WebAssembly memory boundaries.

### 4.7 Rectangle Topology & Metric Operators (Rect Metrics & IoU)
- **Sub-Rectangle Intersection**: If two rectangles intersect, the intersection box is $[\max(x_{\min 1}, x_{\min 2}), \max(y_{\min 1}, y_{\min 2})] \times [\min(x_{\max 1}, x_{\max 2}), \min(y_{\max 1}, y_{\max 2})]$.
- **Intersection over Union (IoU)**: $\text{IoU}(R_1, R_2) = \frac{\text{Area}(R_1 \cap R_2)}{\text{Area}(R_1) + \text{Area}(R_2) - \text{Area}(R_1 \cap R_2)}$, normalized in $[0.0, 1.0]$.
- **Minimum Inter-Rectangle Distance**: Separating-axis Euclidean distance $\sqrt{\Delta x^2 + \Delta y^2}$ with $0.0$ on overlap.
- **Uniform Boundary Expansion (Expand)**: Equidistant outward buffer expansion and shrinkage operations.

### 4.8 Zero-Allocation Counting & Early-Exit Predicate Queries
- **Zero-Allocation Counter**: `query_count` and `query_point_count` aggregate matching leaf entries without allocating result arrays, eliminating garbage collection pauses.
- **Short-Circuit Early Exit**: `query_first` evaluates candidate IDs against a user closure and immediately returns `Some(id)` upon the first match.
- **Predicate Filtering**: `query_with_predicate` combines spatial pruning with arbitrary application filtering in a single traversal pass.

### 4.9 Circular & Radius Range Queries (Circle Range Query)
- **Squared Distance Pruning**: For center $(c_x, c_y)$ and radius $R$, node MBRs are pruned whenever $\Delta x^2 + \Delta y^2 > R^2$, avoiding expensive square root operations.
- **Zero-Allocation Radius Counting**: `query_circle_count` delivers zero-GC performance for geo-fencing and buffer neighborhood analytics.

### 4.10 3D Axis-Aligned Bounding Box Operators (3D AABB Box3D)
- **Orthogonal Separating Axis Theorem (SAT)**: Two 3D boxes intersect if and only if their intervals overlap along all three principal axes ($X, Y, Z$).
- **Volume and Surface Area Metrics**: $\text{Volume} = \Delta x \times \Delta y \times \Delta z$, $\text{SurfaceArea} = 2(\Delta x \Delta y + \Delta y \Delta z + \Delta z \Delta x)$.
- **Point-to-Box Squared Distance**: Independent axis projection $\Delta x^2 + \Delta y^2 + \Delta z^2$, supporting point-cloud partitioning and volumetric collision detection.
- **Box-to-Box Distance & Volumetric IoU**: 3D Euclidean clearance calculation and exact volumetric Intersection over Union in $[0.0, 1.0]$.
- **Sphere-Box Intersection**: Fast collision detection via squared point-to-box distance thresholded at $R^2$ with zero square roots.

### 4.11 3D Sort-Tile-Recursive Contiguous Array Index (3D STRtree)
- **3-Axis Recursive Slicing**: Slices along X via cube root $S_x = \lceil P^{1/3} \rceil$, partitions Y columns via square root $S_y = \lceil \sqrt{P_x} \rceil$, and sorts Z coordinates locally before leaf packing.
- **Flat 6-Tuple Array Layout**: 6 contiguous coordinate vectors (`boxes_min_x/y/z` and `boxes_max_x/y/z`) with CSR branch pointers guarantee $O(N)$ cache-friendly memory locality.
- **Multi-Modal 3D Queries**: Supports 3D AABB range intersection (`query`), zero-allocation counting (`query_count`), 3D point containment (`query_point`), and spherical intersection (`query_sphere`).

### 4.12 3D k-Nearest Neighbor & Parametric Ray-Casting (3D k-NN & Ray-Casting)
- **3D Branch-and-Bound k-NN**: Flat binary min-heap traversal using squared Euclidean point-to-box distance for aggressive subtree pruning. Supports distance sorting (`query_knn_with_distance`) and predicate filtering (`query_knn_with_predicate`).
- **3D Liang-Barsky Ray-Casting**: Parametric axis interval clipping across $X, Y, Z$ dimensions (`query_segment`) for microsecond-level volumetric line intersection and line-of-sight picking.
- **Zero-Allocation 3D Counting**: `query_point_count` and `query_sphere_count` provide GC-free volumetric statistics.

### 4.13 3D Dual-Tree Spatial Join & Native Serialization (3D Spatial Join & FlatBuffers3D)
- **Synchronous DFS Dual-Tree Traversal**: `spatial_join` executes dual-stack simultaneous depth-first search with bidirectional subtree bounding box pruning, capturing volumetric intersections with sub-quadratic complexity.
- **Early-Exit Short-Circuiting & Predicates**: `query_first` provides instant single-match retrieval, and `query_with_predicate` enforces business constraints in-flight.
- **Contiguous Array Buffer Serialization**: `FlatBuffers3D` captures the 6 coordinate arrays and CSR adjacency vectors for zero-copy inter-process and Wasm exchange.

### 4.14 3D Triangle Geometry & Mesh Facet Indexing (3D Triangle & Mesh Indexing)
- **Möller–Trumbore Exact Intersection**: Formulates ray-triangle intersection under barycentric coordinates $\mathbf{O} + t \mathbf{D} = (1 - u - v)\mathbf{V}_0 + u \mathbf{V}_1 + v \mathbf{V}_2$, evaluating piercing points in $O(1)$ time with two-sided support and degenerate tolerance.
- **Two-Stage Accelerated Mesh Pipeline**: `StrMeshTree3D` packages all triangle bounding boxes into an underlying `StrTree3D`. Queries (box, segment, ray) undergo logarithmic hierarchical AABB pruning before evaluating Möller–Trumbore tests on surviving candidates, enabling high-precision ray-tracing and mesh collision queries.

### 4.15 4D Spatiotemporal Hypervolume & Trajectory Indexing (4D Spatiotemporal Indexing)
- **4D Hypervolume Metrics**: `Box4D` models continuous 4D $(x, y, z, t)$ hypervolumes with 4-axis SAT overlap tests, hypervolume $\prod \Delta x_i$, 4-way expansion, and instantaneous collision timestamp verification (`intersects_at_time`).
- **4-Way Recursive Slicing**: `StrTree4D` cascades slicing across 4 dimensions ($S_x = \lceil P^{1/4} \rceil, S_y = \lceil P_x^{1/3} \rceil, S_z = \lceil \sqrt{P_{xy}} \rceil$) to organize dynamic trajectories into flat array storage, supporting instantaneous temporal slice queries (`query_time_slice`).

### 4.16 DE-9IM Topological Model & Adaptive Spatial Join (DE-9IM & Spatial Joins)
- **Dimensionally Extended 9-Intersection Model (DE-9IM)**: Evaluates intersection dimensions across Interior ($I$), Boundary ($B$), and Exterior ($E$) of geometries, generating standard 9-character code strings (`Rect::relate`) and matching against wildcard patterns (`matches_de9im_pattern`).
- **OGC Named Spatial Predicates**: Evaluates `Intersects`, `Contains`, `Within`, `Touches`, `Overlaps`, `Disjoint`, `Equals`, `Covers`, and `CoveredBy` in $O(1)$ time without runtime allocations.
- **Hierarchical Adaptive Spatial Join**: Employs dual-tree simultaneous traversal with hierarchical bounding volume pruning and adaptive area-expansion heuristics, providing $O(N \log N)$ spatial joins (`spatial_join`, `spatial_join_predicate`).

### 4.17 Spatial Index-Accelerated Clustering & Grid Aggregation (Spatial Clustering & Grid Aggregation)
- **Tree-Pruned DBSCAN Clustering**: Leverages 2D circular and 3D spherical spatial bounding queries (`query_circle`, `query_sphere`) to prune neighbor searches in $O(\log N)$ rather than naive $O(N)$ full-table distance scans, accelerating density-based cluster discovery on dense point sets and bounding geometries.
- **Uniform Grid Density Aggregation**: `aggregate_grid` adaptively subdivides the bounding extent into regular orthogonal cells, tabulating element counts, density ratios, and ranked hotspot clusters to identify high-density geographic concentrations.

### 4.18 Streaming Geofencing Transitions & Spatiotemporal Sliding-Window Trajectory Index (Geofencing & Trajectory Window Index)
- **Spatial Index-Accelerated Geofence State Tracker**: `GeofenceMonitor` organizes boundary boxes in an underlying `StrTree`. Queries evaluate active candidate geofences in $O(\log N)$ time, generating discrete transition events (`Enter`, `Exit`, `Stay`) against historical presence states.
- **Dual-Constraint Trajectory Segment Pruning**: `TrajectoryWindowIndex` breaks continuous tracks into directed segments $(p_0, p_1)$. Traversal utilizes spatial bounding box hierarchy pruning alongside temporal interval intersection $[seg.min\_t, seg.max\_t] \cap [t_{\min}, t_{\max}] \ne \emptyset$, enabling efficient spatiotemporal window filtering and trajectory discovery.

### 4.19 Trajectory Simplification & Synchronized Euclidean Distance (SED) Error Bounding (Trajectory Simplification & Compression)
- **Classical 2D Douglas-Peucker Topological Decimation**: Employs divide-and-conquer recursion to compute perpendicular distance $d_\perp$ from intermediate points to the chord connecting endpoints. Points with $d_{\max} \le \epsilon$ are culled, delivering high geometric fidelity with dramatic point reduction.
- **Synchronized Euclidean Distance (SED) Temporal Fidelity**: Evaluates spatiotemporal error by comparing waypoint position $(x_i, y_i)$ at timestamp $t_i$ against the linearly interpolated synchronized reference point $(x_{\text{sync}}, y_{\text{sync}})$ on segment $P_0 P_{n-1}$. This guarantees that kinematic velocity shifts and temporal pauses are preserved rather than lost to spatial-only culling.
- **Sliding-Window Online Compression**: `StreamingTrajectoryCompressor` maintains an incremental buffer, evaluating error bound violations in real time and locking in intermediate waypoints before streaming them downstream with zero delay.

### 4.20 Trajectory Dynamic Time Warping & Discrete Fréchet Distance (Trajectory DTW & Discrete Fréchet)
- **Dynamic Time Warping (DTW)**: Accommodates non-uniform sampling rates and temporal dilation between variable-length spatiotemporal trajectories by evaluating the dynamic programming recurrence $D(i, j) = d(p_i, q_j) + \min(D(i-1, j), D(i, j-1), D(i-1, j-1))$.
- **Sakoe-Chiba Band Constraint & $O(M)$ Rolling Buffer**: Applies an optional temporal distortion window constraint $|i - j| \le w$ to suppress pathological warping paths while bounding computation to a narrow diagonal band. The DP matrix state maintains only previous and current rows, reducing heap space complexity from $O(N \cdot M)$ to $O(M)$.
- **Discrete Fréchet Leash Distance**: Evaluates the maximal bottleneck alignment gap between two polygonal curves via the recurrence $F(i, j) = \max(d(p_i, q_j), \min(F(i-1, j), F(i, j-1), F(i-1, j-1)))$, executed within an allocation-minimized $O(M)$ dual-row rolling buffer.

---



## 5. Complexity Guarantees

| Metric | Bound |
| :--- | :--- |
| Bulk Construction Time | $O(N \log N)$ |
| Space Complexity | $O(N)$ contiguous storage |
| Range Query Time (Average) | $O(\log_M N)$ |
| Range Query Time (Worst-Case) | $O(N)$ (all items overlapping) |
| Heap Allocations During Query | $0$ bytes |
| Call Stack Depth | $O(1)$ |

---

## 6. Edge Cases and Conformance

- **Empty Collection ($N = 0$)**: Produces a valid empty tree with `num_items = 0`, `height = 0`. Queries return empty arrays.
- **Single Item ($N = 1$)**: Produces a tree with 1 leaf item under a single root.
- **Zero-Area Bounds**: Degenerate points ($x_{\min} = x_{\max}, y_{\min} = y_{\max}$) and zero-width lines are fully indexed.
- **Non-Finite Coordinates**: Filtered or rejected via `Rect::is_valid`.
