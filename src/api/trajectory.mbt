///|
/// A timestamped 2D trajectory waypoint coordinate.
pub struct TrajectoryPoint {
  x : Double
  y : Double
  t : Double
  track_id : Int
} derive(Eq, Debug, Default)

///|
/// Creates a new timestamped trajectory waypoint.
pub fn TrajectoryPoint::new(
  x : Double,
  y : Double,
  t : Double,
  track_id : Int,
) -> TrajectoryPoint {
  TrajectoryPoint::{ x, y, t, track_id, }
}

///|
/// A directed 2D trajectory segment connecting two consecutive waypoints in spacetime.
pub struct TrajectorySegment {
  p0_x : Double
  p0_y : Double
  p0_t : Double
  p1_x : Double
  p1_y : Double
  p1_t : Double
  track_id : Int
  segment_id : Int
} derive(Eq, Debug, Default)

///|
/// Creates a new directed trajectory segment with track and segment IDs.
pub fn TrajectorySegment::new(
  p0_x : Double,
  p0_y : Double,
  p0_t : Double,
  p1_x : Double,
  p1_y : Double,
  p1_t : Double,
  track_id : Int,
  segment_id : Int,
) -> TrajectorySegment {
  TrajectorySegment::{
    p0_x,
    p0_y,
    p0_t,
    p1_x,
    p1_y,
    p1_t,
    track_id,
    segment_id,
  }
}

///|
/// Computes 2D spatial bounding box enclosing the trajectory segment.
pub fn TrajectorySegment::bounding_rect(self : TrajectorySegment) -> Rect {
  let min_x = if self.p0_x < self.p1_x { self.p0_x } else { self.p1_x }
  let max_x = if self.p0_x > self.p1_x { self.p0_x } else { self.p1_x }
  let min_y = if self.p0_y < self.p1_y { self.p0_y } else { self.p1_y }
  let max_y = if self.p0_y > self.p1_y { self.p0_y } else { self.p1_y }
  Rect::new(min_x, min_y, max_x, max_y)
}

///|
/// Computes temporal duration (|p1_t - p0_t|).
pub fn TrajectorySegment::duration(self : TrajectorySegment) -> Double {
  let dt = self.p1_t - self.p0_t
  if dt < 0.0 {
    -dt
  } else {
    dt
  }
}

///|
/// Computes Euclidean 2D spatial path length.
pub fn TrajectorySegment::length(self : TrajectorySegment) -> Double {
  let dx = self.p1_x - self.p0_x
  let dy = self.p1_y - self.p0_y
  (dx * dx + dy * dy).sqrt()
}

///|
/// Computes average kinematic speed (length / duration).
pub fn TrajectorySegment::speed(self : TrajectorySegment) -> Double {
  let dur = self.duration()
  if dur <= 1.0e-9 {
    0.0
  } else {
    self.length() / dur
  }
}

///|
/// Linearly interpolates (x, y) spatial coordinates at timestamp t.
pub fn TrajectorySegment::interpolate_position(
  self : TrajectorySegment,
  t : Double,
) -> (Double, Double)? {
  let t_start = if self.p0_t < self.p1_t { self.p0_t } else { self.p1_t }
  let t_end = if self.p0_t > self.p1_t { self.p0_t } else { self.p1_t }
  if t < t_start || t > t_end {
    return None
  }
  let span = self.p1_t - self.p0_t
  if span.abs() <= 1.0e-9 {
    return Some((self.p0_x, self.p0_y))
  }
  let alpha = (t - self.p0_t) / span
  let ix = self.p0_x + alpha * (self.p1_x - self.p0_x)
  let iy = self.p0_y + alpha * (self.p1_y - self.p0_y)
  Some((ix, iy))
}

///|
/// Spatiotemporal sliding-window trajectory segment index.
pub struct TrajectoryWindowIndex {
  priv inner : @trajectory.TrajectoryWindowIndex
} derive(Eq, Debug, Default)

///|
/// Builds a TrajectoryWindowIndex from an array of TrajectorySegments.
pub fn TrajectoryWindowIndex::build(
  segments : Array[TrajectorySegment],
  node_capacity? : Int = 16,
) -> TrajectoryWindowIndex {
  let t_segs : Array[@trajectory.TrajectorySegment] = []
  for i = 0; i < segments.length(); i = i + 1 {
    let s = segments[i]
    t_segs.push(
      @trajectory.TrajectorySegment::new(
        s.p0_x,
        s.p0_y,
        s.p0_t,
        s.p1_x,
        s.p1_y,
        s.p1_t,
        s.track_id,
        s.segment_id,
      ),
    )
  }
  let inner = @trajectory.TrajectoryWindowIndex::build(t_segs, node_capacity~)
  TrajectoryWindowIndex::{ inner, }
}

///|
/// Converts consecutive trajectory waypoints into directed segments, joining points with matching track_id.
pub fn TrajectoryWindowIndex::segments_from_points(
  points : Array[TrajectoryPoint],
) -> Array[TrajectorySegment] {
  let t_pts : Array[@trajectory.TrajectoryPoint] = []
  for i = 0; i < points.length(); i = i + 1 {
    let p = points[i]
    t_pts.push(@trajectory.TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  let t_segs = @trajectory.TrajectoryWindowIndex::segments_from_points(t_pts)
  let res : Array[TrajectorySegment] = []
  for i = 0; i < t_segs.length(); i = i + 1 {
    let s = t_segs[i]
    res.push(
      TrajectorySegment::new(
        s.p0_x,
        s.p0_y,
        s.p0_t,
        s.p1_x,
        s.p1_y,
        s.p1_t,
        s.track_id,
        s.segment_id,
      ),
    )
  }
  res
}

///|
/// Queries all trajectory segment IDs whose spatial bounding box intersects search_window
/// and whose temporal lifespan overlaps [t_min, t_max].
pub fn TrajectoryWindowIndex::query_window(
  self : TrajectoryWindowIndex,
  spatial_window : Rect,
  t_min : Double,
  t_max : Double,
) -> Array[Int] {
  self.inner.query_window(spatial_window, t_min, t_max)
}

///|
/// Queries unique track IDs that intersected search_window during temporal interval [t_min, t_max].
pub fn TrajectoryWindowIndex::query_tracks_in_window(
  self : TrajectoryWindowIndex,
  spatial_window : Rect,
  t_min : Double,
  t_max : Double,
) -> Array[Int] {
  self.inner.query_tracks_in_window(spatial_window, t_min, t_max)
}

///|
/// Returns total number of indexed trajectory segments.
pub fn TrajectoryWindowIndex::num_segments(self : TrajectoryWindowIndex) -> Int {
  self.inner.num_segments()
}

///|
/// Metrics and decimated point collection resulting from trajectory simplification.
pub struct TrajectorySimplificationResult {
  points : Array[TrajectoryPoint]
  original_count : Int
  simplified_count : Int
  compression_ratio : Double
  max_error : Double
} derive(Eq, Debug, Default)

///|
/// Simplifies a 2D trajectory waypoint sequence using Douglas-Peucker algorithm with tolerance epsilon.
pub fn simplify_trajectory_2d(
  points : Array[TrajectoryPoint],
  epsilon : Double,
) -> TrajectorySimplificationResult {
  let t_pts : Array[@trajectory.TrajectoryPoint] = []
  for i = 0; i < points.length(); i = i + 1 {
    let p = points[i]
    t_pts.push(@trajectory.TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  let res = @trajectory.simplify_trajectory_2d(t_pts, epsilon)
  let out_pts : Array[TrajectoryPoint] = []
  for i = 0; i < res.points.length(); i = i + 1 {
    let p = res.points[i]
    out_pts.push(TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  TrajectorySimplificationResult::{
    points: out_pts,
    original_count: res.original_count,
    simplified_count: res.simplified_count,
    compression_ratio: res.compression_ratio,
    max_error: res.max_error,
  }
}

///|
/// Simplifies a spatiotemporal trajectory using Synchronized Euclidean Distance (SED) tolerance epsilon.
pub fn simplify_trajectory_spatiotemporal(
  points : Array[TrajectoryPoint],
  epsilon : Double,
) -> TrajectorySimplificationResult {
  let t_pts : Array[@trajectory.TrajectoryPoint] = []
  for i = 0; i < points.length(); i = i + 1 {
    let p = points[i]
    t_pts.push(@trajectory.TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  let res = @trajectory.simplify_trajectory_spatiotemporal(t_pts, epsilon)
  let out_pts : Array[TrajectoryPoint] = []
  for i = 0; i < res.points.length(); i = i + 1 {
    let p = res.points[i]
    out_pts.push(TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  TrajectorySimplificationResult::{
    points: out_pts,
    original_count: res.original_count,
    simplified_count: res.simplified_count,
    compression_ratio: res.compression_ratio,
    max_error: res.max_error,
  }
}

///|
/// Online streaming trajectory compressor performing real-time decimation against error tolerance.
pub struct StreamingTrajectoryCompressor {
  priv inner : @trajectory.StreamingTrajectoryCompressor
} derive(Eq, Debug)

///|
/// Instantiates an online trajectory compressor with error bound epsilon and optional SED calculation.
pub fn StreamingTrajectoryCompressor::new(
  epsilon : Double,
  use_sed? : Bool = false,
) -> StreamingTrajectoryCompressor {
  let inner = @trajectory.StreamingTrajectoryCompressor::new(epsilon, use_sed~)
  StreamingTrajectoryCompressor::{ inner, }
}

///|
/// Ingests a new trajectory waypoint and returns any newly finalized anchor waypoints.
pub fn StreamingTrajectoryCompressor::push(
  self : StreamingTrajectoryCompressor,
  pt : TrajectoryPoint,
) -> Array[TrajectoryPoint] {
  let emitted = self.inner.push(
    @trajectory.TrajectoryPoint::new(pt.x, pt.y, pt.t, pt.track_id),
  )
  let res : Array[TrajectoryPoint] = []
  for i = 0; i < emitted.length(); i = i + 1 {
    let p = emitted[i]
    res.push(TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  res
}

///|
/// Flushes the remaining trajectory stream and returns all preserved decimated waypoints.
pub fn StreamingTrajectoryCompressor::finish(
  self : StreamingTrajectoryCompressor,
) -> Array[TrajectoryPoint] {
  let final_pts = self.inner.finish()
  let res : Array[TrajectoryPoint] = []
  for i = 0; i < final_pts.length(); i = i + 1 {
    let p = final_pts[i]
    res.push(TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  res
}

///|
/// Returns total number of incoming points received so far.
pub fn StreamingTrajectoryCompressor::total_received(
  self : StreamingTrajectoryCompressor,
) -> Int {
  self.inner.total_received()
}

///|
/// Returns total number of finalized waypoints emitted so far.
pub fn StreamingTrajectoryCompressor::total_emitted(
  self : StreamingTrajectoryCompressor,
) -> Int {
  self.inner.total_emitted()
}

///|
/// Computes point decimation percentage ((1 - emitted / received) * 100).
pub fn StreamingTrajectoryCompressor::compression_ratio(
  self : StreamingTrajectoryCompressor,
) -> Double {
  self.inner.compression_ratio()
}

///|
/// Computes Dynamic Time Warping (DTW) distance between two trajectories with optional Sakoe-Chiba window constraint.
pub fn trajectory_dtw_distance(
  a : Array[TrajectoryPoint],
  b : Array[TrajectoryPoint],
  window? : Int = -1,
) -> Double {
  let t_a : Array[@trajectory.TrajectoryPoint] = []
  for i = 0; i < a.length(); i = i + 1 {
    let p = a[i]
    t_a.push(@trajectory.TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  let t_b : Array[@trajectory.TrajectoryPoint] = []
  for i = 0; i < b.length(); i = i + 1 {
    let p = b[i]
    t_b.push(@trajectory.TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  @trajectory.trajectory_dtw_distance(t_a, t_b, window~)
}

///|
/// Computes length-normalized DTW distance (total_dtw / (len_a + len_b)).
pub fn trajectory_dtw_normalized(
  a : Array[TrajectoryPoint],
  b : Array[TrajectoryPoint],
  window? : Int = -1,
) -> Double {
  let t_a : Array[@trajectory.TrajectoryPoint] = []
  for i = 0; i < a.length(); i = i + 1 {
    let p = a[i]
    t_a.push(@trajectory.TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  let t_b : Array[@trajectory.TrajectoryPoint] = []
  for i = 0; i < b.length(); i = i + 1 {
    let p = b[i]
    t_b.push(@trajectory.TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  @trajectory.trajectory_dtw_normalized(t_a, t_b, window~)
}

///|
/// Computes Discrete Fréchet Distance between two polygonal trajectory curves.
pub fn trajectory_frechet_distance(
  a : Array[TrajectoryPoint],
  b : Array[TrajectoryPoint],
) -> Double {
  let t_a : Array[@trajectory.TrajectoryPoint] = []
  for i = 0; i < a.length(); i = i + 1 {
    let p = a[i]
    t_a.push(@trajectory.TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  let t_b : Array[@trajectory.TrajectoryPoint] = []
  for i = 0; i < b.length(); i = i + 1 {
    let p = b[i]
    t_b.push(@trajectory.TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  @trajectory.trajectory_frechet_distance(t_a, t_b)
}
