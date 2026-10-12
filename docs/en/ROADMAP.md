# Roadmap

[English](ROADMAP.md) | [中文](../zh/ROADMAP.md)

## Implemented

Static 2D/3D/4D indexes, geometry and trajectory extensions, layered package ownership, shared nearest-neighbor and DBSCAN traversal, reusable 2D query buffers, checked 2D/3D restoration, and numerical/storage regressions are present in source. The browser experiment now queries the compiled MoonBit core, displays internal bounds and compares real Flatbush/RBush implementations on identical seeded inputs with complete result validation and raw timing export. See [API](API_SPECIFICATION.md) and [validation](VALIDATION.md).

## Remaining work

| Priority | Work | Exit criterion |
| --- | --- | --- |
| Next | Nearest, point and construction performance | Reduce measured gaps against efficient competitor adapters; keep complete losses and raw evidence |
| Next | Broader multidimensional benchmarks | Recorded distributions, compiler/target metadata, build/query costs and worst-case overlap |
| Next | Direct 3D/4D packed construction | Apply measured improvements after the 2D implementation; record peak memory |
| Later | Safer additional persistence formats | Versioned binary format and validation; do not rename raw arrays into a protocol |

Dynamic insert/delete, coordinate projection, distributed indexing and GPU execution are outside the current static index contract. There are no guaranteed throughput or latency targets presented as achieved results. Future changes should be driven by measured bottlenecks.

## Public evidence and future applications

Current work includes efficient competitor adapters, a pinned OurAirports loader, a 456-case diagnostic pass, a complete 10,944-case standard report, configurable exhaustive matrices and a functional 3D/4D browser viewer. Black-and-white charts expose the full standard matrix, failures, unsupported paths and slower cases. Its overall query score is 0.7731x relative to Flatbush and construction is 0.4981x; measured gaps remain optimization priorities. The 4D builder now preserves coincident branch identity and uses O(n log n) sorts. Runtime memory and multidimensional speed remain unmeasured. The [GitHub Pages showcase](https://ling71671.github.io/MoonSTRtree/) is deployed and its report and real 4D query were verified.

Real application case studies are planned, not shipped: urban building viewport selection using public footprints; airport/runway spatial selection; GeoLife spatial/time-window exploration. Each case must declare provenance and units, separate bounding-box candidates from exact geometry, record full correctness checks and demonstrate a reproducible end-to-end operation. GeoLife and NYC data access/licensing still require source-specific verification before integration.
