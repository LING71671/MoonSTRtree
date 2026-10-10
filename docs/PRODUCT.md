# MoonSTRtree Product Specification

[English](./PRODUCT.md) | [中文说明](./PRODUCT_zh.md)

This document defines the functional scope, target platforms, quality criteria, and boundary constraints for MoonSTRtree (2026 MoonBit Hackathon). Technical details follow [API Specification](API_SPECIFICATION.md) and [Architecture](ARCHITECTURE.md).


## Users and Platforms

Targeted at 2D game developers (collision broadphase, frustum culling), GIS/mapping engineers (tile feature querying, viewport picking), graphics and canvas editor developers, and batch data processing pipelines in the MoonBit ecosystem.

Target execution platforms include WebAssembly (WASM), JavaScript (JS), and Native targets supported by the MoonBit toolchain. The core algorithm is implemented strictly in MoonBit with zero external dependencies.

## Core Capabilities and Algorithm Boundaries

MoonSTRtree is an immutable 2D spatial index library based on the authentic **Sort-Tile-Recursive (STR)** bulk-loading algorithm.

| Mode / Feature | Behavior and Guarantees |
| :--- | :--- |
| `bulk_load` | Receives an array of bounding boxes and unique IDs. Sorts centers along X and Y axes, partitions into tiles, and bottom-up aggregates Minimum Bounding Rectangles (MBR). Node capacity $M \ge 2$ is configurable. |
| `range_query` | Traverses the packed tree, prunes disjoint subtrees, and returns exact object IDs whose bounding boxes intersect the query window. |
| `point_query` | Evaluates point containment against packed node MBRs and returns matching object IDs. |
| `stats` | Returns structural metrics: total items, node count, tree height, capacity, and fill factor. |

1. **Read-Only Post-Construction**: Once built, the tree is completely immutable. Dynamic single-item insertion or deletion is explicitly out of scope for the MVP.
2. **Boundary and Degenerate Safety**: Strictly validates bounding box coordinates. Negative floats, zero-area points, degenerate horizontal/vertical lines, duplicate bounding boxes, and empty input sets are handled deterministically without crashes.
3. **Continuous Memory Layout**: Nodes are packed into contiguous flat buffers rather than pointer-heavy object graphs, ensuring optimal CPU cache locality and zero GC churn during queries.

## Quality and Verification Scope

Verification is conducted across three data scales and five spatial distributions:

- **Scales**: 1,000 / 10,000 / 100,000 bounding boxes.
- **Distributions**: Uniform random, high-density clustered, heavily overlapping, elongated aspect ratios, and degenerate duplicate sets.
- **Correctness Standard**: Every query result must match a brute-force linear scan across all inputs.
- **Reproducibility**: Benchmark programs publicly log hardware configuration, target runtime, parameter sets, and timings without synthesized or estimated multiplier claims.

## WebAssembly Playground

The browser demo delivers real-time visual inspection:
- Random rectangle generator across configurable scales (1k, 10k, 100k).
- Real-time rendering of hierarchical node MBRs.
- Interactive mouse-drag query rectangle with instant match highlighting.
- Live measurement comparing STR query latency against brute-force linear scans.
- Core algorithms compiled directly from MoonBit; JavaScript is limited to DOM/Canvas event dispatch.

## Non-Goals

The initial release explicitly excludes:
- Full GIS engine or projection coordinate conversion.
- Dynamic R*-Tree insertion/deletion.
- 3D spatial indexing.
- Distributed index backends or GPU acceleration.
