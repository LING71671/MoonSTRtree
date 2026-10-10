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

///|
test "tree3d query_first, query_with_predicate, and FlatBuffers3D serialization" {
  let items : Array[(@geometry.Box3D, Int)] = []
  for i = 0; i < 40; i = i + 1 {
    let fi = i.to_double() * 10.0
    items.push(
      (@geometry.Box3D::new(fi, fi, fi, fi + 8.0, fi + 8.0, fi + 8.0), i),
    )
  }
  let tree = StrTree3D::build(items, node_capacity=4)
  let q = @geometry.Box3D::new(15.0, 15.0, 15.0, 45.0, 45.0, 45.0)

  // 1. query_with_predicate
  let even_hits = tree.query_with_predicate(q, fn(id) { id % 2 == 0 })
  let all_hits = tree.query(q)
  for id in even_hits {
    assert_eq(id % 2, 0)
    assert_true(all_hits.contains(id))
  }

  // 2. query_first
  let first_even = tree.query_first(q, fn(id) { id % 2 == 0 })
  assert_true(first_even is Some(_))
  assert_true(even_hits.contains(first_even.unwrap()))

  let first_none = tree.query_first(q, fn(id) { id > 500 })
  assert_true(first_none is None)

  // 3. FlatBuffers3D round-trip
  let buffers = tree.to_flat_buffers()
  let reconstructed = StrTree3D::from_flat_buffers(buffers)
  assert_eq(reconstructed.num_items, tree.num_items)
  assert_eq(reconstructed.height, tree.height)
  assert_eq(reconstructed.query(q), tree.query(q))
  assert_eq(
    reconstructed.query_knn(0.0, 0.0, 0.0, 3),
    tree.query_knn(0.0, 0.0, 0.0, 3),
  )
}

///|
test "StrMeshTree3D triangle mesh building, segment testing, and ray tracing" {
  // Build a simple 3D mesh consisting of two triangles:
  // Triangle 0: at z = 10, span (0,0) to (10,10)
  let t0 = @geometry.Triangle3D::new(
    0.0, 0.0, 10.0, 10.0, 0.0, 10.0, 0.0, 10.0, 10.0,
  )
  // Triangle 1: at z = 20, span (0,0) to (10,10)
  let t1 = @geometry.Triangle3D::new(
    0.0, 0.0, 20.0, 10.0, 0.0, 20.0, 0.0, 10.0, 20.0,
  )

  let mesh = StrMeshTree3D::build([t0, t1], node_capacity=2)
  assert_eq(mesh.num_triangles(), 2)

  // 1. Box query enclosing t0
  let box0 = @geometry.Box3D::new(-1.0, -1.0, 9.0, 11.0, 11.0, 11.0)
  let box_hits = mesh.query_box(box0)
  assert_true(box_hits.contains(0))
  assert_false(box_hits.contains(1))

  // 2. Segment intersecting only t0: (2, 2, 0) -> (2, 2, 15)
  let seg0_hits = mesh.query_segment(2.0, 2.0, 0.0, 2.0, 2.0, 15.0)
  assert_eq(seg0_hits, [0])

  // 3. Segment intersecting both t0 and t1: (2, 2, 0) -> (2, 2, 30)
  let seg_both = mesh.query_segment(2.0, 2.0, 0.0, 2.0, 2.0, 30.0)
  assert_true(seg_both.contains(0))
  assert_true(seg_both.contains(1))
  assert_eq(seg_both.length(), 2)

  // 4. Ray tracing first hit from (2, 2, 0) pointing upwards (0, 0, 1)
  let first_hit = mesh.query_first_ray_hit(2.0, 2.0, 0.0, 0.0, 0.0, 1.0)
  assert_true(first_hit is Some(_))
  let (hit_id, hit_t) = first_hit.unwrap()
  assert_eq(hit_id, 0)
  assert_true((hit_t - 10.0).abs() < 0.00001)

  // 5. Ray tracing all hits sorted
  let all_hits = mesh.query_all_ray_hits(2.0, 2.0, 0.0, 0.0, 0.0, 1.0)
  assert_eq(all_hits.length(), 2)
  assert_eq(all_hits[0].0, 0)
  assert_true((all_hits[0].1 - 10.0).abs() < 0.00001)
  assert_eq(all_hits[1].0, 1)
  assert_true((all_hits[1].1 - 20.0).abs() < 0.00001)

  // 6. Ray missing both
  let miss = mesh.query_first_ray_hit(20.0, 20.0, 0.0, 0.0, 0.0, 1.0)
  assert_true(miss is None)
}

///|
test "StrTree4D spatiotemporal building, range query, point containment, and time slice" {
  let empty = StrTree4D::build([])
  assert_eq(empty.num_items, 0)
  assert_eq(
    empty.query(@geometry.Box4D::new(0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0)),
    [],
  )

  let items : Array[(@geometry.Box4D, Int)] = []
  for i = 0; i < 30; i = i + 1 {
    let fi = i.to_double() * 5.0
    items.push(
      (
        @geometry.Box4D::new(
          fi,
          fi,
          fi,
          i.to_double() * 2.0,
          fi + 10.0,
          fi + 10.0,
          fi + 10.0,
          i.to_double() * 2.0 + 4.0,
        ),
        i,
      ),
    )
  }

  let tree = StrTree4D::build(items, node_capacity=4)
  assert_eq(tree.num_items, 30)
  assert_true(tree.height >= 2)

  // 1. Range query covering first 3 items
  let q_box = @geometry.Box4D::new(0.0, 0.0, 0.0, 0.0, 12.0, 12.0, 12.0, 6.0)
  let hits = tree.query(q_box)
  assert_true(hits.contains(0))
  assert_true(hits.contains(1))
  assert_false(hits.contains(20))

  // 2. Query count zero-allocation equivalence
  let count = tree.query_count(q_box)
  assert_eq(count, hits.length())

  // 3. Point query at specific (x, y, z, t)
  let pt_hits = tree.query_point(1.0, 1.0, 1.0, 1.0)
  assert_true(pt_hits.contains(0))

  // 4. Time slice query at t = 2.0
  let slice_hits = tree.query_time_slice(
    2.0,
    @geometry.Box3D::new(0.0, 0.0, 0.0, 15.0, 15.0, 15.0),
  )
  assert_true(slice_hits.contains(0))
  assert_true(slice_hits.contains(1))

  // 5. Diagnostics stats
  let s = tree.stats()
  assert_eq(s.num_items, 30)
  assert_true(s.fill_factor > 0.0)
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
  let items_2d : Array[(@geometry.Rect, Int)] = [
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
  let items_3d : Array[(@geometry.Box3D, Int)] = [
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

///|
test "GeofenceMonitor streaming transitions" {
  let fences = [
    (@geometry.Rect::new(0.0, 0.0, 10.0, 10.0), 101),
    (@geometry.Rect::new(5.0, 5.0, 15.0, 15.0), 102),
    (@geometry.Rect::new(50.0, 50.0, 60.0, 60.0), 103),
  ]
  let monitor = GeofenceMonitor::new(fences, node_capacity=2)
  assert_eq(monitor.tracked_count(), 0)

  // Step 1: Object 1 spawns at (2, 2) -> Enters fence 101
  let events_1 = monitor.update_point(1, 2.0, 2.0)
  assert_eq(events_1.length(), 1)
  assert_eq(events_1[0], GeofenceEvent::Enter(1, 101))
  assert_eq(events_1[0].item_id(), 1)
  assert_eq(events_1[0].fence_id(), 101)
  assert_eq(events_1[0].to_string(), "Enter(1, 101)")
  assert_true(monitor.is_in_fence(1, 101))
  assert_false(monitor.is_in_fence(1, 102))
  assert_eq(monitor.tracked_count(), 1)

  // Step 2: Object 1 moves to (7, 7) -> In overlap of 101 & 102 -> Stay(1, 101) and Enter(1, 102)
  let events_2 = monitor.update_point(1, 7.0, 7.0)
  assert_eq(events_2.length(), 2)
  assert_true(events_2.contains(GeofenceEvent::Stay(1, 101)))
  assert_true(events_2.contains(GeofenceEvent::Enter(1, 102)))
  assert_true(monitor.is_in_fence(1, 101))
  assert_true(monitor.is_in_fence(1, 102))

  // Step 3: Object 1 moves to (12, 12) -> Exits 101, Stays in 102
  let events_3 = monitor.update_point(1, 12.0, 12.0)
  assert_eq(events_3.length(), 2)
  assert_true(events_3.contains(GeofenceEvent::Stay(1, 102)))
  assert_true(events_3.contains(GeofenceEvent::Exit(1, 101)))
  assert_false(monitor.is_in_fence(1, 101))
  assert_true(monitor.is_in_fence(1, 102))

  // Step 4: Rect update into fence 103
  let events_4 = monitor.update_rect(
    1,
    @geometry.Rect::new(51.0, 51.0, 55.0, 55.0),
  )
  assert_eq(events_4.length(), 2)
  assert_true(events_4.contains(GeofenceEvent::Exit(1, 102)))
  assert_true(events_4.contains(GeofenceEvent::Enter(1, 103)))
  assert_eq(monitor.active_fences(1), [103])

  // Step 5: Remove entity 1 -> Emits Exit(1, 103)
  let remove_events = monitor.remove_item(1)
  assert_eq(remove_events, [GeofenceEvent::Exit(1, 103)])
  assert_eq(monitor.tracked_count(), 0)
  assert_false(monitor.is_in_fence(1, 103))
}

///|
test "TrajectoryWindowIndex spatiotemporal sliding window" {
  let pts = [
    // Track 1: Moving from (0,0, t=0) -> (10, 10, t=10) -> (20, 20, t=20)
    TrajectoryPoint::new(0.0, 0.0, 0.0, 1),
    TrajectoryPoint::new(10.0, 10.0, 10.0, 1),
    TrajectoryPoint::new(20.0, 20.0, 20.0, 1),
    // Track 2: Moving from (5, 5, t=50) -> (15, 15, t=60)
    TrajectoryPoint::new(5.0, 5.0, 50.0, 2),
    TrajectoryPoint::new(15.0, 15.0, 60.0, 2),
  ]

  let segments = TrajectoryWindowIndex::segments_from_points(pts)
  assert_eq(segments.length(), 3)
  assert_eq(segments[0].track_id, 1)
  assert_eq(segments[1].track_id, 1)
  assert_eq(segments[2].track_id, 2)

  // Test segment properties
  let seg0 = segments[0]
  assert_eq(seg0.duration(), 10.0)
  assert_true(seg0.speed() > 1.4 && seg0.speed() < 1.42) // sqrt(200)/10 ~= 1.4142
  let interp = seg0.interpolate_position(5.0)
  match interp {
    Some((x, y)) => {
      assert_true((x - 5.0).abs() < 1.0e-5)
      assert_true((y - 5.0).abs() < 1.0e-5)
    }
    None => assert_true(false)
  }

  // Build spatiotemporal window index
  let idx = TrajectoryWindowIndex::build(segments, node_capacity=2)
  assert_eq(idx.num_segments(), 3)

  let win = @geometry.Rect::new(2.0, 2.0, 12.0, 12.0)

  // 1. Sliding window [t=0, t=15]: Should match track 1 (seg 0 and seg 1), but NOT track 2 (which is t in [50, 60])
  let hit_segs_t1 = idx.query_window(win, 0.0, 15.0)
  assert_true(hit_segs_t1.contains(0))
  assert_true(hit_segs_t1.contains(1))
  assert_false(hit_segs_t1.contains(2))

  let hit_tracks_t1 = idx.query_tracks_in_window(win, 0.0, 15.0)
  assert_eq(hit_tracks_t1, [1])

  // 2. Sliding window [t=45, t=65]: Should match track 2 (seg 2), but NOT track 1
  let hit_segs_t2 = idx.query_window(win, 45.0, 65.0)
  assert_eq(hit_segs_t2, [2])
  let hit_tracks_t2 = idx.query_tracks_in_window(win, 45.0, 65.0)
  assert_eq(hit_tracks_t2, [2])

  // 3. Sliding window [t=0, t=100]: Both tracks pass through win
  let all_tracks = idx.query_tracks_in_window(win, 0.0, 100.0)
  assert_eq(all_tracks.length(), 2)
  assert_true(all_tracks.contains(1))
  assert_true(all_tracks.contains(2))
}

///|
test "trajectory simplification 2D and SED" {
  // 1. Collinear trajectory with 5 points on y = x
  let collinear = [
    TrajectoryPoint::new(0.0, 0.0, 0.0, 1),
    TrajectoryPoint::new(2.5, 2.5, 2.5, 1),
    TrajectoryPoint::new(5.0, 5.0, 5.0, 1),
    TrajectoryPoint::new(7.5, 7.5, 7.5, 1),
    TrajectoryPoint::new(10.0, 10.0, 10.0, 1),
  ]
  let res_collinear = simplify_trajectory_2d(collinear, 0.1)
  assert_eq(res_collinear.original_count, 5)
  assert_eq(res_collinear.simplified_count, 2)
  assert_eq(res_collinear.points[0].x, 0.0)
  assert_eq(res_collinear.points[1].x, 10.0)
  assert_true(res_collinear.compression_ratio > 59.0)

  // 2. Trajectory with corner at (5, 10)
  let corner = [
    TrajectoryPoint::new(0.0, 0.0, 0.0, 1),
    TrajectoryPoint::new(5.0, 10.0, 5.0, 1), // Peak deviation
    TrajectoryPoint::new(10.0, 0.0, 10.0, 1),
  ]
  let res_kept = simplify_trajectory_2d(corner, 1.0)
  assert_eq(res_kept.simplified_count, 3) // Kept corner

  let res_culled = simplify_trajectory_2d(corner, 15.0)
  assert_eq(res_culled.simplified_count, 2) // Culled corner with large epsilon

  // 3. Spatiotemporal SED: spatially on line, but temporally distorted
  // Start (0, 0, t=0), End (10, 0, t=10). Expected at t=5 is (5, 0).
  // Middle point is at (1, 0, t=5) -> huge temporal lag (SED = 4.0).
  let temporal_lag = [
    TrajectoryPoint::new(0.0, 0.0, 0.0, 1),
    TrajectoryPoint::new(1.0, 0.0, 5.0, 1), // Distance to line is 0, but SED is 4.0!
    TrajectoryPoint::new(10.0, 0.0, 10.0, 1),
  ]
  // 2D Douglas-Peucker considers this 100% straight (perpendicular dist = 0)
  let res_geo = simplify_trajectory_2d(temporal_lag, 0.5)
  assert_eq(res_geo.simplified_count, 2) // Missed temporal variation!

  // SED preserves the temporal delay because error = 4.0 > 0.5
  let res_sed = simplify_trajectory_spatiotemporal(temporal_lag, 0.5)
  assert_eq(res_sed.simplified_count, 3) // Preserved temporal waypoint!
}

///|
test "StreamingTrajectoryCompressor online decimation" {
  let compressor = StreamingTrajectoryCompressor::new(1.0)

  // Stream in 10 collinear points along x-axis, with one corner outlier
  let _ = compressor.push(TrajectoryPoint::new(0.0, 0.0, 0.0, 1))
  let _ = compressor.push(TrajectoryPoint::new(1.0, 0.0, 1.0, 1))
  let _ = compressor.push(TrajectoryPoint::new(2.0, 0.0, 2.0, 1))
  let _ = compressor.push(TrajectoryPoint::new(3.0, 0.0, 3.0, 1))
  // Outlier at (4, 5) -> exceeds epsilon 1.0
  let _ = compressor.push(TrajectoryPoint::new(4.0, 5.0, 4.0, 1))
  let _ = compressor.push(TrajectoryPoint::new(5.0, 0.0, 5.0, 1))
  let _ = compressor.push(TrajectoryPoint::new(6.0, 0.0, 6.0, 1))
  let _ = compressor.push(TrajectoryPoint::new(7.0, 0.0, 7.0, 1))
  let _ = compressor.push(TrajectoryPoint::new(8.0, 0.0, 8.0, 1))
  let _ = compressor.push(TrajectoryPoint::new(9.0, 0.0, 9.0, 1))

  let final_pts = compressor.finish()
  assert_eq(compressor.total_received(), 10)
  assert_true(final_pts.length() < 10)
  assert_true(compressor.compression_ratio() > 40.0)
  // First point should be (0, 0) and last point should be (9, 0)
  assert_eq(final_pts[0].x, 0.0)
  assert_eq(final_pts[final_pts.length() - 1].x, 9.0)
}

///|
test "trajectory DTW distance and Sakoe-Chiba constraint" {
  let t1 = [
    TrajectoryPoint::new(0.0, 0.0, 0.0, 1),
    TrajectoryPoint::new(1.0, 1.0, 1.0, 1),
    TrajectoryPoint::new(2.0, 2.0, 2.0, 1),
  ]

  // 1. Identical trajectory
  let d_same = trajectory_dtw_distance(t1, t1)
  assert_true(d_same < 1.0e-9)

  // 2. Parallel offset by y + 2.0
  let t2 = [
    TrajectoryPoint::new(0.0, 2.0, 0.0, 2),
    TrajectoryPoint::new(1.0, 3.0, 1.0, 2),
    TrajectoryPoint::new(2.0, 4.0, 2.0, 2),
  ]
  let d_parallel = trajectory_dtw_distance(t1, t2)
  assert_true((d_parallel - 6.0).abs() < 1.0e-9)
  let d_norm = trajectory_dtw_normalized(t1, t2)
  assert_true((d_norm - 1.0).abs() < 1.0e-9) // 6.0 / (3 + 3) = 1.0

  // 3. Stretched trajectory (time warped)
  let t_stretched = [
    TrajectoryPoint::new(0.0, 0.0, 0.0, 3),
    TrajectoryPoint::new(0.5, 0.5, 0.5, 3),
    TrajectoryPoint::new(1.0, 1.0, 1.0, 3),
    TrajectoryPoint::new(1.5, 1.5, 1.5, 3),
    TrajectoryPoint::new(2.0, 2.0, 2.0, 3),
  ]
  let d_stretched = trajectory_dtw_distance(t1, t_stretched)
  assert_true((d_stretched - 1.41421356).abs() < 1.0e-4)

  // 4. Window constrained DTW
  let d_windowed = trajectory_dtw_distance(t1, t_stretched, window=2)
  assert_true((d_windowed - 1.41421356).abs() < 1.0e-4)
}

///|
test "trajectory Discrete Frechet distance" {
  let line_a = [
    TrajectoryPoint::new(0.0, 0.0, 0.0, 1),
    TrajectoryPoint::new(5.0, 0.0, 5.0, 1),
    TrajectoryPoint::new(10.0, 0.0, 10.0, 1),
  ]

  // 1. Identical line
  let f_same = trajectory_frechet_distance(line_a, line_a)
  assert_true(f_same < 1.0e-9)

  // 2. Parallel line shifted vertically by y = 4.0
  let line_b = [
    TrajectoryPoint::new(0.0, 4.0, 0.0, 2),
    TrajectoryPoint::new(5.0, 4.0, 5.0, 2),
    TrajectoryPoint::new(10.0, 4.0, 10.0, 2),
  ]
  let f_parallel = trajectory_frechet_distance(line_a, line_b)
  assert_true((f_parallel - 4.0).abs() < 1.0e-9)

  // 3. Curve with a bulge: midpoint deviates to y = 8.0
  let line_bulge = [
    TrajectoryPoint::new(0.0, 0.0, 0.0, 3),
    TrajectoryPoint::new(5.0, 8.0, 5.0, 3), // Bottleneck point
    TrajectoryPoint::new(10.0, 0.0, 10.0, 3),
  ]
  let f_bulge = trajectory_frechet_distance(line_a, line_bulge)
  assert_true((f_bulge - 8.0).abs() < 1.0e-9)
}
