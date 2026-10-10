# MoonSTRtree Issue Tracking & Quality Audit Log

[English](./docs/en/SPEC.md) | [中文规范](./docs/zh/SPEC.md)

This log records issues, architectural edge cases, and bug fixes discovered during automated reviews and fuzzing sessions.

---

## Issue Log

| Issue ID | Severity | Module | Description | Status | Fix Commit |
| :--- | :--- | :--- | :--- | :--- | :--- |
| ISSUE-001 | High | `root` | Root library package missing public facade re-exports (`Rect`, `StrTree`, `TreeStats`), blocking consumer integration. | Resolved | `b1781a2` |
| ISSUE-002 | Medium | `cmd/main` | CLI entry point contains template stub, triggering unused package compiler warnings. | Resolved | `b1781a2` |
| ISSUE-003 | Low | `src/tree` | Query window lacks pre-normalization guard against manually instantiated inverted rectangles. | Resolved | `b1781a2` |

---

## Review Checklist

- [x] All coordinates normalized (`min <= max`)
- [x] No recursive calls in DFS query loop
- [x] Preallocated integer stack bounds respected
- [x] Zero heap allocations during `query` and `query_point`
- [x] Complete test suite passes with `moon test` (66/66 passed)
- [x] Zero warnings under `moon check`
- [x] 100% equivalence verified against brute-force scan across 5 spatial distributions
- [x] Branch-and-bound k-NN search verified against sorted brute-force Euclidean distance scan
- [x] Line segment ray-casting and dual-tree spatial join verified with differential test suites
- [x] FlatBuffers serialization and reconstruction verified for zero-loss round-trip
- [x] Rect intersection, expand, distance_to_rect, and IoU metric formulas verified
- [x] Zero-allocation counters (query_count, query_point_count) and early-exit predicates verified
- [x] Circular range queries (query_circle, query_circle_count) verified against brute-force scan
- [x] 3D AABB Box3D spatial operators, volume, and distance metrics verified
- [x] query_knn_with_distance monotonic distance ordering verified
- [x] query_knn_with_predicate and query_knn_with_predicate_and_distance in-flight filtering and monotonic ordering verified
- [x] Box3D distance_to_box, volumetric iou, and sphere collision verified
- [x] 3D uniform and clustered Gaussian synthetic distribution generators verified
- [x] StrTree3D range, point, and spherical queries verified with brute-force equivalence
- [x] 3D Box3D Liang-Barsky segment clipping and StrTree3D ray-casting verified
- [x] StrTree3D k-NN search and monotonic distance ordering verified against brute-force scan
- [x] StrTree3D zero-allocation point and sphere counting verified
- [x] StrTree3D dual-tree spatial_join hierarchical traversal verified with brute-force scan
- [x] StrTree3D query_first early-exit and query_with_predicate in-flight filtering verified
- [x] FlatBuffers3D raw array serialization and zero-loss reconstruction round-trip verified

---

## Audit History

- **Review 1 (Commits 11–15)**: Discovered ISSUE-001 (facade missing), ISSUE-002 (stub main), ISSUE-003 (window inversion guard). Resolved in commit `b1781a2`.
- **Review 2 (Commits 16–20)**: Audited synthetic generators and differential fuzzing. Zero defects found. All 32 unit and fuzzing tests passed. Fill factor verified at >98% under uniform & clustered distributions. Working tree clean.
- **Review 3 (Commits 21–26)**: Audited branch-and-bound k-Nearest-Neighbor (`query_knn`) engine, flat binary min-heap ordering, MinDist bounding box lower bounds, and SVG/banner-extracted square logo asset centering. Zero defects discovered. All 36 tests passed cleanly. Working tree verified.
- **Review 4 (Commits 27–32)**: Audited Liang-Barsky segment clipping (`Rect::intersects_segment`), line segment ray-casting traversal (`StrTree::query_segment`), and dual-tree hierarchical spatial join (`StrTree::spatial_join`). Zero defects discovered. All 41 unit and differential fuzzing tests passed cleanly. Working tree clean.
- **Review 5 (Commits 33–37)**: Audited FlatBuffers raw array serialization (`to_flat_buffers` / `from_flat_buffers`), bilingual API specification synchronization, CLI benchmark multi-query driver extension, and formal roadmap phase completion. Zero defects discovered. All 43 tests passed cleanly. Working tree clean.
- **Review 6 (Commits 38–45)**: Audited interactive playground canvas visualizer, Rect topological operators (`intersection`, `expand`), metric operators (`distance_to_rect`, `iou`), bilingual specifications, and roadmap synchronization. Zero defects discovered. All 45 tests passed cleanly. Working tree clean.
- **Review 7 (Commits 46–51)**: Audited zero-allocation spatial item counters (`query_count`, `query_point_count`), early-exit short-circuit search (`query_first`), user predicate filtering (`query_with_predicate`), bilingual API specifications, CLI benchmark driver extensions, and playground visualizer engine synchronization. Zero defects discovered. All 47 tests passed cleanly under `moon test`. Working tree clean.
- **Review 8 (Commits 52–58)**: Audited circle-to-rectangle intersection testing (`Rect::intersects_circle`), circular range query traversal (`StrTree::query_circle`), zero-allocation radius item counting (`StrTree::query_circle_count`), bilingual API specifications, CLI multi-distribution benchmark validation, and playground visualizer engine synchronization. Zero defects discovered. All 50 unit and differential tests passed cleanly. Working tree clean.
- **Review 9 (Commits 59–64)**: Audited 3D bounding box primitive (`Box3D`), 3D SAT intersection and containment tests, volume and surface area metrics, facade exports, bilingual specifications, playground visualizer integration, and `query_knn_with_distance` metric verification. Zero defects discovered. All 53 unit and differential tests passed cleanly. Working tree clean.
- **Review 10 (Commits 65–70)**: Audited predicate-filtered k-NN search (`query_knn_with_predicate`, `query_knn_with_predicate_and_distance`), in-flight leaf predicate evaluation, priority queue pruning bounds, bilingual specifications and roadmaps synchronization, playground JavaScript engine mirror, and monotonic ordering verification. Zero defects discovered. All 54 tests passed cleanly under `moon test`. Working tree clean.
- **Review 11 (Commits 71–75)**: Audited advanced 3D bounding box operators (`Box3D::distance_to_box`, `Box3D::iou`, `Box3D::intersects_sphere`), 3D synthetic distribution generators (`generate_boxes_3d_uniform`, `generate_boxes_3d_clustered`), facade exports, bilingual specifications, and playground JavaScript engine synchronization. Zero defects discovered. All 56 unit and differential tests passed cleanly under `moon test`. Working tree clean.
- **Review 12 (Commits 76–81)**: Audited 3D Sort-Tile-Recursive bulk loader (`pack_str3d`), packed flat-array tree (`StrTree3D`), 3D AABB range queries (`query`), zero-allocation counting (`query_count`), 3D point queries (`query_point`), spherical intersection queries (`query_sphere`), facade exports, bilingual specifications, and playground JavaScript engine mirror. Zero defects discovered. All 59 unit, differential, and brute-force equivalence tests passed cleanly under `moon test`. Working tree clean.
- **Review 13 (Commits 82–87)**: Audited 3D Liang-Barsky line segment / ray intersection (`Box3D::intersects_segment`), 3D branch-and-bound k-NN search (`StrTree3D::query_knn`, `query_knn_with_distance`), in-flight predicate filtering (`query_knn_with_predicate`, `query_knn_with_predicate_and_distance`), 3D ray segment querying (`StrTree3D::query_segment`), zero-allocation point and sphere counting (`query_point_count`, `query_sphere_count`), facade root exports, bilingual specifications, and playground JavaScript engine mirror. Zero defects discovered. All 63 unit, differential, and brute-force equivalence tests passed cleanly under `moon test`. Working tree clean.
- **Review 14 (Commits 88–92)**: Audited 3D dual-tree hierarchical spatial join (`StrTree3D::spatial_join`), early-exit search (`StrTree3D::query_first`), predicate filtering (`StrTree3D::query_with_predicate`), 3D FlatBuffers raw-array serialization and reconstruction (`to_flat_buffers`, `from_flat_buffers`), facade root exports, bilingual specifications (`docs/zh/` & `docs/en/`), and playground JavaScript engine mirror. Zero defects discovered. All 66 unit, differential, and brute-force equivalence tests passed cleanly under `moon test`. Working tree clean.


