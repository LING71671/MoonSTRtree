///|
test "heap hole sifting preserves ordering and node-distance association" {
  let distances : Array[Double] = []
  let nodes : Array[Int] = []
  for i = 0; i < 257; i = i + 1 {
    knn_heap_push(distances, nodes, (i * 31 % 67).to_double(), i)
  }
  let mut previous = -1.0
  let seen = Array::make(257, false)
  while !distances.is_empty() {
    let (distance, id) = knn_heap_pop(distances, nodes)
    assert_true(distance >= previous)
    assert_eq(distance, (id * 31 % 67).to_double())
    assert_true(!seen[id])
    seen[id] = true
    previous = distance
  }
  assert_true(nodes.is_empty())
  assert_true(seen.all(fn(value) { value }))
}

///|
test "bounded candidates preserve IDs and exact top-k distances through replacement and ties" {
  let source = Array::makei(1001, fn(i) { ((i * 97 % 211).to_double(), i) })
  for k in [0, 1, 10, 100, 2000] {
    let distances : Array[Double] = []
    let ids : Array[Int] = []
    for (distance, id) in source {
      insert_knn_candidate(distances, ids, k, distance, id)
    }
    sort_knn_candidates(distances, ids)
    let expected = source.map(fn(pair) { pair.0 })
    expected.sort()
    expected.truncate(k)
    assert_eq(distances, expected)
    assert_eq(ids.length(), distances.length())
    let seen = Array::make(source.length(), false)
    for i = 0; i < ids.length(); i = i + 1 {
      assert_true(!seen[ids[i]])
      assert_eq(distances[i], source[ids[i]].0)
      seen[ids[i]] = true
    }
  }
}

///|
test "large 3D nearest and filtered results preserve exact exhaustive ordering" {
  let items = Array::makei(10000, fn(i) {
    let x = (i * 71 % 997).to_double()
    let y = (i * 43 % 991).to_double()
    let z = (i * 29 % 983).to_double()
    (@geometry.Box3D::new(x, y, z, x + 3.0, y + 7.0, z + 2.0), i)
  })
  for capacity in [4, 16, 64] {
    let tree = StrTree3D::build(items, node_capacity=capacity)
    for k in [1, 10, 100, 10001] {
      let expected = items
        .filter(fn(item) { item.1 % 7 == 0 })
        .map(fn(item) { item.0.distance_squared_to_point(301.0, 407.0, 503.0) })
      expected.sort()
      expected.truncate(k)
      let actual = tree.query_knn_with_predicate_and_distance(
        301.0,
        407.0,
        503.0,
        k,
        fn(id) { id % 7 == 0 },
      )
      assert_eq(actual.map(fn(pair) { pair.1 }), expected)
      assert_true(actual.all(fn(pair) { pair.0 % 7 == 0 }))
    }
  }
}

///|
test "direct leaf nearest candidates match filtered exhaustive distances" {
  let items = Array::makei(257, fn(i) {
    (
      @geometry.Rect::from_point(
        (i * 47 % 89).to_double(),
        (i * 31 % 73).to_double(),
      ),
      i,
    )
  })
  for capacity in [2, 16, 512] {
    let tree = StrTree::build(items, node_capacity=capacity)
    for k in [1, 10, 300] {
      let expected = items
        .filter(fn(item) { item.1 % 3 == 0 })
        .map(fn(item) { item.0.distance_squared_to_point(30.0, 41.0) })
      expected.sort()
      expected.truncate(k)
      let actual = tree.query_knn_with_predicate_and_distance(30.0, 41.0, k, fn(
        id,
      ) {
        id % 3 == 0
      })
      assert_eq(actual.map(fn(pair) { pair.1 }), expected)
      assert_true(actual.all(fn(pair) { pair.0 % 3 == 0 }))
    }
  }
}
