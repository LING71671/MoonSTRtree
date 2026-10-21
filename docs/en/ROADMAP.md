# Roadmap

[English](ROADMAP.md) | [中文](../zh/ROADMAP.md)

## Implemented

Static 2D/3D/4D indexes, geometry and trajectory extensions, layered package ownership, shared nearest-neighbor and DBSCAN traversal, reusable 2D query buffers, checked 2D/3D restoration, and numerical/storage regressions are present in source. The browser experiment now queries the compiled MoonBit core, displays internal bounds and compares real Flatbush/RBush implementations on identical seeded inputs with complete result validation and raw timing export. See [API](API_SPECIFICATION.md) and [validation](VALIDATION.md).

## Remaining work

| Priority | Work | Exit criterion |
| --- | --- | --- |
| Next | Nearest, segment and construction performance; slower point cases | Reduce measured gaps against efficient competitor adapters; keep complete losses and raw evidence |
| Next | Broader multidimensional benchmarks | Recorded distributions, compiler/target metadata, build/query costs and worst-case overlap |
| Next | Direct 3D/4D packed construction | Apply measured improvements after the 2D implementation; record peak memory |
| Later | Safer additional persistence formats | Versioned binary format and validation; do not rename raw arrays into a protocol |

Dynamic insert/delete, coordinate projection, distributed indexing and GPU execution are outside the current static index contract. There are no guaranteed throughput or latency targets presented as achieved results. Future changes should be driven by measured bottlenecks.

## Public evidence and future applications

The [4,640-case geo follow-up](VALIDATION.md#direct-moonbit-geo-follow-up-2026-10-21) completes the same declared protocol for the new circle core. All answers pass; radius scores 1.6277x with 36 slower cases retained. Identical and nested radius subsets remain explicit, as do all unsupported segment queries. This development snapshot is separate from both the earlier geo run and the published 0.2.2 package.

The [packed circle comparison](VALIDATION.md#packed-circle-leaf-traversal-2026-10-21) retains all 2,592 cases: 1.6068x relative to the frozen previous core, 1.0877x relative to Flatbush and 1.6126x relative to RBush. Seven slower cases against the previous core remain; mixed bounds and public airports are still slower than Flatbush. This is a targeted 2D result, not a refreshed full ranking. Leaf-page result collection is implemented; native/multidimensional speed and runtime-memory effects remain unmeasured.

Current work includes efficient competitor adapters, a pinned OurAirports loader, a 456-case diagnostic pass, complete 10,944-case standard reports, configurable exhaustive matrices and a functional 3D/4D browser viewer. Black-and-white charts expose the full standard matrix, failures, unsupported paths and slower cases. The latest 0.2.1 full report scores 0.8921x for queries and 0.5232x for construction relative to Flatbush; point queries score 1.1982x, while nearest neighbors remain at 0.5697x. Measured gaps remain optimization priorities, and the earlier full report is retained. See [current validation](VALIDATION.md#latest-full-standard-matrix-021) for the exact scope and protocol. The 4D builder now preserves coincident branch identity and uses O(n log n) sorts. Runtime memory and multidimensional speed remain unmeasured. The [GitHub Pages showcase](https://ling71671.github.io/MoonSTRtree/) is deployed; checks for the latest report deployment are recorded separately from the measurements.

A separate [direct MoonBit geo comparison](VALIDATION.md#direct-moonbit-geo-comparison-2026-10-20) now retains all 4,640 cases, including identical/nested bounds and empty/singleton inputs. Its 4,060 paired queries score 5.8743x relative to geo 0.1.3, but radius scores 0.9796x and 1,040 slower cases remain. Nearest API differences are disclosed; neither this experiment nor the earlier four-provider snapshot establishes universal superiority. Allocation, GC and peak-memory measurements remain outstanding.

Real application case studies are planned, not shipped: urban building viewport selection using public footprints; airport/runway spatial selection; GeoLife spatial/time-window exploration. Each case must declare provenance and units, separate bounding-box candidates from exact geometry, record full correctness checks and demonstrate a reproducible end-to-end operation. GeoLife and NYC data access/licensing still require source-specific verification before integration.
