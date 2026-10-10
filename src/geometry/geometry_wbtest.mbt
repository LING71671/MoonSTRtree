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

///|
test "rect intersects_segment through, inside, touching and disjoint" {
  let r = Rect::new(0.0, 0.0, 10.0, 10.0)

  // Segment piercing right through center
  assert_true(r.intersects_segment(-5.0, 5.0, 15.0, 5.0))
  // Diagonal segment cutting through
  assert_true(r.intersects_segment(-2.0, -2.0, 12.0, 12.0))

  // Segment completely inside
  assert_true(r.intersects_segment(2.0, 3.0, 7.0, 8.0))

  // One endpoint inside, one outside
  assert_true(r.intersects_segment(5.0, 5.0, 20.0, 20.0))

  // Touching corner (0, 0)
  assert_true(r.intersects_segment(-5.0, 0.0, 0.0, 0.0))

  // Collinear along top edge y=10
  assert_true(r.intersects_segment(2.0, 10.0, 8.0, 10.0))

  // Disjoint: parallel above
  assert_false(r.intersects_segment(-5.0, 12.0, 15.0, 12.0))
  // Disjoint: off to the side
  assert_false(r.intersects_segment(12.0, -5.0, 15.0, 15.0))

  // Vertical line
  assert_true(r.intersects_segment(5.0, -10.0, 5.0, 20.0))
  assert_false(r.intersects_segment(15.0, -10.0, 15.0, 20.0))

  // Degenerate zero-length segment (point)
  assert_true(r.intersects_segment(5.0, 5.0, 5.0, 5.0))
  assert_false(r.intersects_segment(15.0, 15.0, 15.0, 15.0))
}

///|
test "rect intersection, expand, distance_to_rect, and iou" {
  let a = Rect::new(0.0, 0.0, 10.0, 10.0)
  let b = Rect::new(5.0, 5.0, 15.0, 15.0)

  // Intersection
  let inter = a.intersection(b)
  assert_true(inter is Some(_))
  let rect_inter = inter.unwrap()
  assert_eq(rect_inter.min_x, 5.0)
  assert_eq(rect_inter.min_y, 5.0)
  assert_eq(rect_inter.max_x, 10.0)
  assert_eq(rect_inter.max_y, 10.0)
  assert_eq(rect_inter.area(), 25.0)

  // Disjoint intersection
  let c = Rect::new(20.0, 20.0, 30.0, 30.0)
  assert_true(a.intersection(c) is None)

  // Expand
  let expanded = a.expand(2.0)
  assert_eq(expanded.min_x, -2.0)
  assert_eq(expanded.min_y, -2.0)
  assert_eq(expanded.max_x, 12.0)
  assert_eq(expanded.max_y, 12.0)

  // Distance between rectangles
  assert_eq(a.distance_squared_to_rect(b), 0.0)
  assert_eq(a.distance_to_rect(b), 0.0)

  // Disjoint distance: a is [0, 10] x [0, 10], c is [20, 30] x [20, 30]
  // dx = 20 - 10 = 10, dy = 20 - 10 = 10 -> sq = 200
  assert_eq(a.distance_squared_to_rect(c), 200.0)

  // Disjoint horizontal: d is [15, 20] x [0, 10] -> dx = 5, dy = 0 -> sq = 25, dist = 5
  let d = Rect::new(15.0, 0.0, 20.0, 10.0)
  assert_eq(a.distance_squared_to_rect(d), 25.0)
  assert_eq(a.distance_to_rect(d), 5.0)

  // IoU calculation: a and b both have area 100.
  // Intersection area is 25. Union area is 100 + 100 - 25 = 175.
  // IoU = 25 / 175 = 1 / 7
  let iou_ab = a.iou(b)
  let diff = iou_ab - 1.0 / 7.0
  let abs_diff = if diff < 0.0 { -diff } else { diff }
  assert_true(abs_diff < 0.0000001)

  // Disjoint IoU is 0.0
  assert_eq(a.iou(c), 0.0)

  // Identical IoU is 1.0
  assert_eq(a.iou(a), 1.0)
}

///|
test "rect intersects_circle center inside, touching, disjoint, negative radius" {
  let r = Rect::new(0.0, 0.0, 10.0, 10.0)

  // Center strictly inside
  assert_true(r.intersects_circle(5.0, 5.0, 1.0))
  assert_true(r.intersects_circle(5.0, 5.0, 0.0))

  // Center on boundary
  assert_true(r.intersects_circle(10.0, 5.0, 0.0))

  // Center outside, radius reaches boundary
  assert_true(r.intersects_circle(13.0, 5.0, 3.0))
  assert_false(r.intersects_circle(13.0, 5.0, 2.9))

  // Center outside diagonal corner (10, 10) -> (13, 14): dx=3, dy=4 -> dist=5
  assert_true(r.intersects_circle(13.0, 14.0, 5.0))
  assert_false(r.intersects_circle(13.0, 14.0, 4.9))

  // Negative radius
  assert_false(r.intersects_circle(5.0, 5.0, -1.0))
}
