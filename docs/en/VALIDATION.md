# Validation record

[English](VALIDATION.md) | [中文](../zh/VALIDATION.md)

The current checkpoint was checked on Windows on 2026-10-11 with `moonc v0.10.14+7d59c7ec9 (2026-09-18)` and `moon 0.1.20260920 (914d7da 2026-09-20)`. Earlier measurements below used the previous toolchain and adapters. This records tested cases, not a proof of universal correctness or speed.

## Core checks

| Command | Result |
| --- | --- |
| `moon info`, `moon fmt`, `moon check` | Interfaces regenerated, formatting completed, check passed |
| `moon test --target wasm` | 108 passed, 0 failed |
| `moon test --target wasm-gc` | 108 passed, 0 failed |
| `moon test --target js` | 108 passed, 0 failed |
| `moon test --target native` | 108 passed, 0 failed |

Numerical regressions first reproduced integer-root overflow and inaccurate large/small-distance and trajectory-length results on the old implementation. Tests now cover integer roots at Int.MAX, large midpoint values, correct branch fill, reusable range buffers, sparse and duplicate IDs in compact DBSCAN, malformed persistence buffers, independent nearest-neighbor comparisons and complete range results over 100,000 objects at multiple capacities. Existing tests were retained and organized by domain.

Windows native verification used existing Visual Studio BuildTools 14.44 headers and libraries because the newer detected compiler installation lacks headers. The fix was process-local:

```powershell
$taskVc = 'C:/Program Files (x86)/Microsoft Visual Studio/2022/BuildTools/VC/Tools/MSVC/14.44.35207'
Import-Module 'C:/Program Files (x86)/Microsoft Visual Studio/2022/BuildTools/Common7/Tools/Microsoft.VisualStudio.DevShell.dll'
Enter-VsDevShell -VsInstallPath 'C:/Program Files (x86)/Microsoft Visual Studio/2022/BuildTools' -SkipAutomaticLocation -DevCmdArguments '-arch=x64 -host_arch=x64' | Out-Null
$env:INCLUDE = "$taskVc/include;" + $env:INCLUDE
$env:LIB = "$taskVc/lib/x64;" + $env:LIB
moon test --target native
```

## Browser integration

The first refactor inventory preserved public type/function/method names. The current checkpoint additionally exposes coordinate ingestion and canonical geometry aliases. Geometry types belong to core/geometry, index adapters belong to api, and internal fields are private. These source changes do not claim binary compatibility.

`pnpm test`: 78 passed, 0 failed, 441 assertions. Ten synthetic distributions cover all five 2D query modes; 100,000-object queries and separate 3D/4D bridge cases also run. Flatbush 4.6.2 uses its built-in leaf filter, RBush 4.0.1 uses rbush-knn 4.0.0 for nearest search, and the timed linear scan uses direct coordinate access and a bounded nearest heap. An independent exhaustive scan/full sort supplies the oracle, rather than the timed baseline.

`pnpm build` passed TypeScript checking and the production Vite build. Earlier Playwright checks operated all five modes, canvas dragging, arrow-key movement, a 100,000-object rebuild, measurement and downloaded JSON export. Every supported answer matched the exhaustive reference. Earlier desktop 1440 and mobile 390 captures showed no mobile document overflow. Those captures predate the monochrome layout and volume section and do not certify their layout.

## Historical measurement (superseded adapters)

The bilingual production build was also exercised in Playwright: Chinese and English translate headings, controls, hints, statuses and capability rows; switching preserves the active query, timing values and enabled export. Reload preserves the selected language. Both languages were captured at 1440 and 390 widths with settled self-hosted fonts. The default Chinese interface and locale-specific documentation links were checked. Website copy now uses concrete descriptive headings and connected explanations.

The [raw exported report](../evidence/browser-js-2026-10-11.json) preserves nine samples per provider, versions, timing method, query and browser environment. This observation uses 10,000 clustered synthetic rectangles, seed 42, capacity 16 and query `[380, 310, 570, 490]`. All four paths returned 527 objects.

| Provider | Median ms/query | Single ingest + build ms |
| --- | ---: | ---: |
| MoonSTRtree | 0.028125 | 38.20 |
| Flatbush | 0.006250 | 15.70 |
| RBush | 0.015625 | 13.30 |
| Linear scan | 0.087500 | 0.00 |

Flatbush won this particular query. Five warmups precede nine batches of 32 queries, rotating provider order per batch. Validation is outside timing; timing includes result construction and adapter filtering. Build times are single observations, not warmed medians. Browser timer resolution and scheduling can materially affect short queries. This historical report is not a current ranking. It predates the new packed construction, efficient competitor adapters and adaptive browser batches. No universal competitor advantage, multidimensional speed or runtime-memory advantage is established.

The Impeccable detector ran once using its degraded regex fallback because parser modules were unavailable. It returned no regex findings; that cannot certify computed contrast or selectors. Visual review evidence is local and ignored by Git.

## Current checkpoint coverage

Current browser measurement warms sixteen times, calibrates per-provider iterations toward twelve-millisecond batches, and rotates provider order across nine batches. Exports include actual iterations, package versions, compiler version and a source SHA-256. Construction time in the interactive ledger remains a single observation.

The first expanded diagnostic runner completed 456 cases with zero result mismatches: ten synthetic datasets and two pinned public datasets, 38 query variants each, capacity 16 and seed 42. Its short three-batch diagnostic timings are not final benchmark scores. The standard profile declares 10,944 cases; it has not yet been completed at this checkpoint. Broader timings, memory profiling, benchmark charts and Pages deployment remain work in progress.

Public snapshots contain 86,231 airport records with no coordinate exclusions, and 15,557 runway endpoint bounds with 32,779 excluded incomplete/invalid endpoint rows. Both use all valid records from a pinned OurAirports commit, checked SHA-256 files, disclosed exclusions and deterministic shuffling. Longitude/latitude is treated as planar coordinates in degrees, not geodesic distance. See playground/benchmarks/data/sources.json and the reproducible fetch script.

The separate browser volume section validates real 3D height queries and 4D time slices with a complete independent scan. It displays XY/XZ projections and previews ten rows; its export retains every matching ID and bound. It is functionality evidence, not a multidimensional performance ranking.

Playwright exercised the current production volume controls: the default 1,000-object 3D query returned 98 matches, the 4D slice at 500 returned 12, and moving the slice to 750 returned 16. Each complete result matched the reference. Switching to English preserved heights 350–650 and time 750. All three sliders have accessible names.

CI is configured to check, build and test four targets and test/build the browser, with an explicit minimum moonc 0.10.14 gate. Remote CI results will be known after this checkpoint is pushed. The Apache-2.0 project license and runtime dependency/font notices are retained. Mooncakes publication is excluded by the user's acceptance scope.

The current compiler-0.10.14 diagnostic artifact is [preserved as gzip NDJSON](../evidence/benchmark-diagnostic-2026-10-11.ndjson.gz): 456 completed cases, no mismatches. It includes source/compiler fingerprints and each raw batch.
