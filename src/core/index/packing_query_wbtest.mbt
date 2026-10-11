///|
test "partitioned packing and contained traversal agree with exhaustive ranges" {
  let items = Array::makei(513, fn(i) {
    let x = (i * 97 % 101).to_double() - 50.0
    let y = (i * 43 % 109).to_double() - 54.0
    (@geometry.Rect::new(x, y, x + (i % 19).to_double(), y + 3.0), i * 31)
  })
  for capacity in [2, 3, 16, 64, 1024] {
    let tree = StrTree::build(items, node_capacity=capacity)
    assert_true(tree.validate_integrity())
    let results : Array[Int] = [999]
    let scratch : Array[Int] = [999]
    for
      window in [
        @geometry.Rect::new(-100.0, -100.0, 100.0, 100.0),
        @geometry.Rect::new(-30.0, -40.0, 35.0, 42.0),
        @geometry.Rect::new(-12.0, -17.0, 14.0, 19.0),
        @geometry.Rect::new(100.0, 100.0, 120.0, 120.0),
        @geometry.Rect::new(0.0, 0.0, 0.0, 0.0),
      ] {
      let expected = items
        .filter(fn(item) { item.0.intersects(window) })
        .map(fn(item) { item.1 })
      tree.query_into(window, results, scratch)
      results.sort()
      expected.sort()
      assert_eq(results, expected)
      assert_true(scratch.is_empty())
      assert_eq(tree.query_count(window), expected.length())
    }
  }
}

///|
test "partition selection terminates for equal centers and extreme finite coordinates" {
  let items = Array::makei(1001, fn(i) {
    let size = (i + 1).to_double()
    (@geometry.Rect::new(-size, -size, size, size), i)
  })
  let tree = StrTree::build(items, node_capacity=3)
  assert_true(tree.validate_integrity())
  assert_eq(tree.query_point(0.0, 0.0).length(), items.length())
  let extremes = StrTree::build(
    [
      (@geometry.Rect::new(1.0e308, 1.0e308, 1.1e308, 1.1e308), 123),
      (@geometry.Rect::new(-1.1e308, -1.1e308, -1.0e308, -1.0e308), 456),
      (@geometry.Rect::from_point(0.0, 0.0), 789),
    ],
    node_capacity=2,
  )
  assert_true(extremes.validate_integrity())
  assert_eq(extremes.query_point(1.05e308, 1.05e308), [123])
}

///|
test "covering query accepts restored leaves in arbitrary node order" {
  let original = StrTree::build([
    (@geometry.Rect::from_point(1.0, 1.0), 31),
    (@geometry.Rect::from_point(2.0, 2.0), 47),
  ])
  let buffers = original.to_flat_buffers()
  // Move the root from last to first and remap all edges.
  for
    values in [
      buffers.boxes_min_x,
      buffers.boxes_min_y,
      buffers.boxes_max_x,
      buffers.boxes_max_y,
    ] {
    values.rev_in_place()
  }
  for values in [buffers.item_ids, buffers.child_count, buffers.child_offset] {
    values.rev_in_place()
  }
  for i = 0; i < buffers.child_indices.length(); i = i + 1 {
    buffers.child_indices[i] = 2 - buffers.child_indices[i]
  }
  let reordered = FlatBuffers::{ ..buffers, root_index: 0, }
  let restored = StrTree::from_flat_buffers_checked(reordered).unwrap()
  let hits = restored.query(@geometry.Rect::new(0.0, 0.0, 3.0, 3.0))
  hits.sort()
  assert_eq(hits, [31, 47])
  assert_eq(restored.query(@geometry.Rect::from_point(2.0, 2.0)), [47])
}
