# MoonSTRtree

<p align="center"><img src="docs/banner.jpg" alt="MoonSTRtree spatial index" width="960" /></p>

<p align="center"><a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-555?style=flat-square" alt="Apache-2.0 license" /></a></p>

<p align="center">MoonBit static spatial indexes: 2D bounds, 3D volumes and 4D spacetime, with geometry and trajectory extensions.</p>

<p align="center"><a href="README.md">English</a> | <a href="docs/zh/README.md">中文</a> | <a href="#quick-start">Quick start</a> | <a href="docs/en/API_SPECIFICATION.md">API</a> | <a href="docs/en/ARCHITECTURE.md">Architecture</a></p>

Requires **moonc 0.10.14 or newer**. Run `moonc -v` to check the compiler rather than the `moon` CLI version.

## Quick start

```powershell
moon add LING71671/moon_strtree
```

Declare the package alias in your application's `moon.pkg`:

```text
import {
  "LING71671/moon_strtree" @spatial,
}
```

```moonbit
let items = [
  (@spatial.Rect::new(0.0, 0.0, 10.0, 10.0), 101),
  (@spatial.Rect::new(20.0, 20.0, 30.0, 30.0), 102),
]
let tree = @spatial.StrTree::build(items, node_capacity=16)
let hits = tree.query(@spatial.Rect::new(5.0, 5.0, 15.0, 15.0))
```

The query includes ID 101. Touching boundaries count as intersections. IDs must be non-negative and coordinates finite. The index is immutable after construction; rebuild when data changes. Result order and the identity chosen among tied nearest neighbors are unspecified.

## Capabilities and limits

| Domain | Implemented |
| --- | --- |
| Indexes | 2D, 3D and 4D STR packing, range and point queries |
| 2D / 3D queries | Counts, first hit, filters, nearest neighbors, radius, segments, spatial joins |
| Geometry | Bounding-box predicates, mesh ray queries, polygon calculations and clipping |
| Analysis | Center-based DBSCAN, grid density, geofence events |
| Trajectories | Time-window candidates, simplification, streaming compression, DTW and discrete Frechet distance |
| Storage | Independently copied arrays; optional checked restore for 2D and 3D |

`query_into` reuses caller-owned result and traversal arrays. Count queries avoid result arrays but allocate traversal scratch. Storage import/export copies arrays; this is neither a zero-copy protocol nor the FlatBuffers binary format. Heavy overlap can require visiting every object, so logarithmic query cost is not guaranteed.

## Explore and verify

```powershell
moon check
moon test
moon test --target js
moon test --target wasm-gc
moon info
moon fmt
```

The [browser experiment](playground/) runs compiled MoonBit queries beside real Flatbush and RBush implementations. Draw a query, reveal actual packed node bounds, measure identical seeded inputs, and export raw timing evidence. The comparison ledger measures the JS target and 2D queries; a separate 3D/4D experiment exposes height and time queries with complete result export. It does not establish a universal speed ranking. Start it with `cd playground` and `pnpm dev` after `pnpm install`.

`moon run cmd/main` prints diagnostic examples, not benchmark timings. See the [development guide](docs/en/DEVELOPMENT.md) for toolchain setup and the [validation record](docs/en/VALIDATION.md) for executed checks.

## Source ownership

<details><summary><strong>Layered directory map</strong></summary>

```text
src/
  api/                   Public adapters and types
  core/
    geometry/            Bounds and exact predicates
    packing/             STR ordering and page arithmetic
    index/               Storage, traversal and analysis
    stats/               Diagnostics and integrity checks
  extensions/
    trajectory/          Time windows and sequence operations
    geofence/            Stateful fence events
    polygon/             Polygon operations and indexing
  support/generator/     Deterministic test data
  bridge/browser/        JS host boundary for the demo
tests/api/               Root API compatibility and regressions
playground/src/          React interface, worker and adapters
docs/en/ and docs/zh/    Separate language editions
```

</details>

Root API names remain available. Geometry types are re-exported from `src/core/geometry` and opaque index adapters live in `src/api`; direct imports of former internal package paths must migrate. The [roadmap](docs/en/ROADMAP.md) separates implemented work from future measurements.

## For developers and agents

| Document | Purpose |
| --- | --- |
| [Architecture](docs/en/ARCHITECTURE.md) | Package dependencies and source ownership |
| [API](docs/en/API_SPECIFICATION.md) | Query and storage semantics |
| [Development](docs/en/DEVELOPMENT.md) | Commands and toolchain setup |
| [Validation](docs/en/VALIDATION.md) | Executed tests and retained measurements |
| [Specification](docs/en/SPEC.md) | Behavioral invariants |

Apache-2.0. See [LICENSE](LICENSE).

## CI and licenses

[CI](.github/workflows/ci.yml) checks, builds and tests Wasm, Wasm GC, JavaScript and Native, runs the CLI example, and tests/builds the browser. Runtime dependency and font notices are distributed with the showcase. Publishing to mooncakes is outside this checkpoint.
