///|
test "coordinate ingestion normalizes boxes and owns its input" {
  let coordinates = [30.0, 40.0, 10.0, 20.0, -5.0, -5.0, 0.0, 0.0]
  let tree = @lib.StrTree::build_coordinates(coordinates, node_capacity=2)
  coordinates[0] = 999.0
  assert_eq(tree.query_point(15.0, 25.0), [0])
  assert_eq(tree.query_point(-1.0, -1.0), [1])
  let restored = @lib.StrTree::from_flat_buffers_checked(tree.to_flat_buffers()).unwrap()
  assert_eq(tree, restored)
  let all = restored.query(@lib.Rect::new(-100.0, -100.0, 100.0, 100.0))
  all.sort()
  assert_eq(all, [0, 1])
  assert_eq(@lib.StrTree::build_coordinates([]), @lib.StrTree::build([]))
}
