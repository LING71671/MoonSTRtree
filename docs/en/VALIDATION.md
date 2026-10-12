# Validation record

[English](VALIDATION.md) | [中文](../zh/VALIDATION.md)

The current checkpoint was checked on Windows on 2026-10-12 with `moonc v0.10.14+7d59c7ec9 (2026-09-18)` and `moon 0.1.20260920 (914d7da 2026-09-20)`. Earlier measurements below used the previous toolchain and adapters. This records tested cases, not a proof of universal correctness or speed.

## Core checks

| Command | Result |
| --- | --- |
| `moon info`, `moon fmt`, `moon check` | Interfaces regenerated, formatting completed, check passed |
| `moon test --target wasm` | 113 passed, 0 failed |
| `moon test --target wasm-gc` | 113 passed, 0 failed |
| `moon test --target js` | 113 passed, 0 failed |
| `moon test --target native` | 113 passed, 0 failed |

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

CI is configured to check, build and test four targets and test/build the browser, with an explicit minimum moonc 0.10.14 gate. The [current remote CI](https://github.com/LING71671/MoonSTRtree/actions/runs/38184546848) passed all five jobs after the checkpoint push. The Apache-2.0 project license and runtime dependency/font notices are retained. Mooncakes publication is excluded by the user's acceptance scope.

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
