///|
test "rect normalization swaps inverted bounds" {
  let r = Rect::new(10.0, 20.0, 0.0, 5.0)
  assert_eq(r.min_x, 0.0)
  assert_eq(r.min_y, 5.0)
  assert_eq(r.max_x, 10.0)
  assert_eq(r.max_y, 20.0)
  assert_eq(r.width(), 10.0)
  assert_eq(r.height(), 15.0)
  assert_eq(r.center_x(), 5.0)
  assert_eq(r.center_y(), 12.5)
}

///|
test "rect degenerate point from_point" {
  let pt = Rect::from_point(3.5, -4.5)
  assert_eq(pt.min_x, 3.5)
  assert_eq(pt.max_x, 3.5)
  assert_eq(pt.min_y, -4.5)
  assert_eq(pt.max_y, -4.5)
  assert_eq(pt.width(), 0.0)
  assert_eq(pt.height(), 0.0)
  assert_eq(pt.area(), 0.0)
  assert_true(pt.is_valid())
}

///|
test "rect intersects overlapping and boundary touching" {
  let a = Rect::new(0.0, 0.0, 10.0, 10.0)
  let b = Rect::new(5.0, 5.0, 15.0, 15.0)
  let c = Rect::new(10.0, 0.0, 20.0, 10.0) // touches boundary edge at x=10
  let d = Rect::new(10.0, 10.0, 20.0, 20.0) // touches corner at (10, 10)
  let disjoint = Rect::new(11.0, 11.0, 20.0, 20.0)

  assert_true(a.intersects(b))
  assert_true(b.intersects(a))
  assert_true(a.intersects(c))
  assert_true(a.intersects(d))
  assert_false(a.intersects(disjoint))
  assert_false(disjoint.intersects(a))
}

///|
test "rect contains_point inclusive boundary" {
  let r = Rect::new(-10.0, -10.0, 10.0, 10.0)
  assert_true(r.contains_point(0.0, 0.0))
  assert_true(r.contains_point(-10.0, 0.0)) // left edge
  assert_true(r.contains_point(10.0, 10.0)) // top-right corner
  assert_false(r.contains_point(10.0001, 0.0))
  assert_false(r.contains_point(-10.0001, 0.0))
}

///|
test "rect contains_rect" {
  let outer = Rect::new(-20.0, -20.0, 20.0, 20.0)
  let inner = Rect::new(-5.0, -5.0, 5.0, 5.0)
  let overlapping = Rect::new(0.0, 0.0, 30.0, 30.0)

  assert_true(outer.contains_rect(inner))
  assert_true(outer.contains_rect(outer))
  assert_false(inner.contains_rect(outer))
  assert_false(outer.contains_rect(overlapping))
}

///|
test "rect union calculation" {
  let a = Rect::new(0.0, 0.0, 5.0, 5.0)
  let b = Rect::new(-10.0, -5.0, 10.0, 15.0)
  let u = a.union(b)

  assert_eq(u.min_x, -10.0)
  assert_eq(u.min_y, -5.0)
  assert_eq(u.max_x, 10.0)
  assert_eq(u.max_y, 15.0)
}

///|
test "rect negative coordinates arithmetic" {
  let r1 = Rect::new(-50.0, -60.0, -20.0, -10.0)
  let r2 = Rect::new(-30.0, -30.0, -5.0, -5.0)

  assert_true(r1.intersects(r2))
  assert_eq(r1.width(), 30.0)
  assert_eq(r1.height(), 50.0)
  assert_eq(r1.area(), 1500.0)
  assert_eq(r1.center_x(), -35.0)
  assert_eq(r1.center_y(), -35.0)
}

///|
test "rect distance to point inside, boundary and corner" {
  let r = Rect::new(0.0, 0.0, 10.0, 10.0)

  // Point inside
  assert_eq(r.distance_squared_to_point(5.0, 5.0), 0.0)
  assert_eq(r.distance_to_point(5.0, 5.0), 0.0)

  // Point on boundary
  assert_eq(r.distance_squared_to_point(0.0, 5.0), 0.0)
  assert_eq(r.distance_to_point(10.0, 5.0), 0.0)

  // Point orthogonal edge
  assert_eq(r.distance_squared_to_point(14.0, 5.0), 16.0)
  assert_eq(r.distance_to_point(14.0, 5.0), 4.0)
  assert_eq(r.distance_squared_to_point(5.0, -3.0), 9.0)
  assert_eq(r.distance_to_point(5.0, -3.0), 3.0)

  // Point corner (3-4-5 triangle)
  assert_eq(r.distance_squared_to_point(13.0, 14.0), 25.0)
  assert_eq(r.distance_to_point(13.0, 14.0), 5.0)
}
