# API reference

[English](API_SPECIFICATION.md) | [中文](../zh/API_SPECIFICATION.md)

Import `LING71671/moon_strtree` from `moon.pkg`. The root re-exports the consumer API; index adapters belong to `src/api` and canonical geometry types are re-exported from `src/core/geometry`. See the [API interface](../../src/api/pkg.generated.mbti) and [geometry interface](../../src/core/geometry/pkg.generated.mbti) for signatures. This guide defines behavior and boundaries rather than duplicating every declaration.

## Geometry and construction

| Type / operation | Contract |
| --- | --- |
| `Rect::new(min_x, min_y, max_x, max_y)` | Normalizes reversed bounds; closed intervals |
| `Box3D::new` / `Box4D::new` | Normalizes each spatial and temporal interval |
| `StrTree::build(items, node_capacity=16)` | Static 2D index over `(Rect, Int)` pairs; capacity below 2 is clamped to 2 |
| `StrTree::build_coordinates(coordinates, node_capacity=16)` | Flat `[minX,minY,maxX,maxY]` records; length must be divisible by four, bounds normalize and IDs are input positions |
| `StrTree3D::build` / `StrTree4D::build` | Corresponding 3D or spatiotemporal bounding-box index |
| `stats()` | Item/node/edge counts, height, branch-slot fill and estimated numeric payload |

Supply finite coordinates and non-negative IDs. Duplicate IDs are retained for ordinary queries. IDs identify caller objects, not positions in input. Floating-point calculations can overflow or lose precision at extreme scales. Empty builds and degenerate point/line/box inputs are supported. Outputs are newly owned arrays unless a reusable buffer API explicitly says otherwise.

## Query families

| Method | Dimensions | Meaning |
| --- | --- | --- |
| `query(window)` / `query_point(...)` | 2D, 3D, 4D | Intersecting or containing bounding boxes; includes touching boundaries |
| `query_count(window)` | 2D, 3D, 4D | Number of matches without a result array |
| `query_point_count`, `query_first`, `query_with_predicate` | 2D, 3D | Count / optional first filtered hit / all filtered hits |
| `query_circle`, `query_circle_count` | 2D | Bounding boxes intersecting a circle; negative radius has no hits |
| `query_sphere`, `query_sphere_count` | 3D | Corresponding sphere operations |
| `query_knn`, `query_knn_with_distance` | 2D, 3D | At most k closest boxes by minimum point-to-box distance |
| `query_knn_with_predicate`, `query_knn_with_predicate_and_distance` | 2D, 3D | Closest accepted boxes; rejected candidates do not consume k |
| `query_segment` | 2D, 3D | Segment versus bounding-box intersection, not an infinite ray |
| `spatial_join(other)` | 2D, 3D | All intersecting leaf ID pairs; self-joins include diagonal and symmetric pairs |
| `query_spatial_predicate`, `spatial_join_predicate` | 2D | Named predicates evaluated on bounding rectangles |
| `query_time_slice(box3d, t)` | 4D | Spatial bounds restricted to a degenerate time interval |

Result order is unspecified. k <= 0 returns an empty result; k larger than the population returns all accepted candidates. Distance-returning methods return squared distances, not square roots. Equal-distance ties are arbitrary. A count method still allocates traversal scratch space. Spatial predicates describe bounding boxes and do not implement arbitrary-polygon DE-9IM.

## Reusable queries

```moonbit
let results : Array[Int] = []
let scratch : Array[Int] = []
tree.query_into(window, results, scratch)
```

`StrTree::query_into` clears both arrays before querying, including empty or disjoint cases. `results` and `scratch` must be distinct arrays exclusively owned by that query. Reuse reduces repeated array creation; capacity growth may still allocate. Geometry aliases avoid per-query adapter conversion objects. Do not share scratch arrays between concurrent queries.

## Storage and integrity

`to_flat_buffers()` creates independent array copies. `from_flat_buffers()` copies trusted buffers; 2D may check topology to recover its layout hint, but does not establish finite bounds or enclosure validity. These types are raw MoonBit arrays, not the third-party FlatBuffers binary format.

`from_flat_buffers_checked()` on 2D/3D returns `Some(tree)` only after checking lengths, offsets, child indices, capacity, a connected acyclic root, item count, tree height, finite bounds and geometric enclosure; otherwise it returns `None`. 3D node-level array length and declared node count are also checked. `StrTree::validate_integrity()` checks existing 2D raw storage without copying it. Checked restoration does not imply dynamic mutation support.

## Analytics

`dbscan(eps, min_pts)` clusters bounding-box centers. Minimum points below 1 are clamped to 1. Labels -1 denote noise. Legacy labels are addressed by user ID, so sparse IDs may allocate a very large result array; duplicate IDs cannot represent multiple labels independently.

Prefer `dbscan_compact(eps, min_pts)` for sparse or duplicate IDs. Its `CompactClusterResult` has parallel `item_ids` and `labels` arrays, one entry per indexed item in storage order, plus `num_clusters`, `num_noise` and `cluster_sizes`. The result uses O(N) storage. Cluster numbering is not a stable identifier across rebuilds.

`aggregate_grid` bins item centers by cell width and height, including negative coordinates. Invalid non-positive cell dimensions return an empty summary. Geofence monitoring maintains state for each tracked entity and reports `Enter`, `Exit` and `Stay` based on rectangle intersections or point containment.

## Extension boundaries

| Extension | Behavior |
| --- | --- |
| `StrMeshTree3D` | Indexes triangle bounds; segment/ray methods perform exact triangle tests for candidates |
| `StrPolygonIndex` | Windows/counts return envelope candidates; polygon clipping is a separate operation |
| `TrajectoryWindowIndex` | Indexes segment spatial/time bounds; returns candidate segment or track IDs |
| Simplification | 2D Douglas-Peucker and synchronized spatiotemporal error simplification |
| Streaming compression | Online waypoint reduction; `finish` emits the pending endpoint |
| DTW / Frechet | Discrete sequence distances, with optional DTW window constraint |

Consult the [generated interface](../../src/api/pkg.generated.mbti) for parameter order and all geometry helpers. Use exact geometry after bounding-box candidate filtering when the application requires exact intersections.
