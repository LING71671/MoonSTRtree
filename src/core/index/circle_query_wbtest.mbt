///|
test "packed circle queries match exhaustive clamped-point distances across page sizes" {
  let items = Array::makei(10000, fn(id) {
    let x = (id * 97 % 1009).to_double() - 504.0
    let y = (id * 53 % 1013).to_double() - 506.0
    let width = (id % 23).to_double()
    let height = (id % 17).to_double()
    (@geometry.Rect::new(x, y, x + width, y + height), id * 3)
  })
  for capacity in [2, 3, 4, 16, 64, 1024] {
    let tree = StrTree::build(items, node_capacity=capacity)
    let restored = StrTree::from_flat_buffers_checked(tree.to_flat_buffers()).unwrap()
    for (cx, cy) in [(0.0, 0.0), (-504.0, -506.0), (1000.0, 1000.0)] {
      for radius in [0.0, 1.0, 5.0, 25.0, 100.0, 2000.0] {
        let expected = items
          .filter(fn(item) {
            let box = item.0
            let dx = cx - cx.max(box.min_x).min(box.max_x)
            let dy = cy - cy.max(box.min_y).min(box.max_y)
            dx * dx + dy * dy <= radius * radius
          })
          .map(fn(item) { item.1 })
        expected.sort()
        let actual = tree.query_circle(cx, cy, radius)
        actual.sort()
        assert_eq(actual, expected)
        assert_eq(tree.query_circle_count(cx, cy, radius), expected.length())
        let roundtrip = restored.query_circle(cx, cy, radius)
        roundtrip.sort()
        assert_eq(roundtrip, expected)
      }
    }
  }
}

///|
test "circle pages retain duplicate IDs, tangency, singleton and empty results" {
  let tree = StrTree::build(
    Array::makei(4097, fn(id) {
      (@geometry.Rect::from_point(3.0, 4.0), id % 11)
    }),
    node_capacity=4,
  )
  let expected = Array::makei(4097, fn(id) { id % 11 })
  expected.sort()
  let tangent = tree.query_circle(0.0, 0.0, 5.0)
  tangent.sort()
  assert_eq(tangent, expected)
  assert_eq(tree.query_circle_count(0.0, 0.0, 5.0), 4097)
  assert_eq(tree.query_circle(0.0, 0.0, 4.0), [])
  assert_eq(tree.query_circle(3.0, 4.0, -1.0), [])
  let exact = tree.query_circle(3.0, 4.0, 0.0)
  exact.sort()
  assert_eq(exact, expected)
  assert_eq(StrTree::build([]).query_circle(0.0, 0.0, 5.0), [])
  let single = StrTree::build([(@geometry.Rect::from_point(3.0, 4.0), 91)])
  assert_eq(single.query_circle(0.0, 0.0, 5.0), [91])
  assert_eq(single.query_circle(0.0, 0.0, 4.0), [])
}
