///|
test "facade rect primitives and operations" {
  let r1 = Rect::new(0.0, 0.0, 10.0, 10.0)
  let r2 = Rect::new(5.0, 5.0, 15.0, 15.0)

  assert_true(r1.intersects(r2))
  assert_true(r1.contains_point(5.0, 5.0))
  assert_false(r1.contains_point(15.0, 15.0))

  let u = r1.union(r2)
  assert_eq(u.min_x, 0.0)
  assert_eq(u.max_x, 15.0)
}

///|
test "facade tree build and inverted query window fix verification" {
  let items : Array[(Rect, Int)] = [
    (Rect::new(0.0, 0.0, 10.0, 10.0), 1),
    (Rect::new(20.0, 20.0, 30.0, 30.0), 2),
    (Rect::new(40.0, 40.0, 50.0, 50.0), 3),
  ]
  let tree = StrTree::build(items, node_capacity=2)

  // Verify normal query
  let hits = tree.query(Rect::new(5.0, 5.0, 25.0, 25.0))
  hits.sort()
  assert_eq(hits, [1, 2])

  // Verify inverted window (min > max) is normalized properly
  let inverted_win = Rect::new(25.0, 25.0, 5.0, 5.0)
  let inv_hits = tree.query(inverted_win)
  inv_hits.sort()
  assert_eq(inv_hits, [1, 2])

  // Verify stats
  let s = tree.stats()
  assert_eq(s.num_items, 3)
  assert_true(s.fill_factor > 0.0)
}

///|
test "facade differential testing on 1000 uniform rectangles" {
  let rng = Rng::new(54321)
  let items = generate_uniform(
    rng,
    1000,
    domain_width=2000.0,
    domain_height=2000.0,
  )
  let tree = StrTree::build(items, node_capacity=16)

  let windows = [
    Rect::new(200.0, 200.0, 600.0, 600.0),
    Rect::new(800.0, 800.0, 1400.0, 1400.0),
    Rect::new(0.0, 0.0, 200.0, 200.0),
    Rect::new(1800.0, 1800.0, 2100.0, 2100.0),
  ]

  for w = 0; w < windows.length(); w = w + 1 {
    let win = windows[w]
    let tree_hits = tree.query(win)
    tree_hits.sort()

    let brute_hits : Array[Int] = []
    for i = 0; i < items.length(); i = i + 1 {
      let (r, id) = items[i]
      if r.intersects(win) {
        brute_hits.push(id)
      }
    }
    brute_hits.sort()
    assert_eq(tree_hits, brute_hits)
  }
}

///|
test "facade differential testing on 1000 clustered gaussian rectangles" {
  let rng = Rng::new(99887)
  let items = generate_clustered(
    rng,
    1000,
    num_clusters=6,
    domain_width=2000.0,
    domain_height=2000.0,
  )
  let tree = StrTree::build(items, node_capacity=16)

  let windows = [
    Rect::new(100.0, 100.0, 500.0, 500.0),
    Rect::new(800.0, 800.0, 1200.0, 1200.0),
    Rect::new(1400.0, 1400.0, 1900.0, 1900.0),
  ]

  for w = 0; w < windows.length(); w = w + 1 {
    let win = windows[w]
    let tree_hits = tree.query(win)
    tree_hits.sort()

    let brute_hits : Array[Int] = []
    for i = 0; i < items.length(); i = i + 1 {
      let (r, id) = items[i]
      if r.intersects(win) {
        brute_hits.push(id)
      }
    }
    brute_hits.sort()
    assert_eq(tree_hits, brute_hits)
  }
}

///|
test "facade differential testing on 500 diagonal collinear rectangles" {
  let rng = Rng::new(11223)
  let items = generate_diagonal(rng, 500, domain_size=1500.0)
  let tree = StrTree::build(items, node_capacity=8)

  let windows = [
    Rect::new(200.0, 200.0, 400.0, 400.0),
    Rect::new(700.0, 700.0, 1000.0, 1000.0),
    Rect::new(1200.0, 1200.0, 1600.0, 1600.0),
  ]

  for w = 0; w < windows.length(); w = w + 1 {
    let win = windows[w]
    let tree_hits = tree.query(win)
    tree_hits.sort()

    let brute_hits : Array[Int] = []
    for i = 0; i < items.length(); i = i + 1 {
      let (r, id) = items[i]
      if r.intersects(win) {
        brute_hits.push(id)
      }
    }
    brute_hits.sort()
    assert_eq(tree_hits, brute_hits)
  }
}

///|
test "facade differential testing on 200 concentric nested rectangles" {
  let items = generate_concentric(200, center_x=0.0, center_y=0.0, step=3.0)
  let tree = StrTree::build(items, node_capacity=16)

  // Point query at center must hit all 200 rectangles
  let center_hits = tree.query_point(0.0, 0.0)
  assert_eq(center_hits.length(), 200)

  // Point query at distance 30.5 (radius 30 covers first 10, radius 33 covers from 11th)
  let pt_hits = tree.query_point(30.5, 0.0)
  // First 10 rectangles have radius <= 30, so they don't cover (30.5, 0)
  assert_eq(pt_hits.length(), 190)
}

///|
test "facade differential testing on 400 grid tile rectangles" {
  let items = generate_grid(20, 20, cell_size=10.0, spacing=2.0)
  let tree = StrTree::build(items, node_capacity=16)

  // Point query exactly inside cell (5, 5) -> x = 5*12 = 60, y = 5*12 = 60
  let pt_hits = tree.query_point(65.0, 65.0)
  assert_eq(pt_hits.length(), 1)
  assert_eq(pt_hits[0], 5 * 20 + 5)

  // Point query in gap between cells
  let gap_hits = tree.query_point(71.0, 65.0)
  assert_eq(gap_hits.length(), 0)
}

///|
test "facade differential testing for query_knn" {
  let rng = Rng::new(98765)
  let items = generate_uniform(
    rng,
    300,
    domain_width=1000.0,
    domain_height=1000.0,
  )
  let tree = StrTree::build(items, node_capacity=8)

  let test_points = [(500.0, 500.0), (100.0, 900.0), (-50.0, -50.0)]
  for p = 0; p < test_points.length(); p = p + 1 {
    let (px, py) = test_points[p]
    let k = 10
    let knn_ids = tree.query_knn(px, py, k)

    // Brute force: compute dist_sq to each item box
    let item_dists : Array[(Double, Int)] = []
    for i = 0; i < items.length(); i = i + 1 {
      let (r, id) = items[i]
      let dx = if px < r.min_x {
        r.min_x - px
      } else if px > r.max_x {
        px - r.max_x
      } else {
        0.0
      }
      let dy = if py < r.min_y {
        r.min_y - py
      } else if py > r.max_y {
        py - r.max_y
      } else {
        0.0
      }
      item_dists.push((dx * dx + dy * dy, id))
    }

    // Sort by ascending distance
    item_dists.sort_by(fn(a, b) {
      if a.0 < b.0 {
        -1
      } else if a.0 > b.0 {
        1
      } else {
        a.1 - b.1
      }
    })

    assert_eq(knn_ids.length(), k)
    for i = 0; i < k; i = i + 1 {
      let tree_id = knn_ids[i]
      let mut found_dist = -1.0
      for j = 0; j < items.length(); j = j + 1 {
        if items[j].1 == tree_id {
          let r = items[j].0
          let dx = if px < r.min_x {
            r.min_x - px
          } else if px > r.max_x {
            px - r.max_x
          } else {
            0.0
          }
          let dy = if py < r.min_y {
            r.min_y - py
          } else if py > r.max_y {
            py - r.max_y
          } else {
            0.0
          }
          found_dist = dx * dx + dy * dy
          break
        }
      }
      assert_eq(found_dist, item_dists[i].0)
    }
  }
}

///|
test "facade differential testing for query_segment against brute-force scan" {
  let rng = Rng::new(13579)
  let items = generate_uniform(
    rng,
    500,
    domain_width=1000.0,
    domain_height=1000.0,
  )
  let tree = StrTree::build(items, node_capacity=16)

  let segments = [
    (0.0, 0.0, 1000.0, 1000.0), // diagonal spanning domain
    (200.0, 500.0, 800.0, 500.0), // horizontal cut across middle
    (500.0, 100.0, 500.0, 900.0), // vertical cut across middle
    (-100.0, -100.0, -10.0, -10.0), // disjoint segment outside domain
  ]

  for s = 0; s < segments.length(); s = s + 1 {
    let (x1, y1, x2, y2) = segments[s]
    let tree_hits = tree.query_segment(x1, y1, x2, y2)
    tree_hits.sort()

    let brute_hits : Array[Int] = []
    for i = 0; i < items.length(); i = i + 1 {
      let (r, id) = items[i]
      if r.intersects_segment(x1, y1, x2, y2) {
        brute_hits.push(id)
      }
    }
    brute_hits.sort()

    assert_eq(tree_hits, brute_hits)
  }
}

///|
test "facade differential testing for spatial_join against brute-force cross product" {
  let rng_a = Rng::new(24680)
  let rng_b = Rng::new(13579)

  let items_a = generate_uniform(
    rng_a,
    150,
    domain_width=500.0,
    domain_height=500.0,
  )
  let items_b = generate_clustered(
    rng_b,
    150,
    num_clusters=4,
    domain_width=500.0,
    domain_height=500.0,
  )

  let tree_a = StrTree::build(items_a, node_capacity=8)
  let tree_b = StrTree::build(items_b, node_capacity=8)

  let join_pairs = tree_a.spatial_join(tree_b)
  join_pairs.sort_by(fn(x, y) { if x.0 != y.0 { x.0 - y.0 } else { x.1 - y.1 } })

  // Brute force quadratic intersection check
  let brute_pairs : Array[(Int, Int)] = []
  for i = 0; i < items_a.length(); i = i + 1 {
    let (ra, ida) = items_a[i]
    for j = 0; j < items_b.length(); j = j + 1 {
      let (rb, idb) = items_b[j]
      if ra.intersects(rb) {
        brute_pairs.push((ida, idb))
      }
    }
  }
  brute_pairs.sort_by(fn(x, y) {
    if x.0 != y.0 {
      x.0 - y.0
    } else {
      x.1 - y.1
    }
  })

  assert_eq(join_pairs, brute_pairs)
}

///|
test "facade flat buffers round trip and identical query execution" {
  let rng = Rng::new(55555)
  let items = generate_uniform(
    rng,
    100,
    domain_width=500.0,
    domain_height=500.0,
  )
  let tree = StrTree::build(items, node_capacity=8)

  let buf = tree.to_flat_buffers()
  let loaded_tree = StrTree::from_flat_buffers(buf)

  let q = Rect::new(100.0, 100.0, 300.0, 300.0)
  assert_eq(loaded_tree.query(q), tree.query(q))

  let pt_hits = loaded_tree.query_point(250.0, 250.0)
  assert_eq(pt_hits, tree.query_point(250.0, 250.0))

  let knn = loaded_tree.query_knn(200.0, 200.0, 5)
  assert_eq(knn, tree.query_knn(200.0, 200.0, 5))
}

///|
test "facade rect intersection, expand, distance_to_rect and iou" {
  let r1 = Rect::new(0.0, 0.0, 10.0, 10.0)
  let r2 = Rect::new(5.0, 5.0, 15.0, 15.0)

  let inter = r1.intersection(r2)
  assert_true(inter is Some(_))
  let inter_rect = inter.unwrap()
  assert_eq(inter_rect.min_x, 5.0)
  assert_eq(inter_rect.min_y, 5.0)
  assert_eq(inter_rect.max_x, 10.0)
  assert_eq(inter_rect.max_y, 10.0)

  let exp = r1.expand(5.0)
  assert_eq(exp.min_x, -5.0)
  assert_eq(exp.min_y, -5.0)
  assert_eq(exp.max_x, 15.0)
  assert_eq(exp.max_y, 15.0)

  let r3 = Rect::new(20.0, 0.0, 30.0, 10.0)
  assert_eq(r1.distance_squared_to_rect(r3), 100.0)
  assert_eq(r1.distance_to_rect(r3), 10.0)

  let iou_val = r1.iou(r2)
  let diff = iou_val - 1.0 / 7.0
  let abs_diff = if diff < 0.0 { -diff } else { diff }
  assert_true(abs_diff < 0.000001)
}

///|
test "facade query_count, query_point_count, query_first, and query_with_predicate" {
  let rng = Rng::new(9999)
  let items = generate_uniform(
    rng,
    150,
    domain_width=500.0,
    domain_height=500.0,
  )
  let tree = StrTree::build(items, node_capacity=8)

  let win = Rect::new(100.0, 100.0, 300.0, 300.0)
  let hits = tree.query(win)
  let count = tree.query_count(win)
  assert_eq(count, hits.length())

  let pt_hits = tree.query_point(200.0, 200.0)
  let pt_count = tree.query_point_count(200.0, 200.0)
  assert_eq(pt_count, pt_hits.length())

  // Predicate: only IDs divisible by 3
  let mod3_hits = tree.query_with_predicate(win, fn(id) { id % 3 == 0 })
  for id in mod3_hits {
    assert_true(id % 3 == 0)
    assert_true(hits.contains(id))
  }

  // First item matching
  let first_match = tree.query_first(win, fn(id) { id % 3 == 0 })
  if mod3_hits.length() > 0 {
    assert_true(first_match is Some(_))
    assert_true(first_match.unwrap() % 3 == 0)
  } else {
    assert_true(first_match is None)
  }
}

///|
test "facade rect intersects_circle and StrTree query_circle / query_circle_count" {
  let r = Rect::new(0.0, 0.0, 10.0, 10.0)
  assert_true(r.intersects_circle(5.0, 5.0, 2.0))
  assert_true(r.intersects_circle(12.0, 5.0, 2.0))
  assert_false(r.intersects_circle(12.0, 5.0, 1.9))

  let rng = Rng::new(12345)
  let items = generate_uniform(
    rng,
    100,
    domain_width=500.0,
    domain_height=500.0,
  )
  let tree = StrTree::build(items, node_capacity=8)

  let cx = 250.0
  let cy = 250.0
  let radius = 100.0

  let circle_hits = tree.query_circle(cx, cy, radius)
  let circle_count = tree.query_circle_count(cx, cy, radius)
  assert_eq(circle_count, circle_hits.length())

  // Verify against brute-force scan
  let mut brute_hits = 0
  for item in items {
    let (rect, id) = item
    if rect.intersects_circle(cx, cy, radius) {
      brute_hits = brute_hits + 1
      assert_true(circle_hits.contains(id))
    }
  }
  assert_eq(circle_hits.length(), brute_hits)
}

///|
test "facade box3d basic operations and volume calculation" {
  let b = Box3D::new(0.0, 0.0, 0.0, 10.0, 10.0, 10.0)
  assert_eq(b.volume(), 1000.0)
  assert_eq(b.surface_area(), 600.0)
  assert_true(b.contains_point(5.0, 5.0, 5.0))
  assert_false(b.contains_point(15.0, 5.0, 5.0))

  let b2 = Box3D::new(5.0, 5.0, 5.0, 15.0, 15.0, 15.0)
  assert_true(b.intersects(b2))
  let inter = b.intersection(b2)
  assert_true(inter is Some(_))
  assert_eq(inter.unwrap().volume(), 125.0)

  let b_far = Box3D::new(20.0, 20.0, 20.0, 30.0, 30.0, 30.0)
  assert_false(b.intersects(b_far))
  assert_true(b.intersection(b_far) is None)

  // Distance to box
  assert_eq(b.distance_to_box(b2), 0.0)
  // Distance from (0,0,0)-(10,10,10) to (20,20,20)-(30,30,30): dx=10, dy=10, dz=10 -> sqrt(300) = 17.320508...
  let d_far = b.distance_to_box(b_far)
  let diff_d = d_far - (300.0 : Double).sqrt()
  let abs_diff_d = if diff_d < 0.0 { -diff_d } else { diff_d }
  assert_true(abs_diff_d < 0.0000001)

  // IoU
  let expected_iou = 125.0 / 1875.0
  let diff_iou = b.iou(b2) - expected_iou
  let abs_diff_iou = if diff_iou < 0.0 { -diff_iou } else { diff_iou }
  assert_true(abs_diff_iou < 0.0000001)
  assert_eq(b.iou(b_far), 0.0)

  // Intersects sphere
  assert_true(b.intersects_sphere(5.0, 5.0, 5.0, 1.0))
  assert_true(b.intersects_sphere(13.0, 5.0, 5.0, 3.0))
  assert_false(b.intersects_sphere(13.0, 5.0, 5.0, 2.9))
}

///|
test "facade query_knn_with_distance consistency with query_knn" {
  let rng = Rng::new(54321)
  let items = generate_uniform(rng, 50, domain_width=300.0, domain_height=300.0)
  let tree = StrTree::build(items, node_capacity=4)

  let px = 150.0
  let py = 150.0
  let k = 5

  let knn_ids = tree.query_knn(px, py, k)
  let knn_pairs = tree.query_knn_with_distance(px, py, k)

  assert_eq(knn_ids.length(), knn_pairs.length())
  for i = 0; i < knn_ids.length(); i = i + 1 {
    assert_eq(knn_ids[i], knn_pairs[i].0)
    // Distances must be monotonically ascending
    if i > 0 {
      assert_true(knn_pairs[i - 1].1 <= knn_pairs[i].1)
    }
  }
}

///|
test "facade query_knn_with_predicate filters even IDs and sorts monotonically" {
  let rng = Rng::new(99887)
  let items = generate_uniform(rng, 60, domain_width=400.0, domain_height=400.0)
  let tree = StrTree::build(items, node_capacity=4)

  let px = 200.0
  let py = 200.0
  let k = 6

  // Query only even IDs
  let even_knn = tree.query_knn_with_predicate(px, py, k, fn(id) { id % 2 == 0 })
  let even_knn_pairs = tree.query_knn_with_predicate_and_distance(px, py, k, fn(
    id,
  ) {
    id % 2 == 0
  })

  assert_eq(even_knn.length(), even_knn_pairs.length())
  assert_true(even_knn.length() <= k)

  for i = 0; i < even_knn.length(); i = i + 1 {
    let id = even_knn[i]
    assert_eq(id % 2, 0)
    assert_eq(id, even_knn_pairs[i].0)
    if i > 0 {
      assert_true(even_knn_pairs[i - 1].1 <= even_knn_pairs[i].1)
    }
  }
}

///|
test "facade strtree3d range, point, sphere, and brute-force equivalence" {
  let rng = Rng::new(777123)
  let items = generate_boxes_3d_uniform(
    rng,
    100,
    domain_x=500.0,
    domain_y=500.0,
    domain_z=500.0,
    max_box_size=30.0,
  )
  let tree3d = StrTree3D::build(items, node_capacity=8)

  let stats = tree3d.stats()
  assert_eq(stats.num_items, 100)
  assert_true(stats.height >= 2)
  assert_true(stats.fill_factor > 0.0)

  // 1. Range query brute-force equivalence
  let search_box = Box3D::new(100.0, 100.0, 100.0, 250.0, 250.0, 250.0)
  let hits = tree3d.query(search_box)
  let hit_count = tree3d.query_count(search_box)
  assert_eq(hits.length(), hit_count)

  let mut bf_count = 0
  for i = 0; i < items.length(); i = i + 1 {
    let (b, id) = items[i]
    if b.intersects(search_box) {
      bf_count = bf_count + 1
      assert_true(hits.contains(id))
    }
  }
  assert_eq(hits.length(), bf_count)

  // 2. Point query brute-force equivalence
  let px = 200.0
  let py = 200.0
  let pz = 200.0
  let point_hits = tree3d.query_point(px, py, pz)
  for i = 0; i < items.length(); i = i + 1 {
    let (b, id) = items[i]
    if b.contains_point(px, py, pz) {
      assert_true(point_hits.contains(id))
    }
  }

  // 3. Sphere query
  let sphere_hits = tree3d.query_sphere(250.0, 250.0, 250.0, 50.0)
  for i = 0; i < items.length(); i = i + 1 {
    let (b, id) = items[i]
    if b.intersects_sphere(250.0, 250.0, 250.0, 50.0) {
      assert_true(sphere_hits.contains(id))
    }
  }
}

///|
test "facade differential testing for 3D k-NN, segment, and counting queries" {
  let rng = Rng::new(98765)
  let items = generate_boxes_3d_uniform(
    rng,
    60,
    domain_x=300.0,
    domain_y=300.0,
    domain_z=300.0,
  )
  let tree3d = StrTree3D::build(items, node_capacity=4)

  // 1. 3D k-NN query
  let qx = 150.0
  let qy = 150.0
  let qz = 150.0
  let knn_ids = tree3d.query_knn(qx, qy, qz, 5)
  let knn_dists = tree3d.query_knn_with_distance(qx, qy, qz, 5)
  assert_eq(knn_ids.length(), 5)
  assert_eq(knn_dists.length(), 5)
  for i = 0; i < 5; i = i + 1 {
    assert_eq(knn_ids[i], knn_dists[i].0)
  }
  for i = 0; i < 4; i = i + 1 {
    assert_true(knn_dists[i].1 <= knn_dists[i + 1].1)
  }

  // 2. 3D Segment query
  let seg_hits = tree3d.query_segment(0.0, 0.0, 0.0, 300.0, 300.0, 300.0)
  let mut bf_seg = 0
  for i = 0; i < items.length(); i = i + 1 {
    let (b, id) = items[i]
    if b.intersects_segment(0.0, 0.0, 0.0, 300.0, 300.0, 300.0) {
      bf_seg = bf_seg + 1
      assert_true(seg_hits.contains(id))
    }
  }
  assert_eq(seg_hits.length(), bf_seg)

  // 3. Counting queries equivalence
  let pt_cnt = tree3d.query_point_count(qx, qy, qz)
  assert_eq(pt_cnt, tree3d.query_point(qx, qy, qz).length())

  let sp_cnt = tree3d.query_sphere_count(qx, qy, qz, 40.0)
  assert_eq(sp_cnt, tree3d.query_sphere(qx, qy, qz, 40.0).length())
}

///|
test "facade differential testing for 3D spatial_join, query_first, and FlatBuffers3D" {
  let rng_a = Rng::new(12345)
  let rng_b = Rng::new(67890)
  let items_a = generate_boxes_3d_uniform(
    rng_a,
    25,
    domain_x=100.0,
    domain_y=100.0,
    domain_z=100.0,
  )
  let items_b = generate_boxes_3d_uniform(
    rng_b,
    25,
    domain_x=100.0,
    domain_y=100.0,
    domain_z=100.0,
  )

  let tree_a = StrTree3D::build(items_a, node_capacity=4)
  let tree_b = StrTree3D::build(items_b, node_capacity=4)

  // 1. Spatial join
  let pairs = tree_a.spatial_join(tree_b)
  let mut bf_pairs = 0
  for i = 0; i < items_a.length(); i = i + 1 {
    for j = 0; j < items_b.length(); j = j + 1 {
      if items_a[i].0.intersects(items_b[j].0) {
        bf_pairs = bf_pairs + 1
        assert_true(pairs.contains((items_a[i].1, items_b[j].1)))
      }
    }
  }
  assert_eq(pairs.length(), bf_pairs)

  // 2. Query with predicate and query_first
  let search_box = Box3D::new(10.0, 10.0, 10.0, 60.0, 60.0, 60.0)
  let odd_hits = tree_a.query_with_predicate(search_box, fn(id) { id % 2 != 0 })
  for id in odd_hits {
    assert_true(id % 2 != 0)
  }
  let first_odd = tree_a.query_first(search_box, fn(id) { id % 2 != 0 })
  if !odd_hits.is_empty() {
    assert_true(first_odd is Some(_))
    assert_true(odd_hits.contains(first_odd.unwrap()))
  }

  // 3. FlatBuffers3D persistence
  let buffers = tree_a.to_flat_buffers()
  let reloaded = StrTree3D::from_flat_buffers(buffers)
  assert_eq(reloaded.query(search_box), tree_a.query(search_box))
}

///|
test "facade differential testing for Triangle3D and StrMeshTree3D" {
  let t0 = Triangle3D::new(0.0, 0.0, 5.0, 20.0, 0.0, 5.0, 0.0, 20.0, 5.0)
  let t1 = Triangle3D::new(0.0, 0.0, 15.0, 20.0, 0.0, 15.0, 0.0, 20.0, 15.0)

  // Triangle methods
  let (cx, cy, cz) = t0.centroid()
  assert_true((cx - 20.0 / 3.0).abs() < 0.00001)
  assert_true((cy - 20.0 / 3.0).abs() < 0.00001)
  assert_true((cz - 5.0).abs() < 0.00001)
  assert_true((t0.area() - 200.0).abs() < 0.00001)

  // StrMeshTree3D
  let mesh = StrMeshTree3D::build([t0, t1], node_capacity=2)
  assert_eq(mesh.num_triangles(), 2)

  // Query segment
  let seg_hits = mesh.query_segment(5.0, 5.0, 0.0, 5.0, 5.0, 10.0)
  assert_eq(seg_hits, [0])

  // Ray hits
  let first_hit = mesh.query_first_ray_hit(5.0, 5.0, 0.0, 0.0, 0.0, 1.0)
  assert_true(first_hit is Some(_))
  assert_eq(first_hit.unwrap().0, 0)
  assert_true((first_hit.unwrap().1 - 5.0).abs() < 0.00001)

  let all_hits = mesh.query_all_ray_hits(5.0, 5.0, 0.0, 0.0, 0.0, 1.0)
  assert_eq(all_hits.length(), 2)
  assert_eq(all_hits[0].0, 0)
  assert_eq(all_hits[1].0, 1)
}

///|
test "facade differential testing for Box4D and StrTree4D" {
  let items : Array[(Box4D, Int)] = [
    (Box4D::new(0.0, 0.0, 0.0, 0.0, 10.0, 10.0, 10.0, 5.0), 1),
    (Box4D::new(20.0, 20.0, 20.0, 0.0, 30.0, 30.0, 30.0, 5.0), 2),
    (Box4D::new(0.0, 0.0, 0.0, 10.0, 10.0, 10.0, 10.0, 15.0), 3),
  ]

  let tree = StrTree4D::build(items, node_capacity=2)
  assert_eq(tree.stats().num_items, 3)

  // 1. Point query
  let pt_hits = tree.query_point(5.0, 5.0, 5.0, 2.0)
  assert_eq(pt_hits, [1])

  // 2. Range query
  let q_hits = tree.query(Box4D::new(0.0, 0.0, 0.0, 0.0, 25.0, 25.0, 25.0, 6.0))
  assert_true(q_hits.contains(1))
  assert_true(q_hits.contains(2))
  assert_false(q_hits.contains(3))

  // 3. Time slice query at t = 12.0
  let slice_hits = tree.query_time_slice(
    12.0,
    Box3D::new(0.0, 0.0, 0.0, 10.0, 10.0, 10.0),
  )
  assert_eq(slice_hits, [3])
}

///|
test "facade spatial predicate queries, relates, and hierarchical joins" {
  let r1 = Rect::new(0.0, 0.0, 10.0, 10.0)
  let r_disjoint = Rect::new(20.0, 20.0, 30.0, 30.0)
  let r_touch = Rect::new(10.0, 0.0, 20.0, 10.0)

  // 1. Relate matrix string & pattern matching
  let mat = r1.relate(r_disjoint)
  assert_eq(mat, "FF2FF1212")
  assert_true(matches_de9im_pattern(mat, "FF*FF****"))
  assert_false(matches_de9im_pattern(mat, "T********"))

  // 2. SpatialPredicate enum string conversions
  let pred_opt = SpatialPredicate::from_string("touches")
  assert_true(pred_opt is Some(_))
  assert_eq(pred_opt.unwrap().to_string(), "touches")

  // 3. Tree predicate query & spatial join
  let tree_a = StrTree::build([(r1, 1), (r_touch, 2)], node_capacity=2)
  let touch_hits = tree_a.query_spatial_predicate(
    r_touch,
    SpatialPredicate::Touches,
  )
  assert_eq(touch_hits, [1])

  let tree_b = StrTree::build(
    [
      (Rect::new(5.0, 0.0, 15.0, 10.0), 10),
      (Rect::new(100.0, 100.0, 110.0, 110.0), 20),
    ],
    node_capacity=2,
  )
  let join_hits = tree_a.spatial_join_predicate(
    tree_b,
    SpatialPredicate::Overlaps,
  )
  assert_true(join_hits.contains((1, 10)))
  assert_true(join_hits.contains((2, 10)))
  assert_false(join_hits.contains((1, 20)))
}
