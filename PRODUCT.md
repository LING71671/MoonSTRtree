# Product

<!-- impeccable:product-schema 1 -->

[English](PRODUCT.md) | [中文](docs/zh/PRODUCT.md)

## Platform

web

The library also compiles to MoonBit WASM, WASM-GC, JavaScript and Native targets. The browser showcase is one host of the same core implementation.

## Users

MoonBit developers evaluating spatial indexes for games, map/GIS viewport filtering, graphics and data analysis. The current showcase is primarily for competition judges assessing algorithm behavior, implementation quality, portability and measured differences.

## Product Purpose

Build an immutable spatial hierarchy once, prune irrelevant bounds during queries, and make that mechanism inspectable. Success means a consumer can reproduce query correctness and assess workload-dependent costs.

## Capabilities and Constraints

2D/3D/4D STR-packed indexes; geometric bounds and predicates; nearest neighbors; joins; center-based DBSCAN and grid density; geofence state; polygon candidates and clipping; trajectory windows, simplification, compression and sequence similarity.

Input coordinates must be finite and IDs non-negative. Exact geometry may be required after bounding-box filtering. Count queries allocate scratch; raw buffer export/import copies arrays. No universal latency, zero-GC or competitor-speed claim is established. The index has no dynamic insert/delete API.

## Operating Context

Existing MoonBit library, CLI diagnostics and pnpm/Vite/Tailwind playground. Root imports are the consumer boundary; internal packages are layered under src/core and src/extensions. Tests compare query results against independent scans.

## Brand Commitments

Keep the MoonSTRtree name and factual product mechanisms. The user selected a code-led spatial experiment bench and subsequently requested a purely black-and-white professional presentation. A large query canvas and benchmark charts expose real results. Code and directory optimization precedes the showcase build. Technical documentation is maintained in separate English and Chinese files.

## Evidence on Hand

The website provides complete Chinese and English versions through an immediate language switch. Chinese is the default and the selection persists locally. Switching language preserves the current query and measurements. Use concrete connected explanations rather than slogans made from very short phrases separated by commas. Chinese reading and display type is self-hosted Noto Sans SC; the English typography retains Barlow Condensed and Manrope.

Core source, generated interfaces, deterministic regression tests, diagnostic samples and maintained architecture/API documents. Synthetic distributions must be labeled. Browser comparison results are only evidence after measuring real implementations on identical data and validating complete results.

## Product Principles

Preserve root API names; isolate domains through directed package dependencies; prove correctness independently; disclose measurement limitations and losses; show the algorithm working before making performance claims.

Benchmark improvement aims at broad competitive performance across queries, construction and memory rather than a selected winning example. Public datasets, synthetic stress cases, multiple seeds and workload parameters must remain distinguishable. Use efficient documented competitor APIs and publish failed or slower cases alongside successes. Complete real-world application case studies are a future roadmap item. The public repository requires topics and a working GitHub Pages showcase.
