# MoonSTRtree Development Requirements and Engineering Standards

[English](./DEVELOPMENT.md) | [中文说明](../zh/DEVELOPMENT.md)

This document specifies the decoupled architectural boundaries, memory invariants, testing acceptance criteria, and the 10-step commit roadmap for MoonSTRtree.

---

## 1. Decoupled Architecture

The library is strictly organized into decoupled layers where each layer has a single responsibility and depends only downward:

```text
+-------------------------------------------------------+
|                 Application / Consumer                |
|            (CLI Benchmark, WebAssembly Playground)    |
+-------------------------------------------------------+
                           |
+-------------------------------------------------------+
|                 Spatial Query Engine                  |
|          (Iterative Stack DFS, Subtree Pruning)       |
+-------------------------------------------------------+
                           |
+-------------------------------------------------------+
|                  Packed Storage Model                 |
|       (Contiguous Level Arrays, Zero-GC Layout)       |
+-------------------------------------------------------+
                           |
+-------------------------------------------------------+
|                 STR Packing Pipeline                  |
|     (Pure Coordinate Tiling, Bottom-Up Reduction)     |
+-------------------------------------------------------+
                           |
+-------------------------------------------------------+
|                 Geometric Primitives                  |
|       (Rect, Normalization, Intersection Math)        |
+-------------------------------------------------------+
```

### Module Responsibilities and Boundaries

| Layer / Module | Source File | Dependencies | Invariant & Decoupling Boundary |
| :--- | :--- | :--- | :--- |
| **Geometry** | `geometry.mbt` | None | Pure 2D math. Has no knowledge of trees, slices, arrays, or query stacks. |
| **STR Builder** | `str.mbt` | `geometry.mbt` | Pure algorithmic tiling. Sorts centers, calculates vertical slices, groups by capacity $M$. Has no knowledge of query logic. |
| **Packed Tree** | `tree.mbt` | `geometry.mbt`, `str.mbt` | Flat storage representation. Stores bounding coordinates in contiguous arrays. Read-only post-construction. |
| **Query Engine** | `query.mbt` / `tree.mbt` | `geometry.mbt`, `tree.mbt` | Iterative DFS traversal. Traverses flat buffers without allocating temporary nodes. |
| **Diagnostics** | `stats.mbt` | `tree.mbt` | Independent inspection. Calculates height, node count, and fill factor without altering tree state. |

---

## 2. Engineering Invariants and Constraints

1. **Zero Heap Allocation During Traversal**:
   - Query traversal must use a preallocated integer stack for node offsets.
   - No temporary nodes or intermediate arrays may be allocated in the inner loop of `query` and `query_point`.
2. **Zero Call Stack Recursion**:
   - Depth-First Search must be strictly iterative using an integer offset stack. Maximum stack depth is bounded by `height * node_capacity`, eliminating stack overflow hazards.
3. **Immutability and Concurrency Safety**:
   - Once constructed via `StrTree::build`, index buffers are completely read-only.
   - Multiple concurrent queries can execute across the same tree instance without data races.
4. **Boundary Robustness**:
   - Every operation must be tested against degenerate bounding boxes: points (`width == 0`, `height == 0`), horizontal lines, vertical lines, identical duplicates, negative floating-point numbers, and empty input arrays.
5. **MoonBit Toolchain Compliance**:
   - Strict adherence to modern MoonBit syntax: `derive(Debug)`, `!expr`, `fn Type::method`, `assert_eq`.
   - Zero compilation warnings under `moon check`.

---

## 3. Testing and Verification Acceptance Criteria

- **Unit and Edge-Case Tests**: Every geometric method (`intersects`, `contains_point`, `union`, `is_valid`) must have dedicated whitebox tests.
- **Brute-Force Equivalence**: Every query result must be cross-validated against an $O(N)$ linear scan across 1k, 10k, and 100k random elements.
- **Benchmark Coverage**: Benchmarks must evaluate construction throughput and query latency across uniform, clustered, overlapping, and degenerate distributions.

---

## 4. Atomic Commit Roadmap (10+ Commit Standard)

To meet the hackathon submission requirement of $\ge 10$ meaningful commits, development proceeds in bounded atomic phases:

1. `chore`: Initialize MoonBit scaffolding, module configuration, and `.gitignore`.
2. `docs`: Establish product specification and decoupled architecture guide.
3. `docs`: Add formal API specification and visual assets.
4. `feat(geometry)`: Implement 2D `Rect` primitive with coordinate normalization.
5. `test(geometry)`: Add unit and edge-case whitebox tests for `Rect`.
6. `feat(str)`: Implement Sort-Tile-Recursive slice partition and coordinate sorting.
7. `feat(tree)`: Implement contiguous packed array storage and bottom-up MBR aggregation.
8. `feat(query)`: Implement iterative stack DFS range query and point containment query.
9. `feat(stats)`: Implement tree structural metrics and diagnostic validation.
10. `test(tree)`: Add large-scale property fuzzing and brute-force equivalence validation.
11. `perf(benchmark)`: Implement reproducible benchmark suite across 1k, 10k, and 100k scales.
12. `chore`: Finalize build targets, packaging, and module export contracts.
