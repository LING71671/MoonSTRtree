///|
test "Euclidean distances remain accurate at large and small scales" {
  let origin = Rect::from_point(0.0, 0.0)
  assert_true(
    (origin.distance_to_point(3.0e12, 4.0e12) / 5.0e12 - 1.0).abs() < 1.0e-12,
  )
  assert_true(
    (origin.distance_to_rect(Rect::from_point(3.0e-12, 4.0e-12)) / 5.0e-12 - 1.0).abs() <
    1.0e-12,
  )
}

///|
test "finite midpoint coordinates do not overflow during spatial sorting" {
  let rect = Rect::new(1.0e308, 1.0e308, 1.0e308, 1.0e308)
  assert_eq(rect.center_x(), 1.0e308)
  assert_eq(rect.center_y(), 1.0e308)
  let box = Box3D::from_point(1.0e308, 1.0e308, 1.0e308)
  assert_eq(box.center_x(), 1.0e308)
  assert_eq(box.center_z(), 1.0e308)
}
