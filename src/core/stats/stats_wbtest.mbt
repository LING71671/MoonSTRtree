///|
test "stats empty tree diagnostics" {
  let tree = @tree.StrTree::build([])
  let s = TreeStats::compute(tree)

  assert_eq(s.num_items, 0)
  assert_eq(s.num_nodes, 0)
  assert_eq(s.height, 0)
  assert_eq(s.fill_factor, 1.0)
  assert_eq(s.leaf_nodes, 0)
  assert_eq(s.branch_nodes, 0)
  assert_eq(s.estimated_memory_bytes, 0)
  assert_true(TreeStats::validate_integrity(tree))
}

///|
test "stats single item tree diagnostics" {
  let item = (@geometry.Rect::new(0.0, 0.0, 10.0, 10.0), 1)
  let tree = @tree.StrTree::build([item], node_capacity=16)
  let s = TreeStats::compute(tree)

  assert_eq(s.num_items, 1)
  assert_eq(s.leaf_nodes, 1)
  assert_eq(s.branch_nodes, 1)
  assert_true(s.fill_factor > 0.0)
  assert_true(s.estimated_memory_bytes > 0)
  assert_true(TreeStats::validate_integrity(tree))
}

///|
test "stats 100 items multi-level tree integrity and fill factor" {
  let items : Array[(@geometry.Rect, Int32)] = []
  for i = 0; i < 100; i = i + 1 {
    let x = (i % 10).to_double() * 10.0
    let y = (i / 10).to_double() * 10.0
    items.push((@geometry.Rect::new(x, y, x + 8.0, y + 8.0), i))
  }
  let tree = @tree.StrTree::build(items, node_capacity=8)
  let s = TreeStats::compute(tree)

  assert_eq(s.num_items, 100)
  assert_eq(s.leaf_nodes, 100)
  assert_true(s.branch_nodes > 0)
  assert_true(s.height >= 2)
  assert_true(s.fill_factor > 0.5 && s.fill_factor <= 1.0)
  assert_true(TreeStats::validate_integrity(tree))
}
