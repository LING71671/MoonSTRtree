# Roadmap

[English](ROADMAP.md) | [中文](../zh/ROADMAP.md)

## Implemented

Static 2D/3D/4D indexes, geometry and trajectory extensions, layered package ownership, shared nearest-neighbor and DBSCAN traversal, reusable 2D query buffers, checked 2D/3D restoration, and numerical/storage regressions are present in source. The browser experiment now queries the compiled MoonBit core, displays internal bounds and compares real Flatbush/RBush implementations on identical seeded inputs with complete result validation and raw timing export. See [API](API_SPECIFICATION.md) and [validation](VALIDATION.md).

## Remaining work

| Priority | Work | Exit criterion |
| --- | --- | --- |
| Next | Broader multidimensional benchmarks | Recorded distributions, compiler/target metadata, build/query costs and worst-case overlap |
| Next | Direct 3D/4D packed construction | Apply measured improvements after the 2D implementation; record peak memory |
| Later | Safer additional persistence formats | Versioned binary format and validation; do not rename raw arrays into a protocol |

Dynamic insert/delete, coordinate projection, distributed indexing and GPU execution are outside the current static index contract. There are no guaranteed throughput or latency targets presented as achieved results. Future changes should be driven by measured bottlenecks.

## Public evidence and future applications

Current work includes efficient competitor adapters, a pinned OurAirports loader, a 456-case diagnostic pass, configurable standard/exhaustive matrices and a functional 3D/4D browser viewer. Final broad scores and memory measurements remain pending. Add black-and-white benchmark charts with full slower/failed results and publish the stable showcase through GitHub Pages.

Real application case studies are planned, not shipped: urban building viewport selection using public footprints; airport/runway spatial selection; GeoLife spatial/time-window exploration. Each case must declare provenance and units, separate bounding-box candidates from exact geometry, record full correctness checks and demonstrate a reproducible end-to-end operation. GeoLife and NYC data access/licensing still require source-specific verification before integration.
