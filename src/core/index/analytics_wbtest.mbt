///|
test "StrTree and StrTree3D DBSCAN clustering" {
  // Empty tree
  let empty = StrTree::build([])
  let res_empty = empty.dbscan(10.0, 2)
  assert_eq(res_empty.num_clusters, 0)
  assert_eq(res_empty.num_noise, 0)

  // Cluster 0: points near (0, 0), (1, 1), (2, 2)
  // Cluster 1: points near (100, 100), (101, 101), (102, 102)
  // Noise point: at (50, 50)
  let items_2d : Array[(@geometry.Rect, Int32)] = [
    (@geometry.Rect::from_point(0.0, 0.0), 0),
    (@geometry.Rect::from_point(1.0, 1.0), 1),
    (@geometry.Rect::from_point(2.0, 2.0), 2),
    (@geometry.Rect::from_point(100.0, 100.0), 3),
    (@geometry.Rect::from_point(101.0, 101.0), 4),
    (@geometry.Rect::from_point(102.0, 102.0), 5),
    (@geometry.Rect::from_point(50.0, 50.0), 6),
  ]
  let tree_2d = StrTree::build(items_2d, node_capacity=2)
  let res_2d = tree_2d.dbscan(5.0, 2)

  assert_eq(res_2d.num_clusters, 2)
  assert_eq(res_2d.num_noise, 1)
  assert_eq(res_2d.cluster_sizes[0], 3)
  assert_eq(res_2d.cluster_sizes[1], 3)

  // Items 0, 1, 2 should share the same cluster label
  assert_eq(res_2d.labels[0], res_2d.labels[1])
  assert_eq(res_2d.labels[1], res_2d.labels[2])
  // Items 3, 4, 5 should share the same cluster label
  assert_eq(res_2d.labels[3], res_2d.labels[4])
  assert_eq(res_2d.labels[4], res_2d.labels[5])
  // Clusters 0 and 1 are distinct
  assert_true(res_2d.labels[0] != res_2d.labels[3])
  // Item 6 is noise
  assert_eq(res_2d.labels[6], -1)

  // 3D DBSCAN test
  let items_3d : Array[(@geometry.Box3D, Int32)] = [
    (@geometry.Box3D::from_point(0.0, 0.0, 0.0), 0),
    (@geometry.Box3D::from_point(1.0, 1.0, 1.0), 1),
    (@geometry.Box3D::from_point(100.0, 100.0, 100.0), 2),
    (@geometry.Box3D::from_point(101.0, 101.0, 101.0), 3),
    (@geometry.Box3D::from_point(500.0, 500.0, 500.0), 4),
  ]
  let tree_3d = StrTree3D::build(items_3d, node_capacity=2)
  let res_3d = tree_3d.dbscan(5.0, 2)
  assert_eq(res_3d.num_clusters, 2)
  assert_eq(res_3d.num_noise, 1)
}

///|
test "StrTree spatial grid density aggregation" {
  let empty = StrTree::build([])
  let empty_summary = empty.aggregate_grid(10.0, 10.0)
  assert_eq(empty_summary.total_cells, 0)
  assert_eq(empty_summary.max_density, 0)

  // 3 points in cell (0, 0): [0, 10] x [0, 10]
  // 1 point in cell (1, 0): [10, 20] x [0, 10]
  // 2 points in cell (5, 5): [50, 60] x [50, 60]
  let items = [
    (@geometry.Rect::from_point(2.0, 3.0), 0),
    (@geometry.Rect::from_point(5.0, 5.0), 1),
    (@geometry.Rect::from_point(8.0, 9.0), 2),
    (@geometry.Rect::from_point(15.0, 2.0), 3),
    (@geometry.Rect::from_point(52.0, 54.0), 4),
    (@geometry.Rect::from_point(58.0, 59.0), 5),
  ]
  let tree = StrTree::build(items, node_capacity=2)

  let summary = tree.aggregate_grid(10.0, 10.0, hotspot_threshold=2)
  assert_eq(summary.total_cells, 3)
  assert_eq(summary.max_density, 3)
  assert_eq(summary.hotspot_cells.length(), 2)

  // Top hotspot should be cell (0, 0) with 3 items
  assert_eq(summary.hotspot_cells[0].col, 0)
  assert_eq(summary.hotspot_cells[0].row, 0)
  assert_eq(summary.hotspot_cells[0].count, 3)

  // Second hotspot should be cell (5, 5) with 2 items
  assert_eq(summary.hotspot_cells[1].col, 5)
  assert_eq(summary.hotspot_cells[1].row, 5)
  assert_eq(summary.hotspot_cells[1].count, 2)

  // Average density: 6 items across 3 cells = 2.0
  assert_true((summary.avg_density - 2.0).abs() < 0.0001)
}
