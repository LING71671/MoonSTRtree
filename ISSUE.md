# MoonSTRtree Issue Tracking & Quality Audit Log

[English](./docs/en/SPEC.md) | [中文规范](./docs/zh/SPEC.md)

This log records issues, architectural edge cases, and bug fixes discovered during automated reviews and fuzzing sessions.

---

## Issue Log

| Issue ID | Severity | Module | Description | Status | Fix Commit |
| :--- | :--- | :--- | :--- | :--- | :--- |

---

## Review Checklist

- [ ] All coordinates normalized (`min <= max`)
- [ ] No recursive calls in DFS query loop
- [ ] Preallocated integer stack bounds respected
- [ ] Zero heap allocations during `query` and `query_point`
- [ ] Complete test suite passes with `moon test`
- [ ] Zero warnings under `moon check`
- [ ] 100% equivalence verified against brute-force scan
