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
- [x] Complete test suite passes with `moon test` (36/36 passed)
- [x] Zero warnings under `moon check`
- [x] 100% equivalence verified against brute-force scan across 5 spatial distributions
- [x] Branch-and-bound k-NN search verified against sorted brute-force Euclidean distance scan

---

## Audit History

- **Review 1 (Commits 11–15)**: Discovered ISSUE-001 (facade missing), ISSUE-002 (stub main), ISSUE-003 (window inversion guard). Resolved in commit `b1781a2`.
- **Review 2 (Commits 16–20)**: Audited synthetic generators and differential fuzzing. Zero defects found. All 32 unit and fuzzing tests passed. Fill factor verified at >98% under uniform & clustered distributions. Working tree clean.
- **Review 3 (Commits 21–26)**: Audited branch-and-bound k-Nearest-Neighbor (`query_knn`) engine, flat binary min-heap ordering, MinDist bounding box lower bounds, and SVG/banner-extracted square logo asset centering. Zero defects discovered. All 36 tests passed cleanly. Working tree verified.
