///|
test "tree empty items handling" {
  let tree = StrTree::build([])
  assert_eq(tree.num_items(), 0)
  assert_eq(tree.num_nodes(), 0)
  assert_eq(tree.height(), 0)
  assert_true(tree.root_bounds() is None)

  let query_res = tree.query(@geometry.Rect::new(0.0, 0.0, 10.0, 10.0))
  assert_eq(query_res.length(), 0)

  let point_res = tree.query_point(5.0, 5.0)
  assert_eq(point_res.length(), 0)
}

///|
test "tree single item query and point query" {
  let item = (@geometry.Rect::new(10.0, 10.0, 20.0, 20.0), 101)
  let tree = StrTree::build([item], node_capacity=16)

  assert_eq(tree.num_items(), 1)
  assert_eq(tree.height(), 1)

  // Intersecting query
  let hit = tree.query(@geometry.Rect::new(15.0, 15.0, 25.0, 25.0))
  assert_eq(hit.length(), 1)
  assert_eq(hit[0], 101)

  // Disjoint query
  let miss = tree.query(@geometry.Rect::new(0.0, 0.0, 5.0, 5.0))
  assert_eq(miss.length(), 0)

  // Point query inside
  let pt_hit = tree.query_point(15.0, 15.0)
  assert_eq(pt_hit.length(), 1)
  assert_eq(pt_hit[0], 101)

  // Point query outside
  let pt_miss = tree.query_point(9.9, 9.9)
  assert_eq(pt_miss.length(), 0)
}

///|
test "tree 25 items grid query and pruning" {
  let items : Array[(@geometry.Rect, Int32)] = []
  // 5x5 grid from (0,0) to (50, 50)
  for x = 0; x < 5; x = x + 1 {
    for y = 0; y < 5; y = y + 1 {
      let min_x = x.to_double() * 10.0
      let min_y = y.to_double() * 10.0
      let id = x * 10 + y
      items.push(
        (@geometry.Rect::new(min_x, min_y, min_x + 5.0, min_y + 5.0), id),
      )
    }
  }

  let tree = StrTree::build(items, node_capacity=4)
  assert_eq(tree.num_items(), 25)

  // Query window covering (0,0) to (15, 15) -> hits (0,0), (0,1), (1,0), (1,1)
  let q = @geometry.Rect::new(0.0, 0.0, 15.0, 15.0)
  let res = tree.query(q)
  res.sort()

  let expected = [0, 1, 10, 11]
  assert_eq(res, expected)

  // Point query exactly inside cell (2, 3) -> (20, 30) to (25, 35)
  let pt_res = tree.query_point(22.0, 32.0)
  assert_eq(pt_res, [23])
}

///|
test "tree query_knn empty and single item" {
  let empty_tree = StrTree::build([])
  assert_eq(empty_tree.query_knn(0.0, 0.0, 0), [])
  assert_eq(empty_tree.query_knn(0.0, 0.0, 5), [])

  let single_item = (@geometry.Rect::new(10.0, 10.0, 20.0, 20.0), 99)
  let tree = StrTree::build([single_item])
  assert_eq(tree.query_knn(0.0, 0.0, 0), [])
  assert_eq(tree.query_knn(15.0, 15.0, 1), [99])
  assert_eq(tree.query_knn(100.0, 100.0, 10), [99])
}

///|
test "tree query_knn 25 items nearest neighbor ordering" {
  let items : Array[(@geometry.Rect, Int32)] = []
  for x = 0; x < 5; x = x + 1 {
    for y = 0; y < 5; y = y + 1 {
      let min_x = x.to_double() * 10.0
      let min_y = y.to_double() * 10.0
      let id = x * 10 + y
      items.push(
        (@geometry.Rect::new(min_x, min_y, min_x + 5.0, min_y + 5.0), id),
      )
    }
  }

  let tree = StrTree::build(items, node_capacity=4)

  // Query exactly at (0.0, 0.0)
  // Distance to (0, 0) box is 0.0 -> ID 0
  let knn_1 = tree.query_knn(0.0, 0.0, 1)
  assert_eq(knn_1, [0])

  // Top 3 closest to (0.0, 0.0)
  // Box 0: (0,0)-(5,5) -> dist=0
  // Box 1: (0,10)-(5,15) -> dist=5
  // Box 10: (10,0)-(15,5) -> dist=5
  let knn_3 = tree.query_knn(0.0, 0.0, 3)
  assert_eq(knn_3.length(), 3)
  assert_eq(knn_3[0], 0)
  assert_true(
    (knn_3[1] == 1 && knn_3[2] == 10) || (knn_3[1] == 10 && knn_3[2] == 1),
  )

  // Query asking for k > total items
  let knn_all = tree.query_knn(0.0, 0.0, 50)
  assert_eq(knn_all.length(), 25)
  assert_eq(knn_all[0], 0)
}

///|
test "tree query_segment diagonal and horizontal cuts" {
  let empty = StrTree::build([])
  assert_eq(empty.query_segment(0.0, 0.0, 10.0, 10.0), [])

  let items : Array[(@geometry.Rect, Int32)] = []
  for x = 0; x < 5; x = x + 1 {
    for y = 0; y < 5; y = y + 1 {
      let min_x = x.to_double() * 10.0
      let min_y = y.to_double() * 10.0
      let id = x * 10 + y
      items.push(
        (@geometry.Rect::new(min_x, min_y, min_x + 5.0, min_y + 5.0), id),
      )
    }
  }
  let tree = StrTree::build(items, node_capacity=4)

  // Diagonal segment (-5, -5) -> (50, 50) cuts through main diagonal cells
  let diag_hits = tree.query_segment(-5.0, -5.0, 50.0, 50.0)
  diag_hits.sort()
  assert_eq(diag_hits, [0, 11, 22, 33, 44])

  // Horizontal line at y=22 cuts row y=2 (boxes y in [20, 25]) across all 5 columns
  let horiz_hits = tree.query_segment(-5.0, 22.0, 55.0, 22.0)
  horiz_hits.sort()
  assert_eq(horiz_hits, [2, 12, 22, 32, 42])

  // Disjoint segment completely outside
  let disjoint_hits = tree.query_segment(100.0, 100.0, 200.0, 200.0)
  assert_eq(disjoint_hits, [])
}

///|
test "tree spatial_join dual-tree intersection" {
  let empty = StrTree::build([])
  assert_eq(empty.spatial_join(empty), [])

  let items_a = [
    (@geometry.Rect::new(0.0, 0.0, 10.0, 10.0), 101),
    (@geometry.Rect::new(20.0, 20.0, 30.0, 30.0), 102),
  ]
  let items_b = [
    (@geometry.Rect::new(5.0, 5.0, 15.0, 15.0), 201), // intersects 101
    (@geometry.Rect::new(25.0, 25.0, 35.0, 35.0), 202), // intersects 102
    (@geometry.Rect::new(100.0, 100.0, 110.0, 110.0), 203), // disjoint
  ]

  let tree_a = StrTree::build(items_a, node_capacity=2)
  let tree_b = StrTree::build(items_b, node_capacity=2)

  let pairs = tree_a.spatial_join(tree_b)
  pairs.sort_by(fn(x, y) { if x.0 != y.0 { x.0 - y.0 } else { x.1 - y.1 } })

  assert_eq(pairs, [(101, 201), (102, 202)])

  // Disjoint trees
  let items_c = [(@geometry.Rect::new(500.0, 500.0, 600.0, 600.0), 301)]
  let tree_c = StrTree::build(items_c)
  assert_eq(tree_a.spatial_join(tree_c), [])
}

///|
test "tree to_flat_buffers and from_flat_buffers round-trip integrity" {
  let items : Array[(@geometry.Rect, Int32)] = []
  for i = 0; i < 20; i = i + 1 {
    let fi = i.to_double() * 10.0
    items.push((@geometry.Rect::new(fi, fi, fi + 5.0, fi + 5.0), i))
  }
  let tree = StrTree::build(items, node_capacity=4)

  let buffers = tree.to_flat_buffers()
  let reconstructed = StrTree::from_flat_buffers(buffers)

  assert_eq(reconstructed.num_items(), tree.num_items())
  assert_eq(reconstructed.height(), tree.height())

  let q = @geometry.Rect::new(15.0, 15.0, 55.0, 55.0)
  assert_eq(reconstructed.query(q), tree.query(q))

  let knn = reconstructed.query_knn(0.0, 0.0, 3)
  assert_eq(knn, tree.query_knn(0.0, 0.0, 3))
}

///|
test "tree query_count, query_point_count, query_first, and query_with_predicate" {
  let items : Array[(@geometry.Rect, Int32)] = []
  for i = 0; i < 20; i = i + 1 {
    let fi = i.to_double() * 10.0
    items.push((@geometry.Rect::new(fi, fi, fi + 10.0, fi + 10.0), i))
  }
  let tree = StrTree::build(items, node_capacity=4)

  let q = @geometry.Rect::new(15.0, 15.0, 55.0, 55.0)
  let hits = tree.query(q)
  let count = tree.query_count(q)
  assert_eq(count, hits.length())

  // Point count
  let pt_hits = tree.query_point(25.0, 25.0)
  let pt_count = tree.query_point_count(25.0, 25.0)
  assert_eq(pt_count, pt_hits.length())

  // Predicate: only even IDs
  let even_hits = tree.query_with_predicate(q, fn(id) { id % 2 == 0 })
  for id in even_hits {
    assert_true(id % 2 == 0)
    assert_true(hits.contains(id))
  }
  for id in hits {
    if id % 2 == 0 {
      assert_true(even_hits.contains(id))
    }
  }

  // First hit satisfying condition (id >= 4)
  let first_ge4 = tree.query_first(q, fn(id) { id >= 4 })
  assert_true(first_ge4 is Some(_))
  assert_true(first_ge4.unwrap() >= 4)
  assert_true(hits.contains(first_ge4.unwrap()))

  // Non-existent predicate
  let first_none = tree.query_first(q, fn(id) { id > 100 })
  assert_true(first_none is None)
}

///|
test "tree query_circle and query_circle_count verified against brute-force scan" {
  let items : Array[(@geometry.Rect, Int32)] = []
  for i = 0; i < 50; i = i + 1 {
    let fi = i.to_double() * 10.0
    items.push((@geometry.Rect::new(fi, fi, fi + 10.0, fi + 10.0), i))
  }
  let tree = StrTree::build(items, node_capacity=4)

  let cx = 100.0
  let cy = 100.0
  let radius = 50.0

  let circle_hits = tree.query_circle(cx, cy, radius)
  let circle_count = tree.query_circle_count(cx, cy, radius)
  assert_eq(circle_count, circle_hits.length())

  // Brute-force verification
  let mut brute_count = 0
  for item in items {
    let (rect, id) = item
    if rect.intersects_circle(cx, cy, radius) {
      brute_count = brute_count + 1
      assert_true(circle_hits.contains(id))
    }
  }
  assert_eq(circle_hits.length(), brute_count)

  // Empty / disjoint circle
  let disjoint_hits = tree.query_circle(-200.0, -200.0, 10.0)
  assert_eq(disjoint_hits.length(), 0)
  assert_eq(tree.query_circle_count(-200.0, -200.0, 10.0), 0)

  // Negative radius
  assert_eq(tree.query_circle(cx, cy, -5.0).length(), 0)
  assert_eq(tree.query_circle_count(cx, cy, -5.0), 0)
}

///|
test "StrTree spatial predicate queries and hierarchical spatial joins" {
  // Tree A with items 0, 1, 2
  // item 0: [0, 10] x [0, 10]
  // item 1: [10, 20] x [0, 10] (touches item 0 on edge x=10)
  // item 2: [50, 60] x [50, 60] (disjoint)
  let items_a = [
    (@geometry.Rect::new(0.0, 0.0, 10.0, 10.0), 0),
    (@geometry.Rect::new(10.0, 0.0, 20.0, 10.0), 1),
    (@geometry.Rect::new(50.0, 50.0, 60.0, 60.0), 2),
  ]
  let tree_a = StrTree::build(items_a, node_capacity=2)

  // 1. query_spatial_predicate: Touches
  let touch_rect = @geometry.Rect::new(10.0, 0.0, 15.0, 10.0)
  // touch_rect touches item 0 along edge x=10, overlaps item 1
  let touches_hits = tree_a.query_spatial_predicate(
    touch_rect,
    @geometry.SpatialPredicate::Touches,
  )
  assert_true(touches_hits.contains(0))
  assert_false(touches_hits.contains(1))

  // 2. query_spatial_predicate: Contains (window contains leaf)
  let big_window = @geometry.Rect::new(-5.0, -5.0, 25.0, 25.0)
  let contains_hits = tree_a.query_spatial_predicate(
    big_window,
    @geometry.SpatialPredicate::Contains,
  )
  assert_true(contains_hits.contains(0))
  assert_true(contains_hits.contains(1))
  assert_false(contains_hits.contains(2))

  // 3. Tree B with items 100, 101
  // item 100: [5, 15] x [0, 10] (overlaps item 0, overlaps item 1)
  // item 101: [70, 80] x [70, 80] (completely disjoint from all items in A)
  let items_b = [
    (@geometry.Rect::new(5.0, 0.0, 15.0, 10.0), 100),
    (@geometry.Rect::new(70.0, 70.0, 80.0, 80.0), 101),
  ]
  let tree_b = StrTree::build(items_b, node_capacity=2)

  // 4. Hierarchical spatial join: Intersects
  let join_inter = tree_a.spatial_join(tree_b)
  assert_true(join_inter.contains((0, 100)))
  assert_true(join_inter.contains((1, 100)))
  assert_false(join_inter.contains((2, 100)))
  assert_false(join_inter.contains((0, 101)))

  // 5. Hierarchical spatial join with predicate: Overlaps
  let join_overlaps = tree_a.spatial_join_predicate(
    tree_b,
    @geometry.SpatialPredicate::Overlaps,
  )
  assert_true(join_overlaps.contains((0, 100)))
  assert_true(join_overlaps.contains((1, 100)))
}
