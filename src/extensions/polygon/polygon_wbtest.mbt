///|
test "polygon2d_geometry_metrics" {
  let p1 = Point2D::new(0.0, 0.0)
  let p2 = Point2D::new(3.0, 4.0)
  assert_true((p1.distance_to(p2) - 5.0).abs() < 1.0e-9)

  // 10x10 square
  let square = Polygon2D::new([
    Point2D::new(0.0, 0.0),
    Point2D::new(10.0, 0.0),
    Point2D::new(10.0, 10.0),
    Point2D::new(0.0, 10.0),
  ])
  assert_true((square.area() - 100.0).abs() < 1.0e-9)
  assert_true((square.perimeter() - 40.0).abs() < 1.0e-9)

  let env = square.envelope()
  assert_true(
    env.min_x == 0.0 &&
    env.min_y == 0.0 &&
    env.max_x == 10.0 &&
    env.max_y == 10.0,
  )

  assert_true(square.contains_point(5.0, 5.0))
  assert_true(!square.contains_point(15.0, 5.0))
  assert_true(!square.contains_point(-1.0, 5.0))

  let c = square.centroid()
  assert_true((c.x - 5.0).abs() < 1.0e-9 && (c.y - 5.0).abs() < 1.0e-9)

  // Closed ring with duplicate point at end
  let closed_triangle = Polygon2D::new([
    Point2D::new(0.0, 0.0),
    Point2D::new(6.0, 0.0),
    Point2D::new(3.0, 4.0),
    Point2D::new(0.0, 0.0),
  ])
  assert_true((closed_triangle.area() - 12.0).abs() < 1.0e-9)
  assert_true((closed_triangle.perimeter() - 16.0).abs() < 1.0e-9)
  assert_true(closed_triangle.contains_point(3.0, 2.0))
  assert_true(!closed_triangle.contains_point(3.0, 5.0))
}

///|
test "sutherland_hodgman_polygon_clipping" {
  let clip_rect = @geometry.Rect::new(0.0, 0.0, 10.0, 10.0)

  // 1. Large square encompassing the clip window
  let large_square = Polygon2D::new([
    Point2D::new(-5.0, -5.0),
    Point2D::new(15.0, -5.0),
    Point2D::new(15.0, 15.0),
    Point2D::new(-5.0, 15.0),
  ])
  let clipped_square = large_square.clip_rect(clip_rect)
  assert_true((clipped_square.area() - 100.0).abs() < 1.0e-9)
  assert_true((clipped_square.perimeter() - 40.0).abs() < 1.0e-9)
  let sq_env = clipped_square.envelope()
  assert_true(
    sq_env.min_x == 0.0 &&
    sq_env.min_y == 0.0 &&
    sq_env.max_x == 10.0 &&
    sq_env.max_y == 10.0,
  )

  // 2. Polygon completely inside
  let small_poly = Polygon2D::new([
    Point2D::new(2.0, 2.0),
    Point2D::new(6.0, 2.0),
    Point2D::new(4.0, 5.0),
  ])
  let clipped_small = small_poly.clip_rect(clip_rect)
  assert_true((clipped_small.area() - small_poly.area()).abs() < 1.0e-9)
  assert_true(clipped_small.vertices.length() == 3)

  // 3. Polygon completely outside
  let disjoint_poly = Polygon2D::new([
    Point2D::new(20.0, 20.0),
    Point2D::new(30.0, 20.0),
    Point2D::new(25.0, 28.0),
  ])
  let clipped_disjoint = disjoint_poly.clip_rect(clip_rect)
  assert_true(clipped_disjoint.vertices.length() == 0)
  assert_true(clipped_disjoint.area() == 0.0)

  // 4. Triangle partially overlapping the window corner
  // Triangle at (-5, 0), (10, 0), (0, 15)
  let corner_triangle = Polygon2D::new([
    Point2D::new(-5.0, 0.0),
    Point2D::new(10.0, 0.0),
    Point2D::new(0.0, 15.0),
  ])
  let clipped_corner = corner_triangle.clip_rect(clip_rect)
  assert_true(clipped_corner.area() > 0.0)
  let corner_env = clipped_corner.envelope()
  assert_true(corner_env.min_x >= 0.0 && corner_env.max_x <= 10.0)
  assert_true(corner_env.min_y >= 0.0 && corner_env.max_y <= 10.0)

  // 5. Convex clipping: clip large square with convex triangle
  let clip_tri = Polygon2D::new([
    Point2D::new(0.0, 0.0),
    Point2D::new(10.0, 0.0),
    Point2D::new(5.0, 10.0),
  ])
  let clipped_by_tri = large_square.clip_convex(clip_tri)
  assert_true((clipped_by_tri.area() - 50.0).abs() < 1.0e-9)
}
