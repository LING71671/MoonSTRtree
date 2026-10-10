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

### 4.3 Branch-and-Bound k-NN Search
- **MinDist Lower Bounding**: For any query point $p = (x, y)$ and node AABB $R$, the lower bound Euclidean distance is computed as:
  $$\text{MinDist}(p, R)^2 = \Delta x^2 + \Delta y^2$$
  where $\Delta x = \max(R.x_{\min} - x, 0, x - R.x_{\max})$ and $\Delta y = \max(R.y_{\min} - y, 0, y - R.y_{\max})$.
- **Priority Queue Pruning**: A flat binary min-heap orders candidate nodes. Traversal immediately terminates when the heap top's $\text{MinDist}$ exceeds the distance to the $k$-th best candidate found so far.

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
