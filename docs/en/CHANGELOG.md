# Changelog

[English](CHANGELOG.md) | [中文](../zh/CHANGELOG.md)

## Unreleased

- Traverse validated 2D circle leaf pages directly and append matching IDs without leaf stack traffic. Keep general traversal for other restored topologies; public signatures, duplicate-ID retention and inclusive tangency are unchanged.
- Add exhaustive circle-result regressions across six capacities, checked snapshot roundtrips, empty/singleton inputs, repeated IDs and multilevel coincident bounds; extend the mixed-depth restoration regression to circle queries.
- Retain all 2,592 targeted circle cases with zero answer failures: 1.6068x relative to the frozen previous core, 1.0877x relative to Flatbush and 1.6126x relative to RBush. Seven slower cases relative to the previous core remain; mixed bounds and public airports remain slower than Flatbush. This does not replace the full website ranking.
- Repeat the unchanged 4,640-case direct geo protocol. All answers pass; the 1,044 paired radius queries score 1.6277x, with 36 slower cases retained. Identical/nested-bound radius subsets score 1.3270x/1.3188x. Keep the earlier report and unsupported paths; independent-run score differences are not a before/after speedup measurement.

## 0.2.2 — 2026-10-20

- Add an isolated direct comparison with pinned `totto2727/geo@0.1.3`, compiling both libraries with the same MoonBit toolchain and using native query APIs at capacity 16. Retain all 4,640 cases, including overlap boundaries and pinned public data: 4,060 paired queries score 5.8743x and 116 builds score 3.1551x, while radius scores 0.9796x and 1,040 slower queries remain. Unsupported segment queries receive no paired score; [validation](VALIDATION.md#direct-moonbit-geo-comparison-2026-10-20) separates nearest API differences and scope.
- Verify the comparison bridge against a complete independent oracle in CI, including multilevel overlap, ties and k outside the input count. Audit complete benchmark matrices, raw medians, regenerated input hashes and query parameters before publishing evidence.
- Reduce 2D/3D nearest traversal overhead with a four-way frontier heap, scalar node removal and termination checks before sifting the frontier. Candidate retention remains a separate bounded binary maximum heap; public interfaces and equal-distance ordering contracts are unchanged.
- Add an interleaved frontier regression that checks exact minimum distances, unique node identity and paired columns across tied insertions and removals.
- Retain the complete 2,592-case targeted nearest comparison: 1.3662x relative to the frozen previous core, 0.8876x relative to Flatbush and 1.0507x relative to RBush, with zero answer-validation failures and 39 slower cases relative to the previous core. This does not replace the full website ranking.

## 0.2.1 — 2026-10-12

- Fix checked restoration of mixed-depth 2D trees: valid branch/leaf mixtures now use the general traversal, preserving every matching ID for point and partial range queries.
- Specialize packed point traversal without increasing index storage. The complete 1,152-case targeted comparison recorded 1.8978x speed relative to 0.2.0 and 1.1359x relative to Flatbush; eleven slower cases relative to the old core remain in the evidence. This is a point-query cohort, not an overall ranking.

- Cache the 3D/4D side projection and share one animation-frame/resize scheduler across canvases. Unchanged dimensions no longer destroy canvas backing stores.
- Coalesce volume queries to the newest input once per 60ms window, cancel queued requests when rebuilding, and fence late results/errors against the active query and dataset.
- Memoize the volume section and stabilize projection properties so unrelated 2D measurements do not redraw it. Selecting the existing object count keeps the ready dataset.
- Add rendering/scheduling regressions and retain local before/after interaction evidence without treating it as a universal frame-rate claim.

## 0.2.0 — 2026-10-12

### Library

- Organize the root facade, public API, core geometry/packing/index/statistics, domain extensions, data generators and browser bridge by ownership.
- Build 2D SoA storage directly, partition at STR page boundaries and copy wholly contained leaf intervals during range queries.
- Fix numerical overflow, midpoint and trajectory-distance handling; add checked persistence restoration and compact DBSCAN handling for sparse or repeated IDs.
- Preserve explicit 4D node identity and levels. Coincident internal bounds no longer link to the wrong level; standard O(n log n) sorting replaces quadratic loops.
- Retain nearest candidates with a bounded maximum heap and sort once at the end. Complete nearest-distance regressions cover 2D and filtered 3D queries, ties, capacities and k beyond the input count.

### Compatibility

Root API names remain available. Canonical geometry types now belong to core geometry; index adapters and storage internals are private. Direct field mutation and internal package imports require migration. These changes do not promise binary compatibility.

### Showcase and evidence

- Provide Chinese and English real 2D queries, an independent complete-result oracle, 3D height queries and 4D time slices.
- Automatically rebuild on configuration changes and measure settled queries. Cache the object layer so dragging does not redraw all objects every frame; cancel superseded worker operations and clear stale results.
- Publish the complete 10,944-case benchmark snapshot with pinned public inputs, original samples, coverage, slower cases and source/compiler fingerprints. A separate 2,592-case nearest comparison measures this optimization at 1.3747x the previous implementation, with 144 slower cases retained. The new nearest implementation remains slower than Flatbush in that comparison.
- Replace the brand mark, favicon and wide README banner with a consistent image-generated monochrome identity; retain generation provenance.

### Distribution

Require moonc 0.10.14 or newer, retain Apache-2.0 licensing and dependency notices, and verify four core targets in CI. The MoonBit archive excludes the browser application and benchmark evidence; those remain available in the public repository and Pages site.

See [validation](VALIDATION.md) for executed checks and measurement limitations. Future memory and multidimensional performance work is not a released performance claim.
