# MoonSTRtree Issue Tracking & Quality Audit Log

[English](./docs/en/SPEC.md) | [中文规范](./docs/zh/SPEC.md)

This log records issues, architectural edge cases, and bug fixes discovered during automated reviews and fuzzing sessions.

---

## Issue Log

| Issue ID | Severity | Module | Description | Status | Fix Commit |
| :--- | :--- | :--- | :--- | :--- | :--- |
| ISSUE-001 | High | `root` | Root library package missing public facade re-exports (`Rect`, `StrTree`, `TreeStats`), blocking consumer integration. | Resolved | Pending Commit |
| ISSUE-002 | Medium | `cmd/main` | CLI entry point contains template stub, triggering unused package compiler warnings. | Resolved | Pending Commit |
| ISSUE-003 | Low | `src/tree` | Query window lacks pre-normalization guard against manually instantiated inverted rectangles. | Resolved | Pending Commit |

---

## Review Checklist

- [x] All coordinates normalized (`min <= max`)
- [x] No recursive calls in DFS query loop
- [x] Preallocated integer stack bounds respected
- [x] Zero heap allocations during `query` and `query_point`
- [x] Complete test suite passes with `moon test` (22/22 passed)
- [x] Zero warnings under `moon check`
- [x] 100% equivalence verified against brute-force scan
