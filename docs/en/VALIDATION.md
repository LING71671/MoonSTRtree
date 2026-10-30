# Validation record

[English](VALIDATION.md) | [中文](../zh/VALIDATION.md)

The current checkpoint was checked on Windows on 2026-10-30 with `moonc v0.10.18+6c83a7f62 (2026-10-28)` and `moon 0.1.20261028 (e1e1f15 2026-10-28)`. Historical measurements below retain their own source, toolchain and adapter records. This records tested cases, not a proof of universal correctness or speed.

## Packed circle leaf traversal, 2026-10-21

The [complete targeted summary](../evidence/circle-leaf-2026-10-21.json) and [raw samples](../evidence/circle-leaf-2026-10-21.json.ndjson.gz) retain all 2,592 cases, completed in 748.271 seconds with zero answer-validation failures. The frozen before core comes from `fcbb22233db4b433f7d5ba2b6be737892edb9543`; the after core is clean commit `b4c4b5ba8c1fc74303a7a8f6241a3c5d7d50a566`. Both compile with moonc 0.10.14 and run together under Node 22.22.1 on the same Intel i7-14650HX Windows host. Core and frozen-artifact hashes remain in the report.

| Node capacity | Cases | Before / after geometric speed | After relative to Flatbush | After relative to RBush |
| --- | ---: | ---: | ---: | ---: |
| All | 2,592 | 1.6068x | 1.0877x | 1.6126x |
| 4 | 864 | 1.4563x | 1.1188x | 1.6079x |
| 16 | 864 | 1.6469x | 1.1171x | 1.6117x |
| 64 | 864 | 1.7296x | 1.0297x | 1.6184x |

Ratios use equal case weights in the common valid five-provider cohort; above 1 means the after core is faster. The descriptive 5% band retains 2,568 faster, 17 close and seven slower cases against the before core. Mixed bounds, slender bounds and public airports remain slower than Flatbush at 0.8376x, 0.9744x and 0.8069x. The 100,000-object cohort scores 0.9926x relative to Flatbush. No slower case was removed; this targeted result is not a replacement for the full website ranking.

Only branch nodes enter the packed circle traversal stack. Validated homogeneous leaf pages compute box-to-point squared distances and write matching IDs directly, without per-leaf push/pop or new index columns. Other restored topologies retain general traversal; circle counting is unchanged. Regressions compare complete results against independent clamped-point distances across six capacities, checked roundtrips, tangency, repeated IDs, empty/singleton trees and 4,097 coincident points. The mixed-depth restored fixture also verifies circle results. All four core targets pass 118 tests; the browser passes 100 tests / 637 assertions, the compiled geo bridge passes five tests / 405 assertions, and the production build passes. Public interfaces are unchanged.

The standard targeted matrix includes ten synthetic distributions at 1,000/10,000/100,000 objects, all valid pinned airport/runway records, capacities 4/16/64, seeds 0/42/2026 and nine radius/anchor combinations. Each implementation receives 64 warmups and nine rotated batches calibrated toward 3ms; independent complete ID sets are checked before and after timing. Construction is excluded. The publisher reconstructs the whole declared matrix and validates raw medians and completion. A 108-case diagnostic was used only to decide whether to broaden the run. This does not measure native/Wasm speed, 3D/4D performance, allocation, GC or runtime memory.

## Direct MoonBit geo follow-up, 2026-10-21

The [complete follow-up](../evidence/geo-circle-standard-2026-10-21.json) and [raw observations](../evidence/geo-circle-standard-2026-10-21.json.ndjson.gz) retain all 4,640 cases, completed in 1,024.864 seconds with zero answer failures. Clean source commit `b05f1ff66c5c1af9e7dff8a3e13de8b007a229e2` uses core SHA-256 `444dd9862a8d95a6ed69dc2b691929dea1a25f65bacff7169c172540400cef0e`. The bridge, pinned geo 0.1.3 source, compiler and protocol are unchanged from the earlier comparison below: one JavaScript release artifact, capacity 16, 16 query warmups and nine rotated batches targeting 5ms. The publisher checked the complete matrix and regenerated every input hash and exact query parameter.

| Query | Common valid cases | MoonSTRtree relative to geo | Faster / close / slower |
| --- | ---: | ---: | ---: |
| All | 4,060 | 6.8254x | 3,562 / 129 / 369 |
| Rectangle | 1,508 | 8.2731x | 1,367 / 1 / 140 |
| Point | 464 | 1.4565x | 334 / 50 / 80 |
| Radius | 1,044 | 1.6277x | 947 / 61 / 36 |
| Nearest | 1,044 | 43.0687x | 914 / 17 / 113 |
| Segment | 0 | Not scored; 580 unsupported geo cases | 0 / 0 / 0 |

Construction counts 116 inputs once and scores 3.2752x. Radius queries over identical bounds score 1.3270x across 81 cases, with no slower cases; nested bounds score 1.3188x across 81 cases, also with no slower cases. Airport and runway radius subsets have 27 cases each and score 2.2182x and 1.5791x, retaining three and zero slower cases. These are radius-only subsets of the full retained matrix, not selected replacements for the aggregate.

The aggregate still requires API-specific interpretation: geo's specialized single-nearest API scores 1.3509x at k=1; native collection-and-sort k=10 and k=100 score 403.1862x and 146.6791x, with 348 cases per k. Empty and singleton all-query cohorts remain slower at 0.7973x and 0.8038x. All 369 slower paired queries and 580 unsupported cases remain visible. The 5% band is descriptive; no universal advantage is claimed.

The earlier geo run is retained separately. Differences between those independent runs are not used to attribute a speedup to this optimization; the same-process before/after circle comparison above supplies that evidence. Neither report replaces the four-provider website ranking or measures allocation, GC, native/Wasm or multidimensional performance. These development commits are newer than the published 0.2.2 package.

## Direct MoonBit geo comparison, 2026-10-20

The [complete summary](../evidence/geo-standard-2026-10-20.json) and [raw observations](../evidence/geo-standard-2026-10-20.json.ndjson.gz) retain 4,640 declared cases, completed in 872.125 seconds with zero answer-validation failures. Both libraries compile together with moonc 0.10.14 to JavaScript release, using capacity 16. MoonSTRtree resolves from clean local commit `42e1b5bc99a3249dbb0393e45615fa1f23d52b68`; the comparator is registry `totto2727/geo@0.1.3`. The report records both source hashes, bridge/artifact hashes, Node 22.22.1, V8 and the Intel i7-14650HX Windows host. This is a two-provider experiment, separate from the four-provider website ranking.

| Query | Selected / common valid | MoonSTRtree relative to geo | Faster / close / slower |
| --- | ---: | ---: | ---: |
| All | 4,640 / 4,060 | 5.8743x | 2,908 / 112 / 1,040 |
| Rectangle | 1,508 / 1,508 | 8.0073x | 1,369 / 0 / 139 |
| Point | 464 / 464 | 1.3844x | 323 / 20 / 121 |
| Radius | 1,044 / 1,044 | 0.9796x | 300 / 82 / 662 |
| Nearest | 1,044 / 1,044 | 42.8047x | 916 / 10 / 118 |
| Segment | 580 / 0 | Not scored; geo unsupported | 0 / 0 / 0 |

Ratios are equal-case geometric means of geo time divided by MoonSTRtree time; above 1 means MoonSTRtree is faster. The 5% band is descriptive, not a significance test. Construction includes ingestion and counts each of 116 inputs once, yielding 3.1551x. Losses remain visible: radius is slightly slower in aggregate, with 662 slower cases; empty and singleton query cohorts score 0.7595x and 0.8266x. This does not establish universal superiority.

Nearest results must be interpreted by API: geo uses its specialized `query_nearest` for k=1, scoring 1.3493x across 348 cases. For k=10 and k=100 it uses native `nearest_neighbors`, which collects and sorts all entries; these score 403.0468x and 144.2181x across 348 cases each. These algorithm differences explain much of the nearest aggregate. No slower replacement for geo's specialized single-nearest API or no-neighbor requests contributes to that score.

The matrix contains ten synthetic distributions plus identical/nested bounds at 1,000/10,000/100,000 objects and seeds 0/42/2026; all 86,231 pinned airport records and 15,557 valid runway bounds at all three seeds; and empty/singleton inputs. Each input has 40 variants, including all-hit, no-hit and touching-boundary queries. Identical and nested bounds each have 360 selected / 315 paired cases, scoring 3.9817x and 4.1967x; they retain 116 and 118 slower cases. Public inputs have 240 selected / 210 paired cases, scoring 9.2422x. Longitude/latitude remains planar degrees. The report preserves exclusions and source-file hashes.

Both providers use ordinary result-owning APIs. Queries have 16 warmups and nine rotated batches calibrated toward 5ms; construction has one warmup and nine rotated samples. Complete ID sets, or exact ordered nearest-distance sequences allowing tied IDs, are checked against an independent exhaustive reference before and after timing. All 580 unsupported geo segment cases remain in coverage with no paired score. The publisher verified the complete matrix, raw medians and source pins, then regenerated every input hash and exact query parameter. See the [reproduction protocol](DEVELOPMENT.md#direct-moonbit-geo-comparison).

Local checks passed 100 regular tests / 637 assertions, five compiled bridge tests / 405 assertions, the production build, `moon check`, `moon info` and `moon fmt`; main-library interfaces are unchanged. Bridge tests also cover native k<=0, k beyond the input count and multilevel coincident bounds. Fresh CI initializes the Mooncakes registry with `moon update` before resolving the comparator. This experiment does not measure allocation, GC, peak memory, native/Wasm speed or 3D/4D performance. Full overlap still requires output-proportional work; real multidimensional application cases remain planned.

## Nearest frontier optimization, 2026-10-15

The [complete targeted comparison](../evidence/nearest-frontier-2026-10-15.json) and [raw samples](../evidence/nearest-frontier-2026-10-15.json.ndjson.gz) retain all 2,592 nearest cases, completed in 629.755 seconds with zero answer-validation failures. The frozen before core comes from `d6f874b73dbd647f66f5da4dfb1867d08eadcf9a`; the after core is clean commit `2697fd319edec511325be8f1b6ac05bb90834874`. Both use moonc 0.10.14 and Node 22.22.1 on the same Intel i7-14650HX Windows host. Core and frozen-module hashes are retained in the report.

| Neighbors | Cases | Before / after geometric speed | After relative to Flatbush | After relative to RBush |
| --- | ---: | ---: | ---: | ---: |
| All | 2,592 | 1.3662x | 0.8876x | 1.0507x |
| 1 | 864 | 1.3976x | 0.7572x | 0.9919x |
| 10 | 864 | 1.3630x | 0.9851x | 1.0550x |
| 100 | 864 | 1.3386x | 0.9373x | 1.1084x |

The descriptive 5% band retains 2,521 faster, 32 close and 39 slower cases relative to the before core. Public airport and runway subsets remain slower than both competitors: after / Flatbush ratios are 0.7270x and 0.8322x; after / RBush ratios are 0.6870x and 0.8252x. No losses were removed. This same-process result measures the combined traversal changes, not isolated contributions or universal superiority.

The frontier uses a four-way minimum heap and returns a node ID without allocating a distance/node pair for each removal. Traversal checks the minimum distance before removing the node, avoiding an unnecessary final sift when pruning ends the search. The candidate maximum heap, result distances, predicate semantics and public interfaces are unchanged. An independent sorted reference exercises interleaved frontier insertions/removals and equal distances; complete 2D and filtered 3D nearest regressions remain.

The standard targeted protocol uses ten synthetic distributions at 1,000/10,000/100,000 objects, every valid pinned public input, capacities 4/16/64, seeds 0/42/2026 and k 1/10/100. Each provider receives 64 warmups and nine rotated, calibrated 3ms batches. Full independent distance sequences are checked before and after timing; tied IDs may differ. The summarizer reconstructs the declared matrix and verifies raw medians, identities and completion. A preliminary 108-case diagnostic was used only to decide whether to expand the experiment. Core checks pass 116 tests on each of four targets, browser integration passes 94 tests / 610 assertions, and the production build passes. The website's complete 10,944-case matrix below remains its own earlier snapshot; this targeted result does not replace it or establish 3D speed, native speed, construction speed or runtime memory savings.

## Latest full standard matrix: 0.2.1

The [0.2.1 summary](../evidence/standard-0.2.1-2026-10-12.json), [complete case report](../../playground/public/benchmarks/standard-0.2.1-2026-10-12.json) and [raw batch samples](../../playground/public/benchmarks/standard-0.2.1-2026-10-12.ndjson.gz) retain all 10,944 cases, with zero result-validation failures, completed in 3,233.887 seconds. The publisher independently reconstructed every declared input/capacity/seed/query identity and verified raw medians, unique cases, public dataset hashes and the completion footer. The website manifest now selects this report; the earlier full report remains available below.

| Query | Cases | Relative to Flatbush | Relative to RBush | Relative to optimized scan |
| --- | ---: | ---: | ---: | ---: |
| All queries | 10,944 | 0.8921x | 1.1724x | 14.6857x |
| Rectangle | 3,168 | 1.0741x | 1.7097x | 12.6962x |
| Point | 1,152 | 1.1982x | 1.4326x | 111.3177x |
| Nearest neighbors | 2,592 | 0.5697x | 0.6687x | 18.4589x |
| Radius | 2,592 | 1.0225x | 1.1817x | 10.2099x |
| Segment | 1,440 | 0.8215x | 1.1798x | 5.1011x |

Each ratio is the geometric mean of competitor time divided by MoonSTRtree time, with equal weights across the same valid four-provider cohort. Above 1 means MoonSTRtree is faster. Construction is counted once per unique index: 288 configurations yield 0.5232x relative to Flatbush and 1.9088x relative to RBush, including input adaptation. Against Flatbush, the descriptive 5% band retains 4,033 faster, 815 close and 6,096 slower queries. Public data alone has 684 cases and a 0.8098x query ratio against Flatbush. Nearest, segment and construction remain measured gaps; no universal advantage is claimed.

This is a clean-source 2D planar JavaScript observation of commit `02f7d508527f88b0a062746bd55c87538988ae0a`, core SHA-256 `b73a428fb8c7efdfc42e7f4c3e151916eb4ab0559ab51a21b410e5652bf92643`, using moonc 0.10.14, Node v22.22.1 / V8 12.4.254.21-node.35, Windows and Intel i7-14650HX. Each query has 64 warmups and nine rotated batches calibrated toward 3ms, with complete independent oracle checks before and after timing. The matrix includes ten synthetic distributions at 1,000/10,000/100,000 objects and all valid pinned OurAirports records, capacities 4/16/64 and seeds 0/42/2026. It does not measure runtime memory, native performance or 3D/4D speed. Separate before/after comparisons below use their own recorded protocol and are not substituted into this full ranking.

Publication preparation passed `pnpm build`, `moon info` and `moon fmt`, with no interface changes. The local production browser loaded all 10,944 cases with the 0.89x query score and 288 construction configurations with the 0.52x build score. Selecting public data retained all 684 cases; switching from Chinese to English preserved the selection and values. The raw download points to the complete 0.2.1 NDJSON gzip, and no application alerts occurred. Remote CI and Pages checks are separate from these local checks.

## Core checks

| Command | Result |
| --- | --- |
| `moon info`, `moon fmt`, `moon check` | Interfaces regenerated, formatting completed, check passed |
| `moon test --target wasm` | 118 passed, 0 failed |
| `moon test --target wasm-gc` | 118 passed, 0 failed |
| `moon test --target js` | 118 passed, 0 failed |
| `moon test --target native` | 118 passed, 0 failed |

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

## Earlier browser integration

The first refactor inventory preserved public type/function/method names. The current checkpoint additionally exposes coordinate ingestion and canonical geometry aliases. Geometry types belong to core/geometry, index adapters belong to api, and internal fields are private. These source changes do not claim binary compatibility.

`pnpm test`: 90 passed, 0 failed, 593 assertions. Ten synthetic distributions cover all five 2D query modes; 100,000-object queries and separate 3D/4D bridge cases also run. Flatbush 4.6.2 uses its built-in leaf filter, RBush 4.0.1 uses rbush-knn 4.0.0 for nearest search, and the timed linear scan uses direct coordinate access and a bounded nearest heap. An independent exhaustive scan/full sort supplies the oracle, rather than the timed baseline.

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

The first expanded diagnostic runner completed 456 cases with zero result mismatches: ten synthetic datasets and two pinned public datasets, 38 query variants each, capacity 16 and seed 42. Its short three-batch diagnostic timings are not final benchmark scores. The standard profile has now completed 10,944 cases. Memory profiling, multidimensional performance and further speed improvements remain work in progress; the new charts expose the full measured matrix.

Public snapshots contain 86,231 airport records with no coordinate exclusions, and 15,557 runway endpoint bounds with 32,779 excluded incomplete/invalid endpoint rows. Both use all valid records from a pinned OurAirports commit, checked SHA-256 files, disclosed exclusions and deterministic shuffling. Longitude/latitude is treated as planar coordinates in degrees, not geodesic distance. See playground/benchmarks/data/sources.json and the reproducible fetch script.

The separate browser volume section validates real 3D height queries and 4D time slices with a complete independent scan. It displays XY/XZ projections and previews ten rows; its export retains every matching ID and bound. It is functionality evidence, not a multidimensional performance ranking.

Playwright exercised the current production volume controls: the default 1,000-object 3D query returned 98 matches, the 4D slice at 500 returned 12, and moving the slice to 750 returned 16. Each complete result matched the reference. Switching to English preserved heights 350–650 and time 750. All three sliders have accessible names.

CI is configured to check, build and test four targets and test/build the browser, with an explicit minimum moonc 0.10.18 gate. The [current remote CI](https://github.com/LING71671/MoonSTRtree/actions/runs/38184546848) passed all five jobs after the checkpoint push. The Apache-2.0 project license and runtime dependency/font notices are retained. Mooncakes publication is excluded by the user's acceptance scope.

The current compiler-0.10.14 diagnostic artifact is [preserved as gzip NDJSON](../evidence/benchmark-diagnostic-2026-10-11.ndjson.gz): 456 completed cases, no mismatches. It includes source/compiler fingerprints and each raw batch.

## Standard matrix and 4D identity regression, 2026-10-12

The [complete standard report](../../playground/public/benchmarks/standard-2026-10-12.ndjson.gz) completed 10,944 cases with zero mismatches in 2,400.734 seconds. It measures clean source commit `f6972ca206a1010a7c6d58a12aa70bdaf503d388` using moonc 0.10.14, Node v22.22.1 / V8 12.4.254.21-node.35 on Windows and an Intel i7-14650HX. The publisher independently reconstructed the declared matrix and checked every sample median, unique identity and completed case. Ten synthetic distributions and two pinned public inputs yield 96 input configurations and 288 indexes; construction samples rotate indexed-provider order nine times. See [reproduction commands](DEVELOPMENT.md#expanded-benchmark).

| Operation | MoonSTRtree geometric relative speed | Flatbush reference | Cases / indexes |
| --- | ---: | ---: | ---: |
| All queries | 0.7731x | 1x | 10,944 |
| Rectangle | 1.0535x | 1x | 3,168 |
| Point | 0.6032x | 1x | 1,152 |
| Nearest neighbors | 0.4205x | 1x | 2,592 |
| Radius | 1.0438x | 1x | 2,592 |
| Segment | 0.8320x | 1x | 1,440 |
| Ingest + build | 0.4981x | 1x | 288 |

Scores use equal case weights and a common valid cohort. They do not establish universal superiority: MoonSTRtree remains slower overall than Flatbush. The paired 5% band counts 3,343 faster, 670 close and 6,931 slower queries against Flatbush. Nearest, point and construction are the next optimization priorities. All slower cases remain in the raw report and browser view. No runtime-memory or multidimensional-speed claim is made.

Separately, the old 4D builder matched child identity using ID and only lower coordinates. Internal nodes share ID -1, so coincident branch bounds linked to the wrong level. A 64-record case returned 16 hits with only 4 distinct IDs. [Before evidence](../evidence/4d-identity-before-2026-10-12.json) and [after evidence](../evidence/4d-identity-after-2026-10-12.json) preserve the actual compiler/core fingerprints and IDs. The builder now retains explicit node indices, uses standard O(n log n) sorts with safe midpoint arithmetic, and records levels when creating nodes. It returns all 64 IDs; added regressions cover repeated IDs with distinct upper bounds and exhaustive 10,000-object comparisons across capacities. Generated public interfaces are unchanged. The 4D fix follows the measured 2D snapshot; the UI discloses the snapshot difference.

Current checks pass: `moon check`, `moon info`, `moon fmt`, four targets with 111 tests each, native release build, and browser typecheck / 90 tests with 593 assertions / production build. Browser report interactions verify all 10,944 cases, a 684-case public subset, construction switching and locale-preserved filters. Final 1440/390 Chinese/English captures have loaded fonts and no document overflow; mobile tables scroll independently and their headings wrap outside the scroll containers. Finish review and Pages deployment are tracked separately.

## Reviewed deployment, 2026-10-12

Commit `d8ac98f5cc0c2a1fae7974b38dd01dafb48008f3` passed [CI](https://github.com/LING71671/MoonSTRtree/actions/runs/38184546848) and [GitHub Pages deployment](https://github.com/LING71671/MoonSTRtree/actions/runs/38184577184). The [published showcase](https://ling71671.github.io/MoonSTRtree/) returned HTTP 200 in a real browser, loaded all 10,944 benchmark cases with the expected score rows, and ran a real 4D query yielding 12 IDs matching the independent reference. The manifest and dependency/font notice file also returned HTTP 200. No application alerts occurred. This separately verifies deployment; a configured Pages REST response's null status was not treated as build evidence.

The first fresh finish-review agent was interrupted by a usage limit after identifying touching mobile 3D/4D labels. The fix sets a 16px gap and 44px button width. A fresh retry reviewed the four locale/viewport captures and readable crops; its full disposition was `fix` for stale design persistence only. The mandatory documenter corrected both design editions and sidecar; the subsequent scoped verdict was `Resolved`, remaining clear, disposition `ship`. This verdict covers that documentation repair, not deployment or the unavailable optional QUALITY BAR ceiling. Deployment was verified independently above.

Report loading was tested with a simulated HTTP 503: the visible retry recovered all 10,944 cases. A public-airport count filter selected 342 cases, and a phone viewport remained 390px wide without document overflow. README source-clone commands and the current CLI example were run without requiring a registry release.

## Nearest-candidate optimization and automatic interaction

The separate [nearest summary](../evidence/nearest-heap-2026-10-12.json) retains a [complete raw gzip report](../evidence/nearest-heap-2026-10-12.json.ndjson.gz). All 2,592 nearest cases completed in 638.161 seconds with zero mismatches. Clean commit `db38b916e159d88c80b42e9bd48134fa7c375910` records the same-process comparison of frozen before/after cores using moonc 0.10.14, Node 22.22.1, capacities 4/16/64, seeds 0/42/2026 and k 1/10/100. Each provider has 64 warmups, calibrated 3ms batches and nine rotated observations. An independent full sort validates exact squared-distance sequences before and after timing, allowing different IDs only at equal distances.

| Neighbors | Cases | Before / after geometric speed | After relative to Flatbush |
| --- | ---: | ---: | ---: |
| All | 2,592 | 1.3747x | 0.6526x |
| 1 | 864 | 1.0022x | 0.5420x |
| 10 | 864 | 1.1407x | 0.7311x |
| 100 | 864 | 2.2725x | 0.7013x |

The descriptive 5% band retains 1,646 faster, 802 close and 144 slower cases relative to the old implementation. k=1 remains effectively neutral. This targeted run does not replace the full published matrix, establish superiority to Flatbush or measure multidimensional performance. The summary independently reconstructs every input/capacity/seed/workload identity and validates raw sample medians and completion totals. Its 3ms duration is explicitly recorded; the current comparison CLI retains a 12ms default with an explicit override.

The automatic production browser build passed typecheck, 91 adapter tests with 595 assertions and Vite build. Real browser changes updated complete hit counts from 527 to 48 when reducing objects to 1,000, then to 45 for uniform data. Rapid mode changes ended at Radius with current valid timings; rapid dataset changes ended at 1,000 grid objects with seed 7. Invalid seed input was marked and did not replace the dataset. Language switching preserved timings. Four locale/viewport captures loaded fonts and had document widths equal to 1440/390px, with no application alerts.

A local automated 40-step drag over 100,000 clustered objects (seed 42, capacity 16, displayed depth 1) compared the deployed manual version with the new production build in the same browser and viewport. Frame-interval median / P95 changed from 170.9 / 325ms to 4.2 / 4.3ms; observed main-thread tasks over 50ms changed from 36 to 0. The final query returned 68,716 matching IDs in all implementations. These are single local automated observations, not field INP, a mobile-device measurement or a guaranteed frame rate. Cached object rendering and 60ms worker coalescing remove per-pointer full-object redraw and scan queues; timing starts after 350ms of settled interaction.

The selected image-generated mark and 2172x724 banner are inspected. All seven shipped rasters embed their exact prompts; the provenance scan reports zero missing entries. The symbol is used by header/footer, explicit 16/32px favicons and a 180px touch icon. Earlier Mooncakes exclusions above describe the previous checkpoint; the user subsequently authorized version updates, registry publication, tags and releases.

Final preparation for 0.2.0: the lean archive was extracted and all 113 JS tests passed. Root Wasm, Wasm GC and Native also passed 113 tests each; public interfaces have no unexpected diff. Summary corruption checks rejected an omitted case with adjusted footer counts, a duplicate case, and an altered raw median before writing any output. A hidden-canvas resize guard fixes a zero-dimension draw error; hidden/restored canvas, alternating mobile/desktop widths and reload produced no page errors and retained four automatic measurements. Finish review scored the persistence and English mobile legend repairs Resolved, remaining clear for those two repairs, disposition ship. The first documenter hit a usage limit after partial writes; a fresh retry completed and verified persistence. This scoped verdict does not certify an optional QUALITY BAR or external publication.

## Version 0.2.0 publication

Version 0.2.0 was published with `moon publish` (server 200 OK, exit 0). [Release evidence](../evidence/release-0.2.0.json) records the source commit, registry record, checksum and smoke-test output. Registry checksum `53ae57f3a71387586d6a95e234b125b607da4bf3cf905954dbfefacfa8157b0c` matches both the local 415,410-byte ZIP and the [GitHub release asset](https://github.com/LING71671/MoonSTRtree/releases/tag/v0.2.0). The annotated tag resolves to `01cb9fe5272f1a4e248c9221403491bc95196242`.

A fresh consumer installed `LING71671/moon_strtree@0.2.0` from the registry, ran the README-style range example and a two-neighbor query, and returned IDs 101 and then 102/101 as expected; its Wasm check passed. This confirms registry consumption, not a local path dependency. Temporary portable-SDK publishing credentials were removed; the user's original credentials were retained.

All five [CI jobs](https://github.com/LING71671/MoonSTRtree/actions/runs/38208463065) and both [Pages jobs](https://github.com/LING71671/MoonSTRtree/actions/runs/38208508510) passed for that exact commit. The deployed page applied a count change automatically, returned 48 objects consistently across all providers, loaded the generated mark and HTTP-200 favicon, and loaded all 10,944 static benchmark cases. The observed page-error array was empty. Publication is verified independently from the scoped visual-review verdict.

## Volume interaction follow-up

The user reported lag in the 3D/4D projections after the 0.2.0 release. [Retained interaction observations](../evidence/volume-interaction-2026-10-12.json) separate measured symptoms from implementation evidence. A 40-step local drag at a 2482px CSS viewport/DPR1 produced 202 XZ width assignments and 41 query requests before the change. With 10,000 objects, frame-interval P95 was 33.5ms and three long tasks were observed; afterward P95 was 4.3ms, no long tasks were observed, width assignments were zero and query requests were two. The 1,000-object baseline did not reproduce equally severe lag locally; its P95 changed from 4.4 to 4.3ms. These are single local observations with automation-dependent gesture duration, not field INP or a claim about the user's exact device pixel ratio.

The shared canvas scheduler observes each mounted surface once and coalesces resize/state invalidations into one animation frame. XZ static bounds are cached, unchanged backing dimensions are retained, and hidden canvases are skipped. Volume queries use a trailing 60ms throttle: continuous gestures still send the newest query each window. Rebuilding cancels the queue; instance, request and query/data identity checks prevent stale highlights, answers and exports. The volume component is independent of unrelated 2D progress renders.

Typecheck/production build and 94 browser tests with 610 assertions passed. New tests verify latest-query coalescing without starvation, cancellation/reuse, unchanged backing dimensions and hidden-box handling. Real browser checks retained default 3D 98 hits, 4D time500 12, time750 16 and time1000 0, each complete answer matching the reference. Time750 export retained all sixteen bounds and IDs. Keyboard height controls, rapid dimension/count changes, reselecting the same count and mobile dragging passed without page errors or document overflow. Desktop/mobile Chinese/English and the reported-width captures retain the visual system. The shared 2D canvas remains covered by the existing real-query tests.

The fresh finish review identified one interaction-verification gap after passing the visual/fidelity checks. It is now closed: twelve before/after observations additionally cover the 3D height slider, 4D XY drag and 4D time slider at both supported object counts. Six paired exports have identical final queries and complete sorted ID sets; every exported bound and full-oracle flag was validated. At 10,000 objects, P95 was 37.6/25.1/29.2ms respectively before and about 4.3ms after. The 1,000-object time-slider result stayed about 4.4ms and is retained. Before/after exports report the same moonc 0.10.14 and core SHA-256 `39a155fc525baacfb68a36f6477cd75b449214a6fd1a90f0e3afb5d7dde99a5e`, isolating this renderer/scheduling change from a core/compiler update.

The initial fresh reviewer failed at capacity after partial inspection; its fresh retry returned a complete `fix` review for that verification gap. A capacity interruption delayed the verdict pass; retry scored the one finding `Resolved`, remaining clear, disposition `ship`. This scoped verdict covers the verification repair and local patch, not a whole-surface approval, user-specific 1,000-object responsiveness, optional QUALITY BAR or deployment. The original twelve visual captures remain valid because completing the evidence did not alter the interface.

## Packed point traversal and restoration correctness, 0.2.1

The CPU profile of a frozen 0.2.0 core attributed most point-query time to packed range traversal and its query-into wrapper. A dedicated scalar point traversal removes the temporary rectangle, range normalization and general covering tests without adding index columns. Built homogeneous pages retain the fast path; arbitrary valid restored topologies retain the general path.

Before changing the layout hint, a new regression against the old source reproduced a missing checked-restoration result: the valid mixed-depth tree accepted by restoration returned ID31 for point(5,5), omitting ID47. [Regression evidence](../evidence/point-restoration-regression-2026-10-12.json) contains the complete reproducible buffers. The hint now verifies homogeneous child pages and full leaf coverage; point and partial-range queries return both IDs. Core tests cover 10,000 rectangles across five capacities, inclusive boundaries, repeated IDs, coincident point bounds, empty trees and non-finite query coordinates. All four targets pass 115 tests each; public interfaces have no unexpected change. Web tests remain 94/610 assertions and the production build passes.

The [complete point comparison](../evidence/point-traversal-2026-10-12.json) retains its [raw batches](../evidence/point-traversal-2026-10-12.json.ndjson.gz): 1,152 cases, zero mismatches, 249.190 seconds, clean source commit `a4d20f797ace3932afa0711a4446e7c569dea857`. It uses the standard counts/capacities/seeds, all valid pinned public inputs, four point variants, 64 warmups and nine rotated 3ms batches, checked against complete independent IDs before and after timing. Compiler 0.10.14 and Node22.22.1 are shared by the frozen before and current after cores. Summary publication reconstructs the declared matrix and checks every sample median and completion total.

| Point-query cohort | Geometric relative speed |
| --- | ---: |
| New / old core | 1.8978x |
| New / Flatbush | 1.1359x |
| New / RBush | 1.4139x |
| New / timed linear scan | 87.4664x |

The descriptive 5% band retains 1,073 faster, 68 close and 11 slower cases against the old core. The public-airport subset remains 0.8510x relative to Flatbush; slender bounds remain 0.8888x, grids 0.9681x and point objects 0.9985x. This improvement is not universal and does not replace the complete website matrix or establish construction, nearest, memory, native or multidimensional superiority. The short 48-case diagnostic was used only to decide whether to broaden the experiment; the table uses the full 1,152-case comparison.

Separately, renderer commit `8960439` and documentation commit `42a7024` passed [CI](https://github.com/LING71671/MoonSTRtree/actions/runs/38213455040) and [Pages](https://github.com/LING71671/MoonSTRtree/actions/runs/38213500921). The deployed 4D drag returned thirteen fully validated IDs with zero XZ width assignments during the gesture and no application alerts. This verifies that the renderer patch reached Pages; it does not establish the user's device-specific 1,000-object latency.

## 0.2.1 publication verification

`moon publish` returned200 OK/exit0 for0.2.1. [Release evidence](../evidence/release-0.2.1.json) preserves source/tag/registry and checksums. The425,868-byte archive, registry record and uploaded [GitHub ZIP](https://github.com/LING71671/MoonSTRtree/releases/tag/v0.2.1) share SHA-256 `63c0dff8cd63f4f0d0675e872ac1834a584201020fb2345bed933ec5ffd34c1f`.

A fresh registry consumer verified point ID101, nearest IDs102/101, and checked roundtrip of a public opaque snapshot with ID101; its Wasm check passed. Consumer buffers are opaque: an attempted direct record fixture was corrected to the supported public roundtrip. The mixed-topology fixture was then executed successfully as the downloaded package's own white-box regression. This distinguishes consumer API validation from internal raw-layout validation.

[CI](https://github.com/LING71671/MoonSTRtree/actions/runs/38217009369) and [Pages](https://github.com/LING71671/MoonSTRtree/actions/runs/38217055895) passed for release commit `ff2af4dd93b0bdc7fae840eef14aa4ddf1046b61`. The live point-query export reports the measured after-core SHA-256 `b73a428fb8c7efdfc42e7f4c3e151916eb4ab0559ab51a21b410e5652bf92643`; all four complete answers match and each retains nine raw batches. The standard website snapshot remains separately identified and is not replaced with a point-only score.

## 0.2.2 publication verification

`moon publish` returned 200 OK and exit 0 for 0.2.2. The [release record](../evidence/release-0.2.2.json) links the registry, annotated tag and [GitHub release](https://github.com/LING71671/MoonSTRtree/releases/tag/v0.2.2) to commit `7c2810a15c98d6ae730fe3882e72fce10021a2fc`. The 437,291-byte ZIP contains 145 files; its SHA-256 `46e536fc0d900626813bdb6c62c5a014b3c435f033f34551519eb8d10fd85d6b` matches the refreshed registry record and GitHub asset digest. The archive excludes the playground, benchmark evidence, private proposal, credentials and build output. Its extracted sources pass 116 JS tests and a Wasm check.

A fresh project installed `LING71671/moon_strtree@0.2.2` from the registry. Both JS and Wasm runs passed 2D range/point/nearest and checked snapshot restoration, multilevel 3D nearest, 4D time filtering and a 64-object coincident-bound query. The downloaded manifest and nearest sources match the ZIP. Public interfaces are unchanged. [CI](https://github.com/LING71671/MoonSTRtree/actions/runs/39406010929) and [Pages deployment](https://github.com/LING71671/MoonSTRtree/actions/runs/39406080513) passed for the exact release commit; deployment success is not a new interactive performance measurement. Release, tag and push identities were verified as LING71671. Temporary portable-SDK credentials were removed, retaining the original credentials.

The preflight server returned 202 Accepted with a successful dry-run message, which this installed `moon` reports as exit 1. That response made no publication changes; the actual publish subsequently returned 200 and exit 0. Performance reports above retain their measured source snapshots and scopes rather than being relabeled as new 0.2.2 measurements.
