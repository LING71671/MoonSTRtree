# Direct MoonBit spatial-index comparison

[English](README.md) | [中文](README.zh.md)

This separate module compiles the current local MoonSTRtree and pinned `totto2727/geo@0.1.3` into one JavaScript release artifact with one MoonBit toolchain. `moon.work` resolves MoonSTRtree from the repository, not the older registry release. The main library does not depend on geo, and `/playground/` is excluded from registry publication.

Run from `playground`, with moonc 0.10.18 or newer, Node, Bun and pnpm installed:

```powershell
moon update
pnpm benchmark:data
pnpm benchmark:geo --profile=diagnostic --output=.bench/reports/geo-diagnostic-new.ndjson
pnpm benchmark:geo --profile=standard --output=.bench/reports/geo-standard-new.ndjson
pnpm benchmark:geo:publish --input=.bench/reports/geo-standard-new.ndjson --output=../docs/evidence/geo-standard-new.json
```

Every run requires a new filename. The publisher rejects incomplete matrices, duplicate cases, invalid medians, unpinned public data and invented unsupported scores. It regenerates each input and query to check geometry hashes and actual query parameters, then retains a gzip copy of every raw observation.

## Protocol

- Capacity is 16 for both implementations, matching geo's fixed maximum node entries. The standard profile declares 4,640 cases: ten synthetic distributions and two extreme distributions at 1,000/10,000/100,000 objects and seeds 0/42/2026, two pinned public datasets at all three seeds, plus empty and singleton inputs. Each input has 38 existing query variants and two additional touching-boundary cases. Diagnostic uses 640 cases, not final performance scores.
- Construction includes each library's ingestion from the same flat coordinate input, one warmup and nine rotated samples. Ordinary queries own their returned arrays; the benchmark does not give MoonSTRtree reusable-buffer queries while forcing the other library to allocate results.
- Standard queries use 16 warmups and nine rotated batches, with per-provider iterations calibrated toward 5ms. This protocol is recorded separately from the four-provider website benchmark. Long individual queries may exceed the target duration.
- geo uses its specialized `query_nearest` for k=1 and its native `nearest_neighbors` for other k. Complete ordered squared-distance sequences are checked before and after timing; tied IDs can differ. Other queries require the full exact ID set with no duplicate or out-of-range IDs. Native k<=0 and k beyond the input count are checked in integration tests, without using no-neighbor requests to inflate speed scores.
- Segment queries are measured for MoonSTRtree and retained as unsupported for geo in this bridge, without a score. Paired speed uses only the common valid cohort; all selected/unsupported/error counts and slower cases remain visible. Build observations are counted once per input, not once per query.

## Scope

Identical bounds, nested bounds, all hits, no hits, touching boundaries, empty trees and tied nearest results are explicit cases. They do not establish zero allocation, zero GC, fixed latency or a memory bound. Public longitude/latitude is treated as planar degrees, not geodesic distance.

This is a direct 2D JavaScript comparison. It does not establish native, Wasm, 3D/4D or memory performance. Different algorithms and API contracts are disclosed, not normalized into a claim of universal superiority. The main four-provider website report remains an independent source snapshot.

The registry dependency declares the MIT license, copyright 2026 totto2727. Its downloaded license remains with the local package. Dependency source and the compiled comparison artifact are not vendored or distributed by this repository; retain the dependency notices if distributing that artifact separately.
