<p align="center">
  <img src="docs/banner.jpg" alt="MoonSTRtree: A Fast, Packed Spatial Index for MoonBit" width="960" />
</p>

<p align="center">
  <img alt="Version 0.1.0" src="https://img.shields.io/badge/Version-0.1.0-334155?style=flat-square" />
  <img alt="Algorithm STR" src="https://img.shields.io/badge/Algorithm-STR_Packing-334155?style=flat-square" />
  <img alt="Targets WASM JS Native" src="https://img.shields.io/badge/Targets-WASM_%7C_JS_%7C_Native-334155?style=flat-square" />
  <a href="LICENSE"><img alt="Apache 2.0" src="https://img.shields.io/badge/License-Apache_2.0-334155?style=flat-square" /></a>
  <img alt="MoonBit Hackathon 2026" src="https://img.shields.io/badge/MoonBit-2026_Hackathon-000000?style=flat-square" />
</p>

<p align="center">
  A high-performance packed 2D spatial index for MoonBit using the Sort-Tile-Recursive (STR) bulk-loading algorithm.
</p>

<p align="center">
  <a href="docs/zh/README.md"><strong>简体中文文档</strong></a> ·
  <a href="#quickstart">Quickstart</a> ·
  <a href="docs/en/SPEC.md">Specification</a> ·
  <a href="docs/en/ROADMAP.md">Roadmap</a> ·
  <a href="docs/en/API_SPECIFICATION.md">API Specification</a> ·
  <a href="docs/en/ARCHITECTURE.md">Architecture</a>
</p>

---

## Overview

MoonSTRtree is an immutable 2D spatial index library for MoonBit. Built on the **Sort-Tile-Recursive (STR)** bulk-loading algorithm, it organizes large collections of 2D bounding boxes into a compact, hierarchical spatial index.

When querying overlapping objects across tens of thousands to hundreds of thousands of spatial elements, brute-force scanning costs O(N) per query. MoonSTRtree packs items into contiguous flat arrays and prunes disjoint subtrees, achieving O(log_M N) range query latency with zero heap allocations during traversal.

## Key Features

- **Strict STR Bulk-Loading**: Recursive coordinate sorting and multi-slice tiling achieve 100% node fill factor with minimal bounding box overlap.
- **Contiguous Packed Arrays**: Multi-level nodes are stored in flat primitive arrays, eliminating pointer dereferences and GC churn on WebAssembly, JS, and Native.
- **Efficient Range & Point Queries**: Exact AABB intersection tests and point containment checks evaluated via an iterative stack without recursion overhead.
- **Robust Edge Case Safety**: Handles empty inputs, zero-area points/lines, negative coordinates, and duplicates gracefully. Verified against brute-force scans.
- **Immutable & Deterministic**: Read-only post-construction, ensuring deterministic tree structure and thread safety.


---

## Choose Your Integration Mode

**Library Engine** — Import directly into MoonBit applications for collision detection, viewport culling, or GIS data processing.

**WebAssembly Playground** — Embed inside browser canvas applications with interactive query window dragging and real-time match highlighting.

**CLI Utility & Benchmarks** — Audit spatial queries and measure latency across 1k, 10k, and 100k items under uniform, clustered, and degenerate distributions.

```powershell
# Run the built-in CLI demonstration
moon run cmd/main
```

---

## Quickstart

### 1. Add Dependency

Declare in `moon.mod`:

```moonbit nocheck
///|
import {
  "LING71671/moon_strtree" @lib,
}
```

### 2. Construct 2D Bounding Boxes

```moonbit nocheck
// Rect::new normalizes coordinates (min_x, min_y, max_x, max_y)

///|
let items : Array[(@moon_strtree.Rect, Int)] = [
  (@moon_strtree.Rect::new(0.0, 0.0, 10.0, 10.0), 101),
  (@moon_strtree.Rect::new(5.0, 5.0, 15.0, 15.0), 102),
  (@moon_strtree.Rect::new(100.0, 100.0, 110.0, 110.0), 103),
]
```

### 3. Bulk-Load Packed Spatial Index

```moonbit nocheck
// Build packed STR tree with node capacity M = 16

///|
let tree = @moon_strtree.StrTree::build(items, node_capacity=16)
```

### 4. Range Query with Subtree Pruning

```moonbit nocheck
///|
let search_window = @moon_strtree.Rect::new(2.0, 2.0, 6.0, 6.0)

///|
let matches : Array[Int] = tree.query(search_window)
// matches == [101, 102]
```

### 5. Point Containment & Tree Diagnostics

```moonbit nocheck
// Point query
let point_matches : Array[Int] = tree.query_point(1.0, 1.0)
// point_matches == [101]

// Structural metrics
let stats = tree.stats()
println("Tree Height: \{stats.height}, Total Nodes: \{stats.num_nodes}")
```

### 6. Branch-and-Bound k-NN Search

```moonbit nocheck
// Finds top-k nearest items sorted by ascending Euclidean distance
let knn_items : Array[Int] = tree.query_knn(0.0, 0.0, 2)
// knn_items == [101, 102]
```

### 7. Ray-Casting & Line Segment Query

```moonbit nocheck
// Queries all bounding boxes intersected by segment (x1, y1) -> (x2, y2)
let ray_hits : Array[Int] = tree.query_segment(0.0, 0.0, 12.0, 12.0)
```

### 8. Dual-Tree Hierarchical Spatial Join

```moonbit nocheck
// Synchronously traverses two STR trees to find overlapping item pairs
let overlapping_pairs : Array[(Int, Int)] = tree_a.spatial_join(tree_b)
```

### 9. FlatBuffers Persistence & Zero-Copy Transfer

```moonbit nocheck
// Export flat contiguous native buffers for disk persistence or Wasm transfer
let buffers = tree.to_flat_buffers()
let reloaded_tree = @moon_strtree.StrTree::from_flat_buffers(buffers)
```

---

## Technical Philosophy & Non-Goals

1. **Strict STR Bulk-Loading, Not Dynamic Trees**: MoonSTRtree uses one-shot spatial packing. It avoids expensive dynamic node splits, yielding maximum packing density and minimal bounding box overlap.
2. **Contiguous Memory Buffers, Not Object Graphs**: All nodes are organized in flat arrays. Traversal uses an iterative integer stack rather than pointer chasing, preventing call stack overflow and GC churn.
3. **Non-Goals**: MoonSTRtree is a lightweight spatial index primitive. It is not a complete GIS database, geometry projection engine, dynamic R*-tree, or 3D engine.

---

## Documentation & Architecture Guides

| Topic | Reference |
| :--- | :--- |
| Chinese Documentation / 简体中文说明书 | [docs/zh/README.md](docs/zh/README.md) |
| Technical Specification / 形式化技术规范 | [docs/en/SPEC.md](docs/en/SPEC.md) / [中文版](docs/zh/SPEC.md) |
| Project Roadmap & Milestones / 项目路线图 | [docs/en/ROADMAP.md](docs/en/ROADMAP.md) / [中文版](docs/zh/ROADMAP.md) |
| System Architecture & Packed Layout | [docs/en/ARCHITECTURE.md](docs/en/ARCHITECTURE.md) / [中文版](docs/zh/ARCHITECTURE.md) |
| API Contracts & Data Types | [docs/en/API_SPECIFICATION.md](docs/en/API_SPECIFICATION.md) / [中文版](docs/zh/API_SPECIFICATION.md) |
| Development Standards & Roadmap | [docs/en/DEVELOPMENT.md](docs/en/DEVELOPMENT.md) / [中文版](docs/zh/DEVELOPMENT.md) |
| Product Specification & Verification | [docs/en/PRODUCT.md](docs/en/PRODUCT.md) / [中文版](docs/zh/PRODUCT.md) |


---

<details>
<summary><strong>Building and Testing from Source</strong></summary>

Requires MoonBit CLI toolchain (`moon`).

```powershell
# Check compilation
moon check

# Execute unit and whitebox tests
moon test

# Format code
moon fmt

# Run CLI demonstration
moon run cmd/main
```

All algorithms run deterministically without external runtime dependencies.

</details>

---

## License

Licensed under the [Apache License, Version 2.0](./LICENSE).