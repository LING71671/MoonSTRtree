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
test "facade differential testing against brute force scan" {
  let items : Array[(Rect, Int)] = []
  // Deterministic pseudo-random generation using LCG
  let mut seed = 12345
  for i = 0; i < 200; i = i + 1 {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff
    let x = (seed % 1000).to_double()
    seed = (seed * 1103515245 + 12345) & 0x7fffffff
    let y = (seed % 1000).to_double()
    let w = (seed % 50 + 5).to_double()
    let h = (seed % 50 + 5).to_double()
    items.push((Rect::new(x, y, x + w, y + h), i))
  }

  let tree = StrTree::build(items, node_capacity=8)

  // Test across multiple query windows
  let windows = [
    Rect::new(100.0, 100.0, 300.0, 300.0),
    Rect::new(400.0, 400.0, 600.0, 600.0),
    Rect::new(0.0, 0.0, 100.0, 100.0),
    Rect::new(800.0, 800.0, 1200.0, 1200.0),
  ]

  for w = 0; w < windows.length(); w = w + 1 {
    let win = windows[w]
    let tree_hits = tree.query(win)
    tree_hits.sort()

    // Brute-force linear scan
    let brute_hits : Array[Int] = []
    for i = 0; i < items.length(); i = i + 1 {
      let (r, id) = items[i]
      if r.intersects(win) {
        brute_hits.push(id)
      }
    }
    brute_hits.sort()

    // Assert 100% equivalence
    assert_eq(tree_hits, brute_hits)
  }
}
