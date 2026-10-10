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

### 1.6 `tree.stats`

Calculates and returns tree structural diagnostics.

```moonbit
pub fn stats(self : StrTree) -> TreeStats
```

- **Returns**: `TreeStats` — Metrics on tree height, total node count, item count, and capacity.

---

## 2. Type Definitions

### 2.1 `Rect`

```moonbit
pub struct Rect {
  min_x : Double
  min_y : Double
  max_x : Double
  max_y : Double
} derive(Eq, Show)
```

#### Member Methods
- `intersects(self : Rect, other : Rect) -> Bool` — Returns `true` if this box intersects or touches `other`.
- `contains_point(self : Rect, x : Double, y : Double) -> Bool` — Inclusive boundary containment test.
- `union(self : Rect, other : Rect) -> Rect` — Computes the Minimum Bounding Rectangle of both boxes.
- `center_x(self : Rect) -> Double` — Center X coordinate `(min_x + max_x) / 2.0`.
- `center_y(self : Rect) -> Double` — Center Y coordinate `(min_y + max_y) / 2.0`.
- `is_valid(self : Rect) -> Bool` — Validates that coordinates are finite numbers.

---

### 2.2 `StrTree`

```moonbit
pub struct StrTree {
  node_capacity : Int
  num_items : Int
  // Internal contiguous level buffers
}
```

---

### 2.3 `TreeStats`

```moonbit
pub struct TreeStats {
  num_items : Int
  num_nodes : Int
  height : Int
  node_capacity : Int
  fill_factor : Double
} derive(Eq, Show)
```
