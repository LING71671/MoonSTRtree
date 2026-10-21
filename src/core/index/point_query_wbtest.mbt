///|
test "mixed branch and leaf children use general traversal after checked restoration" {
  // Valid topology with unequal leaf depths; the root mixes a branch and a leaf.
  // This is not a homogeneous packed page even though leaves occupy a prefix.
  let buffers : FlatBuffers = {
    boxes_min_x: [0.0, 0.0, 0.0, 0.0],
    boxes_min_y: [0.0, 0.0, 0.0, 0.0],
    boxes_max_x: [10.0, 10.0, 10.0, 10.0],
    boxes_max_y: [10.0, 10.0, 10.0, 10.0],
    child_offset: [0, 0, 0, 1],
    child_count: [0, 0, 1, 2],
    child_indices: [0, 2, 1],
    item_ids: [31, 47, -1, -1],
    root_index: 3,
    node_capacity: 2,
    num_items: 2,
    height: 2,
  }
  let tree = StrTree::from_flat_buffers_checked(buffers).unwrap()
  let point = tree.query_point(5.0, 5.0)
  point.sort()
  assert_eq(point, [31, 47])
  let range = tree.query(@geometry.Rect::new(4.0, 4.0, 6.0, 6.0))
  range.sort()
  assert_eq(range, [31, 47])
  assert_eq(tree.query_point_count(5.0, 5.0), 2)
  let circle = tree.query_circle(5.0, 5.0, 1.0)
  circle.sort()
  assert_eq(circle, [31, 47])
  assert_eq(tree.query_circle_count(5.0, 5.0, 1.0), 2)
}

///|
test "packed point queries preserve inclusive boundaries and complete exhaustive results" {
  let items = Array::makei(10000, fn(id) {
    let x = (id * 97 % 1009).to_double() - 504.0
    let y = (id * 53 % 1013).to_double() - 506.0
    let width = (id % 23).to_double()
    let height = (id % 17).to_double()
    (@geometry.Rect::new(x, y, x + width, y + height), id * 3)
  })
  for capacity in [2, 4, 16, 64, 1024] {
    let tree = StrTree::build(items, node_capacity=capacity)
    for
      (x, y) in [
        (0.0, 0.0),
        (-504.0, -506.0),
        (504.0, 506.0),
        (37.0, -19.0),
        (-1000.0, 0.0),
        (1000.0, 1000.0),
      ] {
      let expected = items
        .filter(fn(item) {
          let box = item.0
          x >= box.min_x && x <= box.max_x && y >= box.min_y && y <= box.max_y
        })
        .map(fn(item) { item.1 })
      let actual = tree.query_point(x, y)
      actual.sort()
      expected.sort()
      assert_eq(actual, expected)
      assert_eq(tree.query_point_count(x, y), expected.length())
    }
  }
  assert_eq(StrTree::build([]).query_point(0.0, 0.0), [])
  let same = StrTree::build(
    Array::makei(1001, fn(id) {
      (@geometry.Rect::from_point(3.0, -5.0), id % 7)
    }),
    node_capacity=4,
  )
  let ids = same.query_point(3.0, -5.0)
  ids.sort()
  let expected = Array::makei(1001, fn(id) { id % 7 })
  expected.sort()
  assert_eq(ids, expected)
  assert_eq(same.query_point(3.0, -4.0), [])
  assert_eq(same.query_point(0.0 / 0.0, -5.0), [])
  assert_eq(same.query_point(1.0 / 0.0, -5.0), [])
}
