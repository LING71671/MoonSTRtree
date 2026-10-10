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
