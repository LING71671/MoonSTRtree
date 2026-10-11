# Development

[English](DEVELOPMENT.md) | [中文](../zh/DEVELOPMENT.md)

## Build and check

Use a current MoonBit toolchain. Run commands from the repository root:

```powershell
just verify
```

Without `just`:

```powershell
moon info
moon fmt
moon check
moon test --target wasm
moon test --target wasm-gc
moon test --target js
```

`moon info` regenerates package interfaces. Inspect interface diffs after moving types or adding APIs; this refactor changes type ownership and internal import paths while preserving root names. `moon fmt` is the formatter. Do not edit generated `.mbti` files.

## Native on Windows

MoonBit's Windows native target needs an MSVC-compatible C compiler and Windows SDK; MinGW is not a supported replacement. Use an installed Visual Studio Developer PowerShell with C++ headers and libraries available, then run `moon test --target native`.

This machine's newer Visual Studio compiler installation lacks its include directory. Native verification used the existing BuildTools 14.44 headers and libraries in a process-local developer environment. No system environment or SDK installation was changed. If `vcruntime.h` is missing, inspect the selected toolset before retrying; see [validation](VALIDATION.md).

## Work by ownership

| Change | Primary location |
| --- | --- |
| Public adapter | `src/api/` |
| Geometry and predicates | `src/core/geometry/` |
| STR sorting and page arithmetic | `src/core/packing/` |
| Storage / traversal / nearest-neighbor / joins | Matching files in `src/core/index/` |
| Geofence, polygon or trajectory behavior | Matching package under `src/extensions/` |
| Public compatibility regression | `tests/api/` |

Keep each dependency directed downward. The root file only re-exports API names. Preserve `///|` block separators and use `assert_eq` for stable numerical behavior. Add a regression that would fail on the old implementation when fixing a bug. For numerical operations, cover large and small scales, empty inputs and inclusive boundaries.

Public compatibility tests import the root package, exercising the same entry point as consumers. Package-local white-box tests inspect storage invariants. The regression suite includes 100,000 deterministic rectangles at several capacities and compares complete query results with linear scans. A passing suite establishes tested cases, not universal correctness.

## Playground and diagnostics

The `playground` package uses pnpm and Vite. Follow its package scripts:

```powershell
cd playground
pnpm install
pnpm dev
pnpm test
pnpm build
```

`pnpm engine` compiles the JS-only `src/bridge/browser` package and copies its exports and compiler metadata into ignored `src/.generated`. Both dev and build run this step. Bun executes adapter integration tests through `pnpm test`; browser automation uses Playwright. The UI, worker, data generator, query geometry and real provider adapters have separate ownership under `playground/src`. Query changes invalidate old measurements; configuration edits require an explicit rebuild.

`moon run cmd/main` prints diagnostic samples. It does not collect timing data. Browser comparisons use the actual compiled MoonBit implementation and real competitor packages, identical seeded inputs, warmups, repeated timings, and full result validation. Export raw measurements and environment details before making performance claims.

## Website languages

Complete website copy lives in `playground/src/i18n/en.ts` and `zh.ts`. The Chinese dictionary must satisfy the English dictionary's TypeScript shape. `LocaleProvider` owns the default Chinese selection, local persistence, document language/title/description and number formatting. Keep query state and measurements outside locale state so switching languages does not rebuild the experiment. Provider names and raw JSON field names remain stable for reproducibility; visible query paths and status text are translated. English uses self-hosted Barlow Condensed and Manrope, Chinese uses self-hosted Noto Sans SC.

## Documentation

Maintain separate English and Chinese files with reciprocal links. `README.md` is the module readme; `PRODUCT.md` holds durable product context. Architecture explains dependency and ownership rules; API explains semantics; validation records executed evidence; roadmap contains future work. Do not turn target latencies, estimated payload sizes or planned work into measured claims.

## Compiler requirement

Use moonc 0.10.14 or newer (`moonc -v`). Browser engine scripts enforce this minimum. A local ignored `.moon-toolchain.json` at the repository root may set `{ "home": "<portable SDK root>" }`, or set MOON_HOME; CI uses the installed SDK from PATH. The compiler version and source SHA-256 are exported with measurements.

## Expanded Benchmark

Run these commands from `playground`. Use a new output filename for each measurement: the runner refuses to overwrite evidence.

```powershell
pnpm benchmark:data
pnpm benchmark --profile=standard --output=.bench/reports/standard.ndjson
pnpm benchmark:publish --input=.bench/reports/standard.ndjson --output=public/benchmarks/standard.json
```

The standard matrix contains 10,944 cases: ten synthetic distributions at 1,000/10,000/100,000 objects plus all valid airport and runway records, capacities 4/16/64, seeds 0/42/2026 and 38 query variants. The diagnostic profile contains 456 short cases; exhaustive adds more scales, seeds and capacities. `--datasets=public`, `synthetic` or comma-separated dataset IDs selects an explicitly recorded subset.

Independent provider factories allow rotated construction order and keep other implementations running when one fails. One warm build precedes nine observed builds. Queries use 64 warmups, calibrated three-millisecond batches and nine rotated samples in standard mode; complete oracle validation happens before and after timing. Errors, mismatches and unsupported cases remain in the report. Header records include compiler, core and harness SHA-256, source commit, Node/V8 and host metadata; the footer confirms completion or records an aborted run.

The publisher verifies raw medians, unique case identities and the entire declared matrix before producing a compact JSON view, its SHA-256 manifest and a gzip copy of the complete NDJSON. Query scores use a common valid four-provider cohort and equal case weights; construction is counted once per input/capacity/seed. Failed and unsupported cases remain in coverage denominators. A 5% ratio band groups paired differences without claiming statistical significance. The website loads this static report on approach, verifies its checksum, and preserves filters during language changes. Avoid running other heavy workloads while measuring, and retain timing limitations.

## GitHub Pages

The Pages workflow builds the exact main-branch commit that passed CI and publishes `playground/dist`. Vite uses relative asset paths for repository hosting. Enable GitHub Actions as the Pages publishing source; the workflow requires the `github-pages` environment and deployment permissions. Benchmark inputs are not downloaded during site builds: committed reports are displayed as measured snapshots. CI does not regenerate performance scores on shared runners.
