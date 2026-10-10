# MoonSTRtree Project Roadmap

[English](./ROADMAP.md) | [中文说明](../zh/ROADMAP.md)

This document outlines the development phases, milestone deliveries, and future evolution of MoonSTRtree.

---

## Vision and Goals

MoonSTRtree is designed to become the standard high-performance, packed 2D spatial index library for the MoonBit ecosystem. It prioritizes deterministic execution, zero runtime garbage collection during queries, and platform-independent execution across WebAssembly, JavaScript, and Native targets.

---

## Release Milestones

### Phase 1: Foundation and Decoupled Primitives (v0.1.0) — Completed

- **Scaffolding and Configuration**:
  - Initialized MoonBit module configuration and dual-format README documentation.
  - Configured git hooks and privacy filters in `.gitignore`.
- **Decoupled 2D Geometry Package (`src/geometry`)**:
  - Implemented immutable `Rect` primitive with automatic coordinate normalization (`min <= max`).
  - Implemented exact AABB intersection (`intersects`), point containment (`contains_point`), rectangle containment (`contains_rect`), and minimum bounding rectangle union (`union`).
  - Added comprehensive whitebox tests for boundary conditions, zero-area points, and negative coordinates.

---

### Phase 2: STR Bulk-Loading and Packed Storage (v0.2.0) — Completed

- **Sort-Tile-Recursive Partitioning Engine (`src/str`)**:
  - Implemented integer arithmetic helpers (`ceil_div`, `isqrt`, `ceil_sqrt`).
  - Implemented multi-slice vertical partitioning ($P = \lceil N/M \rceil, S = \lceil \sqrt{P} \rceil$).
  - Implemented dual-axis recursive sorting: center-X sorting across slices followed by center-Y sorting within slices.
  - Implemented bottom-up node aggregation and MBR union calculations.
- **Packed Array Storage Layout (`src/tree`)**:
  - Replaced pointer-based tree representations with contiguous flat primitive arrays (`boxes_min_x/y/max_x/max_y`).
  - Compressed sparse row (CSR) adjacency indexing (`child_offset`, `child_count`, `child_indices`).
  - Direct leaf item identifier array (`item_ids`).
- **Iterative Stack DFS Query Engine (`src/tree`)**:
  - Range intersection query (`query`) with early subtree pruning.
  - Point containment query (`query_point`) with exact boundary testing.
  - Iterative integer stack traversal with zero memory allocations during search.

---

### Phase 3: Diagnostics, Public Facade, and Verification (v0.3.0) — In Progress

- **Structural Diagnostics Package (`src/stats`)**:
  - `TreeStats` record: item count, node count, tree height, capacity, and fill factor calculation.
  - Structural integrity validator verifying root MBR enclosure and node child bounds.
- **Unified Public Facade (`moon_strtree`)**:
  - Re-export `Rect`, `StrTree`, `TreeStats`, `query`, and `query_point` at the root module level.
  - Standardized constructor signature `StrTree::build(items, node_capacity=16)`.
- **Brute-Force Equivalence Test Suite**:
  - Property-based testing generating 1,000 to 10,000 pseudo-random rectangles.
  - Assert 100% result equivalence between `StrTree::query` and naive $O(N)$ linear scans.

---

### Phase 4: Benchmarking and CLI Tooling (v0.4.0) — Planned

- **CLI Driver (`cmd/main`)**:
  - Command-line utility to load spatial datasets and output tree structural diagnostics.
- **Reproducible Performance Benchmarks**:
  - Evaluation across uniform random, clustered (Gaussian), grid, and degenerate distributions.
  - Throughput metrics: bulk build rate (items/sec) and query latency (microseconds/op).
  - Memory consumption audit across wasm32 and native targets.

---

### Phase 5: WebAssembly Interactive Visualizer (v0.5.0) — Planned

- **Browser Canvas Visualizer**:
  - WebAssembly build target integrated with HTML5 canvas.
  - Real-time rendering of hierarchical MBR boundaries with color-coded levels.
  - Interactive mouse drag query window with instant hit highlighting and FPS counter.

---

### Phase 6: Algorithmic Extensions (v1.0.0) — Future

- **Nearest Neighbor (k-NN) Search**:
  - Priority queue branch-and-bound traversal for k-nearest spatial elements.
- **Distance and Distance-Bounded Queries**:
  - Radial query around a target point within distance $R$.
- **3D Bounding Box Support**:
  - Generalization of STR partitioning to 3D continuous space (cuboids/volumes).
