///|
test "public trajectory lengths remain accurate across coordinate scales" {
  let large = TrajectorySegment::new(0.0, 0.0, 0.0, 3.0e12, 4.0e12, 1.0, 0, 0)
  let small = TrajectorySegment::new(0.0, 0.0, 0.0, 3.0e-12, 4.0e-12, 1.0, 0, 0)
  assert_true((large.length() / 5.0e12 - 1.0).abs() < 1.0e-12)
  assert_true((small.length() / 5.0e-12 - 1.0).abs() < 1.0e-12)
}

///|
test "reused range query buffers clear prior results including empty queries" {
  let tree = StrTree::build([(Rect::new(0.0, 0.0, 1.0, 1.0), 7)])
  let results = [999]
  let scratch = [999]
  tree.query_into(Rect::new(-1.0, -1.0, 2.0, 2.0), results, scratch)
  assert_eq(results, [7])
  assert_eq(scratch, [])
  tree.query_into(Rect::new(100.0, 100.0, 101.0, 101.0), results, scratch)
  assert_eq(results, [])
  let empty = StrTree::build([])
  results.push(42)
  scratch.push(42)
  empty.query_into(Rect::from_point(0.0, 0.0), results, scratch)
  assert_eq(results, [])
  assert_eq(scratch, [])
}

///|
test "compact DBSCAN preserves duplicate entries and sparse user IDs" {
  let tree = StrTree::build(
    [
      (Rect::from_point(0.0, 0.0), 1000000000),
      (Rect::from_point(0.0, 0.0), 1000000000),
      (Rect::from_point(100.0, 100.0), 17),
    ],
    node_capacity=2,
  )
  let compact = tree.dbscan_compact(0.0, 2)
  assert_eq(compact.item_ids.length(), 3)
  assert_eq(compact.labels.length(), 3)
  assert_eq(compact.num_clusters, 1)
  assert_eq(compact.cluster_sizes, [2])
  assert_eq(compact.num_noise, 1)
  for i = 0; i < compact.item_ids.length(); i = i + 1 {
    assert_eq(compact.labels[i], if compact.item_ids[i] == 17 { -1 } else { 0 })
  }
  let tree3d = StrTree3D::build([
    (Box3D::from_point(0.0, 0.0, 0.0), 1000000000),
    (Box3D::from_point(0.0, 0.0, 0.0), 1000000000),
    (Box3D::from_point(0.0, 0.0, 100.0), 17),
  ])
  let result3d = tree3d.dbscan_compact(0.0, 2)
  assert_eq(result3d.cluster_sizes, [2])
  assert_eq(result3d.num_noise, 1)
  assert_eq(tree.dbscan_compact(-1.0, 2).num_noise, 3)
}

///|
test "nearest APIs agree with brute force after shared traversal refactor" {
  let items = generate_uniform(Rng::new(62026), 1000)
  let tree = StrTree::build(items, node_capacity=4)
  for k in [0, 1, 7, 2000] {
    let expected : Array[(Int, Double)] = []
    for (rect, id) in items {
      if id % 3 == 0 {
        let point = Rect::from_point(371.25, 642.5)
        expected.push((id, rect.distance_squared_to_rect(point)))
      }
    }
    expected.sort_by(fn(a, b) { a.1.compare(b.1) })
    let pairs = tree.query_knn_with_predicate_and_distance(371.25, 642.5, k, fn(
      id,
    ) {
      id % 3 == 0
    })
    let ids = tree.query_knn_with_predicate(371.25, 642.5, k, fn(id) {
      id % 3 == 0
    })
    assert_eq(
      pairs.length(),
      if k < expected.length() {
        k
      } else {
        expected.length()
      },
    )
    assert_eq(ids.length(), pairs.length())
    for i = 0; i < pairs.length(); i = i + 1 {
      assert_eq(pairs[i].1, expected[i].1)
      assert_eq(pairs[i].0, ids[i])
    }
  }
  let plain = tree.query_knn(371.25, 642.5, 10)
  let distances = tree.query_knn_with_distance(371.25, 642.5, 10)
  for i = 0; i < plain.length(); i = i + 1 {
    assert_eq(plain[i], distances[i].0)
  }
}

///|
test "range traversal agrees with linear scan over 100000 reproducible items" {
  let items = generate_uniform(Rng::new(7112026), 100000)
  for capacity in [2, 16, 64] {
    let tree = StrTree::build(items, node_capacity=capacity)
    for
      window in [
        Rect::new(200.0, 200.0, 260.0, 260.0),
        Rect::new(-1.0, -1.0, 2000.0, 2000.0),
        Rect::new(-100.0, -100.0, -50.0, -50.0),
        Rect::from_point(500.0, 500.0),
      ] {
      let expected : Array[Int] = []
      for (rect, id) in items {
        if rect.intersects(window) {
          expected.push(id)
        }
      }
      let actual = tree.query(window)
      expected.sort()
      actual.sort()
      assert_eq(actual, expected)
      assert_eq(tree.query_count(window), expected.length())
    }
  }
}

///|
test "fill factor measures occupied branch slots consistently across dimensions" {
  let two = StrTree::build(
    [(Rect::from_point(0.0, 0.0), 0), (Rect::from_point(1.0, 1.0), 1)],
    node_capacity=2,
  )
  let three = StrTree3D::build(
    [
      (Box3D::from_point(0.0, 0.0, 0.0), 0),
      (Box3D::from_point(1.0, 1.0, 1.0), 1),
    ],
    node_capacity=2,
  )
  let four = StrTree4D::build(
    [
      (Box4D::from_point(0.0, 0.0, 0.0, 0.0), 0),
      (Box4D::from_point(1.0, 1.0, 1.0, 1.0), 1),
    ],
    node_capacity=2,
  )
  assert_eq(two.stats().fill_factor, 1.0)
  assert_eq(three.stats().fill_factor, 1.0)
  assert_eq(four.stats().fill_factor, 1.0)
}
