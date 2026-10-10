///|
test "str math primitives ceil_div and isqrt" {
  assert_eq(ceil_div(0, 16), 0)
  assert_eq(ceil_div(1, 16), 1)
  assert_eq(ceil_div(16, 16), 1)
  assert_eq(ceil_div(17, 16), 2)
  assert_eq(ceil_div(100, 16), 7)

  assert_eq(isqrt(0), 0)
  assert_eq(isqrt(1), 1)
  assert_eq(isqrt(4), 2)
  assert_eq(isqrt(24), 4)
  assert_eq(isqrt(25), 5)
  assert_eq(isqrt(26), 5)

  assert_eq(ceil_sqrt(0), 0)
  assert_eq(ceil_sqrt(1), 1)
  assert_eq(ceil_sqrt(25), 5)
  assert_eq(ceil_sqrt(26), 6)
}

///|
test "str pack empty items" {
  let res = pack_str([])
  assert_eq(res.num_items, 0)
  assert_eq(res.root_index, -1)
  assert_eq(res.height, 0)
  assert_eq(res.nodes.length(), 0)
}

///|
test "str pack single item" {
  let rect = @geometry.Rect::new(10.0, 20.0, 30.0, 40.0)
  let items = [STRItem::new(rect, 99)]
  let res = pack_str(items, node_capacity=16)

  assert_eq(res.num_items, 1)
  assert_eq(res.root_index, 1)
  assert_eq(res.height, 1)
  assert_eq(res.nodes.length(), 2)
  assert_eq(res.nodes[0].item_id, 99)
  assert_eq(res.nodes[0].rect, rect)
  assert_eq(res.nodes[1].children, [0])
  assert_eq(res.nodes[1].item_id, -1)
  assert_eq(res.nodes[1].rect, rect)
}

///|
test "str pack 16 items with capacity 4 creates multi-level hierarchy" {
  let items : Array[STRItem] = []
  for i = 0; i < 16; i = i + 1 {
    let x = (i % 4).to_double() * 10.0
    let y = (i / 4).to_double() * 10.0
    let r = @geometry.Rect::new(x, y, x + 5.0, y + 5.0)
    items.push(STRItem::new(r, i))
  }
  let res = pack_str(items, node_capacity=4)

  assert_eq(res.num_items, 16)
  assert_true(res.height >= 2)
  assert_true(res.root_index >= 0)

  // Verify root MBR bounds all 16 items
  let root = res.nodes[res.root_index]
  assert_eq(root.rect.min_x, 0.0)
  assert_eq(root.rect.min_y, 0.0)
  assert_eq(root.rect.max_x, 35.0)
  assert_eq(root.rect.max_y, 35.0)
}

///|
test "str pack negative coordinates and zero size points" {
  let items = [
    STRItem::new(@geometry.Rect::from_point(-50.0, -50.0), 1),
    STRItem::new(@geometry.Rect::from_point(-10.0, -10.0), 2),
    STRItem::new(@geometry.Rect::from_point(0.0, 0.0), 3),
    STRItem::new(@geometry.Rect::from_point(20.0, 20.0), 4),
    STRItem::new(@geometry.Rect::from_point(50.0, 50.0), 5),
  ]
  let res = pack_str(items, node_capacity=2)

  assert_eq(res.num_items, 5)
  let root = res.nodes[res.root_index]
  assert_eq(root.rect.min_x, -50.0)
  assert_eq(root.rect.min_y, -50.0)
  assert_eq(root.rect.max_x, 50.0)
  assert_eq(root.rect.max_y, 50.0)
}
