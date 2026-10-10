# MoonSTRtree Technical Roadmap and Engineering Panorama

[English](./ROADMAP.md) | [中文说明](../zh/ROADMAP.md)

This document formalizes the engineering roadmap, mathematical foundations, data structure invariants, quantitative performance criteria, and cross-platform milestones for the MoonSTRtree spatial indexing engine.

---

## 1. Core Technical Objectives and Quality Constraints

MoonSTRtree is engineered to deliver industrial-grade throughput and microsecond-level query response for the MoonBit ecosystem under strict systems-level guarantees:

1. **Zero Garbage Collection Allocation During Traversal**: Queries operate strictly across a preallocated contiguous integer stack. The inner search traversal loop performs exactly 0 bytes of heap allocation.
2. **Compact Contiguous Memory Layout**: Hierarchical bounding boxes and node topology are packed into contiguous 1D primitive arrays. Amortized memory overhead across all tree levels is $\le 44$ bytes per indexed spatial element.
3. **Bulk-Loading Throughput Targets**: $\ge 500,000$ rectangles/sec on native platforms; $\ge 200,000$ rectangles/sec on WebAssembly (wasm32).
4. **Query Latency Targets**: On a dataset of $10^5$ spatial rectangles, range queries with $0.1\%$ selectivity must achieve $\le 1.5\,\mu\text{s}$ latency; point containment queries must achieve $\le 0.5\,\mu\text{s}$ latency.
5. **Absolute Equivalence**: Query result ID sets must be 100% equivalent to an exhaustive $O(N)$ linear scan across all spatial scales and data distributions.

---

## 2. Engineering Phases and Deliverables

### Phase 1: Algebraic Geometry Primitives and Interval Arithmetic (v0.1.0) — [Completed]

- **Mathematical Foundations and Data Layout**:
  - Continuous Euclidean 2D AABB primitive: `Rect { min_x: Double, min_y: Double, max_x: Double, max_y: Double }`.
  - Automatic coordinate normalization: Guaranteed $x_{\min} \le x_{\max}$ and $y_{\min} \le y_{\max}$ even under inverted input bounds.
- **Topological Predicates**:
  - Exact closed-interval intersection: $\neg(A.x_{\max} < B.x_{\min} \lor A.x_{\min} > B.x_{\max} \lor A.y_{\max} < B.y_{\min} \lor A.y_{\min} > B.y_{\max})$.
  - Boundary-inclusive point containment and rectangle containment predicates.
  - Minimum Bounding Rectangle (MBR) geometric union operator.
- **Verification Baseline**:
  - Test coverage for zero-area degenerate points, collinear line segments, negative coordinate space, and multi-scale coordinate intervals.
  - Verification of reflexive, symmetric, and transitive geometric algebraic invariants.

---

### Phase 2: STR Dual-Axis Partitioning and Packed Memory Layout (v0.2.0) — [Completed]

- **Formalized Sort-Tile-Recursive Bulk-Loading**:
  - Exact integer arithmetic: Leaf page count $P = \lceil N/M \rceil$, vertical slice count $S = \lceil \sqrt{P} \rceil$, slice page count $P_{\text{slice}} = \lceil P/S \rceil$, and slice item capacity $C_{\text{slice}} = P_{\text{slice}} \times M$.
  - Dual-axis hierarchical greedy sorting: Partition items into vertical slices by global center-X; sort items within each slice by local center-Y.
  - Bottom-up recursive convergence: Leaf nodes packed into groups of capacity $M$, forming new parent inputs recursively until a single root is reached. Tree height is strictly bounded by $H = \lceil \log_M P \rceil + 1$.
- **Packed Array Layout (Flat Arrays & CSR)**:
  - Coordinate storage: `boxes_min_x/y/max_x/max_y : Array[Double]`.
  - Compressed Sparse Row (CSR) topology: `child_offset : Array[Int]`, `child_count : Array[Int]`, `child_indices : Array[Int]`.
  - Leaf item mapping: `item_ids : Array[Int]` (stores original user IDs for leaf items, -1 for internal branches).
- **Iterative Stack DFS Query Pruning Engine**:
  - Zero call stack overhead; maximum stack depth bounded by $H \times M$.
  - Immediate pruning of disjoint subtrees; sequential push of intersecting child nodes.

---

### Phase 3: Structural Diagnostics, Public Facade, and Differential Fuzzing (v0.3.0) — [Completed]

- **Spatial Topological Metrics (`src/stats`)**:
  - Average node fill factor: $\eta = \frac{N}{P \times M} \times 100\%$.
  - Bounding box overlap factor: Quantitative analysis of parent MBR intersection area ratios.
  - Tree structural invariant validator: Recursive proof that parent MBRs strictly enclose all descendant MBRs.
- **Unified Public Facade (`moon_strtree`)**:
  - Export standardized types and methods at the root module level: `Rect`, `StrTree`, `TreeStats`.
  - Canonical constructor signature: `StrTree::build(items : Array[(Rect, Int)], node_capacity~ : Int = 16) -> StrTree`.
  - Canonical query APIs: `query(self : StrTree, search_window : Rect) -> Array[Int]` and `query_point(self : StrTree, x : Double, y : Double) -> Array[Int]`.
- **Differential Fuzzing Suite**:
  - Automated generation of 1,000 to 10,000 pseudo-random geometries and query windows.
  - Differential testing against $O(N)$ brute-force linear scans, asserting 100% ID set equivalence.

---

### Phase 4: Extreme Distribution Benchmarks and CLI Suite (v0.4.0) — [Completed]

- **Five Synthetic Spatial Generators**:
  1. Uniform Distribution: Uniformly scattered across the domain.
  2. Clustered Gaussian: Multi-centroid dense hot-spot clustering.
  3. Diagonal Degenerate: Worst-case slicing collinearity.
  4. Nested Concentric: Extreme hierarchical box nesting.
  5. Regular Grid Tiles: Standard cartographic GIS tiling patterns.
- **Performance Evaluation Suite (`benchmarks/`)**:
  - Benchmark build latency (ms) and throughput (items/sec) across scales of $10^3, 10^4, 10^5, 10^6$.
  - Evaluate query latency percentiles (P50, P95, P99) across variable selectivity levels (0.01%, 0.1%, 1%, 10%).
- **CLI Diagnostic Utility (`cmd/main`)**:
  - Interactive file ingestion, tree depth histogram reporting, and formatted benchmark result output.

---

### Phase 5: WebAssembly Interactive Visualizer (v0.5.0) — [Completed]

- **Wasm Rendering Pipeline**:
  - Compile to standalone wasm32, interfacing with HTML5 Canvas via lightweight JS glue.
  - Zero-copy shared memory transfer of viewport boxes and query hits.
- **Interactive Experience**:
  - Real-time rendering of hierarchical MBR outlines with level-dependent color palettes.
  - Interactive mouse drag query window with instant collision highlighting at a guaranteed 60 FPS.

---

### Phase 6: Higher-Dimensional Generalization and Spatial Operators (v1.0.0+) — [In Progress]

- **Nearest Neighbor (k-NN) Search — [Completed]**:
  - MinDist priority-queue branch-and-bound search for the $k$ nearest spatial items.
- **k-NN Search with Distance Metrics — [Completed]**:
  - Implementation of `query_knn_with_distance` returning `(item_id, squared_distance)` pairs sorted by ascending distance without secondary calculation overhead.
- **k-NN Search with Custom Predicate Filtering — [Completed]**:
  - Implementation of `query_knn_with_predicate` and `query_knn_with_predicate_and_distance` evaluating candidate items directly during branch-and-bound traversal.
- **Parametric Ray-Casting & Segment Query — [Completed]**:
  - Liang-Barsky line clipping traversal for segment intersection testing.
- **Dual-Tree Spatial Join — [Completed]**:
  - Synchronous dual-tree depth-first traversal for bulk collision detection between two independent STRtrees.
- **Advanced Rectangle Topology & Metrics (Rect Metrics & IoU) — [Completed]**:
  - Intersection box computation (`intersection`), uniform boundary expansion (`expand`), inter-rectangle Euclidean distance (`distance_to_rect`), and Intersection over Union metric (`iou`).
- **Zero-Allocation Counting & Early-Exit Predicates — [Completed]**:
  - Support zero-heap-allocation item counters (`query_count`, `query_point_count`), short-circuit search (`query_first`), and user closure filtering (`query_with_predicate`).
- **Circular & Radius Range Queries (Circle Range Query) — [Completed]**:
  - Distance squared pruning for circle intersection filtering (`query_circle`) and zero-allocation radius item counting (`query_circle_count`).
- **3D Spatial Bounding Box & Topological Operators (3D AABB Box3D) — [Completed]**:
  - Implementation of `Box3D` with volume, surface area, 3-axis SAT intersection, containment, union, 6-face buffer expansion, and point-to-box Euclidean distance.
- **3D STRtree Spatial Index Bulk-Loading & Traversal — [Planned]**:
  - 3-axis recursive slicing bulk-loader ($S = \lceil P^{1/3} \rceil$) for volumetric collision detection and point-cloud indexing.
