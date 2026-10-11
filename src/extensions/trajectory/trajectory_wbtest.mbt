///|
test "TrajectoryWindowIndex spatiotemporal sliding window" {
  let pts = [
    // Track 1: Moving from (0,0, t=0) -> (10, 10, t=10) -> (20, 20, t=20)
    TrajectoryPoint::new(0.0, 0.0, 0.0, 1),
    TrajectoryPoint::new(10.0, 10.0, 10.0, 1),
    TrajectoryPoint::new(20.0, 20.0, 20.0, 1),
    // Track 2: Moving from (5, 5, t=50) -> (15, 15, t=60)
    TrajectoryPoint::new(5.0, 5.0, 50.0, 2),
    TrajectoryPoint::new(15.0, 15.0, 60.0, 2),
  ]

  let segments = TrajectoryWindowIndex::segments_from_points(pts)
  assert_eq(segments.length(), 3)
  assert_eq(segments[0].track_id, 1)
  assert_eq(segments[1].track_id, 1)
  assert_eq(segments[2].track_id, 2)

  // Test segment properties
  let seg0 = segments[0]
  assert_eq(seg0.duration(), 10.0)
  assert_true(seg0.speed() > 1.4 && seg0.speed() < 1.42) // sqrt(200)/10 ~= 1.4142
  let interp = seg0.interpolate_position(5.0)
  match interp {
    Some((x, y)) => {
      assert_true((x - 5.0).abs() < 1.0e-5)
      assert_true((y - 5.0).abs() < 1.0e-5)
    }
    None => assert_true(false)
  }

  // Build spatiotemporal window index
  let idx = TrajectoryWindowIndex::build(segments, node_capacity=2)
  assert_eq(idx.num_segments(), 3)

  let win = @geometry.Rect::new(2.0, 2.0, 12.0, 12.0)

  // 1. Sliding window [t=0, t=15]: Should match track 1 (seg 0 and seg 1), but NOT track 2 (which is t in [50, 60])
  let hit_segs_t1 = idx.query_window(win, 0.0, 15.0)
  assert_true(hit_segs_t1.contains(0))
  assert_true(hit_segs_t1.contains(1))
  assert_false(hit_segs_t1.contains(2))

  let hit_tracks_t1 = idx.query_tracks_in_window(win, 0.0, 15.0)
  assert_eq(hit_tracks_t1, [1])

  // 2. Sliding window [t=45, t=65]: Should match track 2 (seg 2), but NOT track 1
  let hit_segs_t2 = idx.query_window(win, 45.0, 65.0)
  assert_eq(hit_segs_t2, [2])
  let hit_tracks_t2 = idx.query_tracks_in_window(win, 45.0, 65.0)
  assert_eq(hit_tracks_t2, [2])

  // 3. Sliding window [t=0, t=100]: Both tracks pass through win
  let all_tracks = idx.query_tracks_in_window(win, 0.0, 100.0)
  assert_eq(all_tracks.length(), 2)
  assert_true(all_tracks.contains(1))
  assert_true(all_tracks.contains(2))
}

///|
test "trajectory simplification 2D and SED" {
  // 1. Collinear trajectory with 5 points on y = x
  let collinear = [
    TrajectoryPoint::new(0.0, 0.0, 0.0, 1),
    TrajectoryPoint::new(2.5, 2.5, 2.5, 1),
    TrajectoryPoint::new(5.0, 5.0, 5.0, 1),
    TrajectoryPoint::new(7.5, 7.5, 7.5, 1),
    TrajectoryPoint::new(10.0, 10.0, 10.0, 1),
  ]
  let res_collinear = simplify_trajectory_2d(collinear, 0.1)
  assert_eq(res_collinear.original_count, 5)
  assert_eq(res_collinear.simplified_count, 2)
  assert_eq(res_collinear.points[0].x, 0.0)
  assert_eq(res_collinear.points[1].x, 10.0)
  assert_true(res_collinear.compression_ratio > 59.0)

  // 2. Trajectory with corner at (5, 10)
  let corner = [
    TrajectoryPoint::new(0.0, 0.0, 0.0, 1),
    TrajectoryPoint::new(5.0, 10.0, 5.0, 1), // Peak deviation
    TrajectoryPoint::new(10.0, 0.0, 10.0, 1),
  ]
  let res_kept = simplify_trajectory_2d(corner, 1.0)
  assert_eq(res_kept.simplified_count, 3) // Kept corner

  let res_culled = simplify_trajectory_2d(corner, 15.0)
  assert_eq(res_culled.simplified_count, 2) // Culled corner with large epsilon

  // 3. Spatiotemporal SED: spatially on line, but temporally distorted
  // Start (0, 0, t=0), End (10, 0, t=10). Expected at t=5 is (5, 0).
  // Middle point is at (1, 0, t=5) -> huge temporal lag (SED = 4.0).
  let temporal_lag = [
    TrajectoryPoint::new(0.0, 0.0, 0.0, 1),
    TrajectoryPoint::new(1.0, 0.0, 5.0, 1), // Distance to line is 0, but SED is 4.0!
    TrajectoryPoint::new(10.0, 0.0, 10.0, 1),
  ]
  // 2D Douglas-Peucker considers this 100% straight (perpendicular dist = 0)
  let res_geo = simplify_trajectory_2d(temporal_lag, 0.5)
  assert_eq(res_geo.simplified_count, 2) // Missed temporal variation!

  // SED preserves the temporal delay because error = 4.0 > 0.5
  let res_sed = simplify_trajectory_spatiotemporal(temporal_lag, 0.5)
  assert_eq(res_sed.simplified_count, 3) // Preserved temporal waypoint!
}

///|
test "StreamingTrajectoryCompressor online decimation" {
  let compressor = StreamingTrajectoryCompressor::new(1.0)

  // Stream in 10 collinear points along x-axis, with one corner outlier
  let _ = compressor.push(TrajectoryPoint::new(0.0, 0.0, 0.0, 1))
  let _ = compressor.push(TrajectoryPoint::new(1.0, 0.0, 1.0, 1))
  let _ = compressor.push(TrajectoryPoint::new(2.0, 0.0, 2.0, 1))
  let _ = compressor.push(TrajectoryPoint::new(3.0, 0.0, 3.0, 1))
  // Outlier at (4, 5) -> exceeds epsilon 1.0
  let _ = compressor.push(TrajectoryPoint::new(4.0, 5.0, 4.0, 1))
  let _ = compressor.push(TrajectoryPoint::new(5.0, 0.0, 5.0, 1))
  let _ = compressor.push(TrajectoryPoint::new(6.0, 0.0, 6.0, 1))
  let _ = compressor.push(TrajectoryPoint::new(7.0, 0.0, 7.0, 1))
  let _ = compressor.push(TrajectoryPoint::new(8.0, 0.0, 8.0, 1))
  let _ = compressor.push(TrajectoryPoint::new(9.0, 0.0, 9.0, 1))

  let final_pts = compressor.finish()
  assert_eq(compressor.total_received(), 10)
  assert_true(final_pts.length() < 10)
  assert_true(compressor.compression_ratio() > 40.0)
  // First point should be (0, 0) and last point should be (9, 0)
  assert_eq(final_pts[0].x, 0.0)
  assert_eq(final_pts[final_pts.length() - 1].x, 9.0)
}

///|
test "trajectory DTW distance and Sakoe-Chiba constraint" {
  let t1 = [
    TrajectoryPoint::new(0.0, 0.0, 0.0, 1),
    TrajectoryPoint::new(1.0, 1.0, 1.0, 1),
    TrajectoryPoint::new(2.0, 2.0, 2.0, 1),
  ]

  // 1. Identical trajectory
  let d_same = trajectory_dtw_distance(t1, t1)
  assert_true(d_same < 1.0e-9)

  // 2. Parallel offset by y + 2.0
  let t2 = [
    TrajectoryPoint::new(0.0, 2.0, 0.0, 2),
    TrajectoryPoint::new(1.0, 3.0, 1.0, 2),
    TrajectoryPoint::new(2.0, 4.0, 2.0, 2),
  ]
  let d_parallel = trajectory_dtw_distance(t1, t2)
  assert_true((d_parallel - 6.0).abs() < 1.0e-9)
  let d_norm = trajectory_dtw_normalized(t1, t2)
  assert_true((d_norm - 1.0).abs() < 1.0e-9) // 6.0 / (3 + 3) = 1.0

  // 3. Stretched trajectory (time warped)
  let t_stretched = [
    TrajectoryPoint::new(0.0, 0.0, 0.0, 3),
    TrajectoryPoint::new(0.5, 0.5, 0.5, 3),
    TrajectoryPoint::new(1.0, 1.0, 1.0, 3),
    TrajectoryPoint::new(1.5, 1.5, 1.5, 3),
    TrajectoryPoint::new(2.0, 2.0, 2.0, 3),
  ]
  let d_stretched = trajectory_dtw_distance(t1, t_stretched)
  assert_true((d_stretched - 1.41421356).abs() < 1.0e-4)

  // 4. Window constrained DTW
  let d_windowed = trajectory_dtw_distance(t1, t_stretched, window=2)
  assert_true((d_windowed - 1.41421356).abs() < 1.0e-4)
}

///|
test "trajectory Discrete Frechet distance" {
  let line_a = [
    TrajectoryPoint::new(0.0, 0.0, 0.0, 1),
    TrajectoryPoint::new(5.0, 0.0, 5.0, 1),
    TrajectoryPoint::new(10.0, 0.0, 10.0, 1),
  ]

  // 1. Identical line
  let f_same = trajectory_frechet_distance(line_a, line_a)
  assert_true(f_same < 1.0e-9)

  // 2. Parallel line shifted vertically by y = 4.0
  let line_b = [
    TrajectoryPoint::new(0.0, 4.0, 0.0, 2),
    TrajectoryPoint::new(5.0, 4.0, 5.0, 2),
    TrajectoryPoint::new(10.0, 4.0, 10.0, 2),
  ]
  let f_parallel = trajectory_frechet_distance(line_a, line_b)
  assert_true((f_parallel - 4.0).abs() < 1.0e-9)

  // 3. Curve with a bulge: midpoint deviates to y = 8.0
  let line_bulge = [
    TrajectoryPoint::new(0.0, 0.0, 0.0, 3),
    TrajectoryPoint::new(5.0, 8.0, 5.0, 3), // Bottleneck point
    TrajectoryPoint::new(10.0, 0.0, 10.0, 3),
  ]
  let f_bulge = trajectory_frechet_distance(line_a, line_bulge)
  assert_true((f_bulge - 8.0).abs() < 1.0e-9)
}
