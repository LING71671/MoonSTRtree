# MoonSTRtree

<p align="center"><img src="docs/banner.jpg" alt="MoonSTRtree spatial index" width="960" /></p>

<p align="center"><a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-555?style=flat-square" alt="Apache-2.0 license" /></a></p>

<p align="center">MoonBit static spatial indexes: 2D bounds, 3D volumes and 4D spacetime, with geometry and trajectory extensions.</p>

<p align="center"><a href="README.md">English</a> | <a href="docs/zh/README.md">中文</a> | <a href="https://ling71671.github.io/MoonSTRtree/">Live showcase</a> | <a href="#quick-start">Quick start</a> | <a href="docs/en/API_SPECIFICATION.md">API</a> | <a href="docs/en/ARCHITECTURE.md">Architecture</a></p>

Requires **moonc 0.10.18 or newer**. Run `moonc -v` to check the compiler rather than the `moon` CLI version.

## Quick start

```powershell
git clone https://github.com/LING71671/MoonSTRtree.git
cd MoonSTRtree
moon check
moon run cmd/main --target js
```

These commands verify the source checkout and run the CLI using the same package. To add version 0.2.3 to an existing MoonBit project:

```powershell
moon add LING71671/moon_strtree@0.2.3
```

Consumers use the following alias in their `moon.pkg`:

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
| [Changelog](docs/en/CHANGELOG.md) | Versioned changes and migration notes |

Apache-2.0. See [LICENSE](LICENSE).

## CI and licenses

STR packing follows Leutenegger, Lopez and Edgington's *STR: A Simple and Efficient Algorithm for R-Tree Packing* (1997). Engineering references include [JTS STRtree](https://github.com/locationtech/jts) and [Flatbush](https://github.com/mourner/flatbush). These established algorithms are not claimed as original inventions. The separate comparison module uses MIT-licensed [totto2727/geo](https://github.com/totto2727-org/geo); it is excluded from the published core package. Existing source copyright headers and the showcase's [dependency and font notices](playground/public/third-party-notices.txt) are retained.

[CI](.github/workflows/ci.yml) checks, builds and tests Wasm, Wasm GC, JavaScript and Native, runs the CLI example, and tests/builds the browser. Runtime dependency and font notices are distributed with the showcase. Version 0.2.0 adds a lean MoonBit distribution archive; the browser and benchmark artifacts stay in the repository. See [distribution commands](docs/en/DEVELOPMENT.md#distribution).

The [bilingual showcase](https://ling71671.github.io/MoonSTRtree/) runs real 2D/3D/4D queries and displays the full 10,944-case standard benchmark with raw samples. Query, construction, coverage and slower cases remain visible; the current results do not establish overall superiority to Flatbush. [Validation](docs/en/VALIDATION.md) records the measured source snapshot and deployment checks.
