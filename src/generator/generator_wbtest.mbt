///|
test "rng determinism and range bounds" {
  let rng1 = Rng::new(42)
  let rng2 = Rng::new(42)

  let v1 = rng1.next_double()
  let v2 = rng2.next_double()
  assert_eq(v1, v2)
  assert_true(v1 >= 0.0 && v1 < 1.0)

  let r = rng1.next_range(10.0, 20.0)
  assert_true(r >= 10.0 && r < 20.0)
}

///|
test "generator uniform distribution" {
  let rng = Rng::new(101)
  let boxes = generate_uniform(rng, 50, domain_width=500.0, domain_height=500.0)
  assert_eq(boxes.length(), 50)
  for i = 0; i < boxes.length(); i = i + 1 {
    let (rect, id) = boxes[i]
    assert_eq(id, i)
    assert_true(rect.is_valid())
  }
}

///|
test "generator clustered distribution" {
  let rng = Rng::new(202)
  let boxes = generate_clustered(rng, 60, num_clusters=3)
  assert_eq(boxes.length(), 60)
  for i = 0; i < boxes.length(); i = i + 1 {
    let (rect, _) = boxes[i]
    assert_true(rect.is_valid())
  }
}

///|
test "generator diagonal distribution" {
  let rng = Rng::new(303)
  let boxes = generate_diagonal(rng, 40)
  assert_eq(boxes.length(), 40)
  for i = 0; i < boxes.length(); i = i + 1 {
    let (rect, _) = boxes[i]
    assert_true(rect.is_valid())
  }
}

///|
test "generator concentric distribution" {
  let boxes = generate_concentric(10, center_x=0.0, center_y=0.0, step=5.0)
  assert_eq(boxes.length(), 10)
  // Verify concentric nesting
  for i = 1; i < boxes.length(); i = i + 1 {
    let (outer, _) = boxes[i]
    let (inner, _) = boxes[i - 1]
    assert_true(outer.contains_rect(inner))
  }
}

///|
test "generator grid distribution" {
  let boxes = generate_grid(5, 5, cell_size=10.0, spacing=2.0)
  assert_eq(boxes.length(), 25)
  for i = 0; i < boxes.length(); i = i + 1 {
    let (rect, id) = boxes[i]
    assert_eq(id, i)
    assert_eq(rect.width(), 10.0)
    assert_eq(rect.height(), 10.0)
  }
}
