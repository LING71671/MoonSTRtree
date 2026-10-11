///|
test "checked restore rejects corrupt lengths, cycles, offsets and bounds" {
  let tree = StrTree::build(
    [
      (@geometry.Rect::from_point(0.0, 0.0), 0),
      (@geometry.Rect::from_point(1.0, 1.0), 1),
    ],
    node_capacity=2,
  )
  assert_true(
    StrTree::from_flat_buffers_checked(tree.to_flat_buffers()) is Some(_),
  )
  let short = tree.to_flat_buffers()
  ignore(short.boxes_min_x.pop())
  assert_true(StrTree::from_flat_buffers_checked(short) is None)
  let cycle = tree.to_flat_buffers()
  cycle.child_indices[0] = tree.root_index()
  assert_true(StrTree::from_flat_buffers_checked(cycle) is None)
  let offset = tree.to_flat_buffers()
  offset.child_offset[tree.root_index()] = 2147483647
  assert_true(StrTree::from_flat_buffers_checked(offset) is None)
  let bounds = tree.to_flat_buffers()
  bounds.boxes_min_x[tree.root_index()] = 100.0
  assert_true(StrTree::from_flat_buffers_checked(bounds) is None)
  let duplicate = tree.to_flat_buffers()
  duplicate.child_indices[1] = duplicate.child_indices[0]
  assert_true(StrTree::from_flat_buffers_checked(duplicate) is None)
}

///|
test "checked restore handles empty and 3D indexes and owns its arrays" {
  assert_true(
    StrTree::from_flat_buffers_checked(StrTree::build([]).to_flat_buffers())
    is Some(_),
  )
  let tree = StrTree3D::build([(@geometry.Box3D::from_point(1.0, 2.0, 3.0), 7)])
  let buffers = tree.to_flat_buffers()
  let restored = StrTree3D::from_flat_buffers_checked(buffers).unwrap()
  buffers.item_ids[0] = 999
  assert_eq(restored.query_point(1.0, 2.0, 3.0), [7])
  let corrupt = tree.to_flat_buffers()
  ignore(corrupt.boxes_max_z.pop())
  assert_true(StrTree3D::from_flat_buffers_checked(corrupt) is None)
}
