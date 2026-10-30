///|
test "tree3d query_knn and query_knn_with_distance nearest neighbor ordering" {
  let empty_tree = StrTree3D::build([])
  assert_eq(empty_tree.query_knn(0.0, 0.0, 0.0, 5), [])
  assert_eq(empty_tree.query_knn_with_distance(0.0, 0.0, 0.0, 5), [])

  // 3x3x3 = 27 items grid
  let items : Array[(@geometry.Box3D, Int32)] = []
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
  let items : Array[(@geometry.Box3D, Int32)] = []
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

  let items_a : Array[(@geometry.Box3D, Int32)] = []
  for i = 0; i < 20; i = i + 1 {
    let fi = i.to_double() * 15.0
    items_a.push(
      (@geometry.Box3D::new(fi, fi, fi, fi + 10.0, fi + 10.0, fi + 10.0), i),
    )
  }
  let tree_a = StrTree3D::build(items_a, node_capacity=4)

  let items_b : Array[(@geometry.Box3D, Int32)] = []
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
  let disjoint_items : Array[(@geometry.Box3D, Int32)] = [
    (@geometry.Box3D::new(1000.0, 1000.0, 1000.0, 1010.0, 1010.0, 1010.0), 999),
  ]
  let disjoint_tree = StrTree3D::build(disjoint_items, node_capacity=4)
  assert_eq(tree_a.spatial_join(disjoint_tree), [])
}

///|
test "tree3d query_first, query_with_predicate, and FlatBuffers3D serialization" {
  let items : Array[(@geometry.Box3D, Int32)] = []
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
