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
  let items : Array[(@geometry.Rect, Int)] = []
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
  let items : Array[(@geometry.Rect, Int)] = []
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

  let items : Array[(@geometry.Rect, Int)] = []
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
  let items : Array[(@geometry.Rect, Int)] = []
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
  let items : Array[(@geometry.Rect, Int)] = []
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
  let items : Array[(@geometry.Rect, Int)] = []
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
test "tree3d query_knn and query_knn_with_distance nearest neighbor ordering" {
  let empty_tree = StrTree3D::build([])
  assert_eq(empty_tree.query_knn(0.0, 0.0, 0.0, 5), [])
  assert_eq(empty_tree.query_knn_with_distance(0.0, 0.0, 0.0, 5), [])

  // 3x3x3 = 27 items grid
  let items : Array[(@geometry.Box3D, Int)] = []
  let mut id = 0
  for x = 0; x < 3; x = x + 1 {
    for y = 0; y < 3; y = y + 1 {
      for z = 0; z < 3; z = z + 1 {
        let fx = x.to_double() * 10.0
        let fy = y.to_double() * 10.0
        let fz = z.to_double() * 10.0
        items.push(
          (@geometry.Box3D::new(fx, fy, fz, fx + 5.0, fy + 5.0, fz + 5.0), id),
        )
        id = id + 1
      }
    }
  }

  let tree = StrTree3D::build(items, node_capacity=4)

  // k <= 0
  assert_eq(tree.query_knn(0.0, 0.0, 0.0, 0), [])
  assert_eq(tree.query_knn_with_distance(0.0, 0.0, 0.0, -1), [])

  // 1-NN from (0, 0, 0) should be item 0 at origin with dist 0
  let knn_1 = tree.query_knn(0.0, 0.0, 0.0, 1)
  assert_eq(knn_1, [0])

  let knn_1_dist = tree.query_knn_with_distance(0.0, 0.0, 0.0, 1)
  assert_eq(knn_1_dist.length(), 1)
  assert_eq(knn_1_dist[0].0, 0)
  assert_eq(knn_1_dist[0].1, 0.0)

  // k = 5 nearest neighbors
  let knn_5 = tree.query_knn_with_distance(0.0, 0.0, 0.0, 5)
  assert_eq(knn_5.length(), 5)
  for i = 0; i < 4; i = i + 1 {
    assert_true(knn_5[i].1 <= knn_5[i + 1].1)
  }

  // With predicate (only even IDs)
  let knn_even = tree.query_knn_with_predicate(0.0, 0.0, 0.0, 4, fn(id) {
    id % 2 == 0
  })
  assert_eq(knn_even.length(), 4)
  for item_id in knn_even {
    assert_eq(item_id % 2, 0)
  }

  let knn_even_dist = tree.query_knn_with_predicate_and_distance(
    0.0,
    0.0,
    0.0,
    4,
    fn(id) { id % 2 == 0 },
  )
  assert_eq(knn_even_dist.length(), 4)
  for pair in knn_even_dist {
    assert_eq(pair.0 % 2, 0)
  }
}

///|
test "tree3d query_segment, query_point_count, and query_sphere_count" {
  let items : Array[(@geometry.Box3D, Int)] = []
  for i = 0; i < 30; i = i + 1 {
    let fi = i.to_double() * 10.0
    items.push(
      (@geometry.Box3D::new(fi, fi, fi, fi + 8.0, fi + 8.0, fi + 8.0), i),
    )
  }
  let tree = StrTree3D::build(items, node_capacity=4)

  // 1. Ray through first 3 boxes: from (0,0,0) to (25,25,25)
  let seg_hits = tree.query_segment(0.0, 0.0, 0.0, 25.0, 25.0, 25.0)
  assert_true(seg_hits.contains(0))
  assert_true(seg_hits.contains(1))
  assert_true(seg_hits.contains(2))

  // Brute force equivalence for segment query
  let mut brute_seg_hits = 0
  for item in items {
    let (box3d, id) = item
    if box3d.intersects_segment(0.0, 0.0, 0.0, 25.0, 25.0, 25.0) {
      brute_seg_hits = brute_seg_hits + 1
      assert_true(seg_hits.contains(id))
    }
  }
  assert_eq(seg_hits.length(), brute_seg_hits)

  // 2. Disjoint ray
  let disjoint_ray = tree.query_segment(
    -100.0, -100.0, 500.0, -100.0, -100.0, 1000.0,
  )
  assert_eq(disjoint_ray.length(), 0)

  // 3. Point count
  let pt_hits = tree.query_point(15.0, 15.0, 15.0)
  let pt_count = tree.query_point_count(15.0, 15.0, 15.0)
  assert_eq(pt_count, pt_hits.length())

  // 4. Sphere count
  let sp_hits = tree.query_sphere(50.0, 50.0, 50.0, 25.0)
  let sp_count = tree.query_sphere_count(50.0, 50.0, 50.0, 25.0)
  assert_eq(sp_count, sp_hits.length())
}

///|
test "tree3d spatial_join against brute-force pairwise intersection" {
  let empty_a = StrTree3D::build([])
  let empty_b = StrTree3D::build([])
  assert_eq(empty_a.spatial_join(empty_b), [])

  let items_a : Array[(@geometry.Box3D, Int)] = []
  for i = 0; i < 20; i = i + 1 {
    let fi = i.to_double() * 15.0
    items_a.push(
      (@geometry.Box3D::new(fi, fi, fi, fi + 10.0, fi + 10.0, fi + 10.0), i),
    )
  }
  let tree_a = StrTree3D::build(items_a, node_capacity=4)

  let items_b : Array[(@geometry.Box3D, Int)] = []
  for j = 0; j < 20; j = j + 1 {
    let fj = j.to_double() * 12.0
    items_b.push(
      (
        @geometry.Box3D::new(fj, fj, fj, fj + 10.0, fj + 10.0, fj + 10.0),
        100 + j,
      ),
    )
  }
  let tree_b = StrTree3D::build(items_b, node_capacity=4)

  let join_results = tree_a.spatial_join(tree_b)

  // Verify against brute-force O(N_a * N_b) pairwise scan
  let mut brute_pairs = 0
  for item_a in items_a {
    for item_b in items_b {
      if item_a.0.intersects(item_b.0) {
        brute_pairs = brute_pairs + 1
        assert_true(join_results.contains((item_a.1, item_b.1)))
      }
    }
  }
  assert_eq(join_results.length(), brute_pairs)

  // Disjoint trees
  let disjoint_items : Array[(@geometry.Box3D, Int)] = [
    (@geometry.Box3D::new(1000.0, 1000.0, 1000.0, 1010.0, 1010.0, 1010.0), 999),
  ]
  let disjoint_tree = StrTree3D::build(disjoint_items, node_capacity=4)
  assert_eq(tree_a.spatial_join(disjoint_tree), [])
}
