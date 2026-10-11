# Behavioral specification

[English](SPEC.md) | [中文](../zh/SPEC.md)

## Inputs and ownership

Coordinates are Double values; supply finite values and non-negative Int IDs. Constructors normalize reversed intervals. The tree supports degenerate bounds and duplicate inputs. Trees are immutable after construction. Exported/restored buffers are copies; caller-owned query scratch arrays are mutable and must be exclusive to one operation.

## Geometry

Ranges use closed intervals: touching boundaries intersect. A point is contained when each coordinate lies between the corresponding min and max. Box center calculation halves each endpoint before addition to avoid midpoint overflow. Euclidean distances use the runtime square root rather than a fixed number of Newton iterations; squared-distance arithmetic is still subject to floating-point limits.

## Packing

Capacity is clamped to at least 2. 2D leaf-page count is `ceil(N / M)`; slice count is `ceil(sqrt(page_count))`. Sort X centers, then Y within slices; aggregate children into parent bounding boxes and repeat. 3D adds Z; 4D includes time. Sorting may change input ordering in internal copies, never caller inputs. Packing is static and results are deterministic for a fixed implementation; ordering is not an external query guarantee.

## Queries and costs

Range/point queries return all intersecting/containing bounding-box IDs including duplicates. Empty trees return empty results or zero counts. Counts and filtered queries must agree with matching full results. k-NN ranks minimum point-to-box distance, applies a filter before accepting, and returns at most k entries. Range cost can be O(N) under overlap; output materialization costs O(number of hits). Construction sorting and temporary hierarchy arrays allocate memory.

## Restoration

Checked 2D/3D restoration must reject invalid lengths, negative/overflowing adjacency ranges, child indices outside storage, cycles, repeated parents, disconnected nodes, mismatched item counts/heights, non-finite bounds and failed parent enclosure. Trusted restoration skips these checks. Both paths copy successful input buffers.

## Acceptance evidence

Compare entire sorted ID arrays against independent scans, not just hit counts. Numerical regression should cover both 1e12 and 1e-12 scale, plus Int packing limits. DBSCAN compact results must preserve sparse and duplicate IDs. Test each supported target separately. Performance measurements require explicit workload, target, compiler, dataset seed, warmup, iteration count and raw timings; capability and estimated storage tables are separate evidence.
