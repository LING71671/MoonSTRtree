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
