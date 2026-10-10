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
