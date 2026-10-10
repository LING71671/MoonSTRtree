// Copyright 2026 Antigravity Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
pub fn TrajectorySegment::bounding_rect(
  self : TrajectorySegment,
) -> @geometry.Rect {
  let min_x = if self.p0_x < self.p1_x { self.p0_x } else { self.p1_x }
  let max_x = if self.p0_x > self.p1_x { self.p0_x } else { self.p1_x }
  let min_y = if self.p0_y < self.p1_y { self.p0_y } else { self.p1_y }
  let max_y = if self.p0_y > self.p1_y { self.p0_y } else { self.p1_y }
  @geometry.Rect::new(min_x, min_y, max_x, max_y)
}

///|
/// Returns earliest timestamp of this segment.
pub fn TrajectorySegment::min_t(self : TrajectorySegment) -> Double {
  if self.p0_t < self.p1_t {
    self.p0_t
  } else {
    self.p1_t
  }
}

///|
/// Returns latest timestamp of this segment.
pub fn TrajectorySegment::max_t(self : TrajectorySegment) -> Double {
  if self.p0_t > self.p1_t {
    self.p0_t
  } else {
    self.p1_t
  }
}

///|
/// Computes Euclidean 2D spatial path length.
pub fn TrajectorySegment::length(self : TrajectorySegment) -> Double {
  let dx = self.p1_x - self.p0_x
  let dy = self.p1_y - self.p0_y
  let d_sq = dx * dx + dy * dy
  if d_sq <= 0.0 {
    0.0
  } else {
    // Newton-Raphson square root
    let mut x = d_sq / 2.0
    if x <= 0.0 {
      x = 1.0
    }
    for step = 0; step < 12; step = step + 1 {
      x = 0.5 * (x + d_sq / x)
    }
    x
  }
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
/// Computes average kinematic speed (length / duration). Returns 0.0 if duration is 0.
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
/// Returns None if t is outside the segment temporal span.
pub fn TrajectorySegment::interpolate_position(
  self : TrajectorySegment,
  t : Double,
) -> (Double, Double)? {
  let t_start = self.min_t()
  let t_end = self.max_t()
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
  tree : StrTree
  segments : Array[TrajectorySegment]
} derive(Eq, Debug, Default)

///|
/// Builds a TrajectoryWindowIndex from an array of TrajectorySegments.
pub fn TrajectoryWindowIndex::build(
  segments : Array[TrajectorySegment],
  node_capacity? : Int = 16,
) -> TrajectoryWindowIndex {
  let items : Array[(@geometry.Rect, Int)] = []
  for i = 0; i < segments.length(); i = i + 1 {
    let seg = segments[i]
    items.push((seg.bounding_rect(), i))
  }
  let tree = StrTree::build(items, node_capacity~)
  TrajectoryWindowIndex::{ tree, segments, }
}

///|
/// Converts consecutive trajectory waypoints into directed segments, joining points with matching track_id.
pub fn TrajectoryWindowIndex::segments_from_points(
  points : Array[TrajectoryPoint],
) -> Array[TrajectorySegment] {
  let segments : Array[TrajectorySegment] = []
  if points.length() < 2 {
    return segments
  }
  let mut seg_counter = 0
  for i = 0; i < points.length() - 1; i = i + 1 {
    let p0 = points[i]
    let p1 = points[i + 1]
    if p0.track_id == p1.track_id {
      segments.push(
        TrajectorySegment::new(
          p0.x,
          p0.y,
          p0.t,
          p1.x,
          p1.y,
          p1.t,
          p0.track_id,
          seg_counter,
        ),
      )
      seg_counter = seg_counter + 1
    }
  }
  segments
}

///|
/// Queries all trajectory segment IDs whose spatial bounding box intersects search_window
/// and whose temporal lifespan overlaps [t_min, t_max].
pub fn TrajectoryWindowIndex::query_window(
  self : TrajectoryWindowIndex,
  spatial_window : @geometry.Rect,
  t_min : Double,
  t_max : Double,
) -> Array[Int] {
  let candidate_indices = self.tree.query(spatial_window)
  let matched_segments : Array[Int] = []

  for i = 0; i < candidate_indices.length(); i = i + 1 {
    let idx = candidate_indices[i]
    if idx >= 0 && idx < self.segments.length() {
      let seg = self.segments[idx]
      let seg_start = seg.min_t()
      let seg_end = seg.max_t()
      // Time interval overlap test: max(start1, start2) <= min(end1, end2)
      let overlap_start = if seg_start > t_min { seg_start } else { t_min }
      let overlap_end = if seg_end < t_max { seg_end } else { t_max }
      if overlap_start <= overlap_end {
        matched_segments.push(seg.segment_id)
      }
    }
  }

  matched_segments
}

///|
/// Queries unique track IDs that intersected search_window during temporal interval [t_min, t_max].
pub fn TrajectoryWindowIndex::query_tracks_in_window(
  self : TrajectoryWindowIndex,
  spatial_window : @geometry.Rect,
  t_min : Double,
  t_max : Double,
) -> Array[Int] {
  let candidate_indices = self.tree.query(spatial_window)
  let matched_tracks : Array[Int] = []

  for i = 0; i < candidate_indices.length(); i = i + 1 {
    let idx = candidate_indices[i]
    if idx >= 0 && idx < self.segments.length() {
      let seg = self.segments[idx]
      let seg_start = seg.min_t()
      let seg_end = seg.max_t()
      let overlap_start = if seg_start > t_min { seg_start } else { t_min }
      let overlap_end = if seg_end < t_max { seg_end } else { t_max }
      if overlap_start <= overlap_end {
        let tid = seg.track_id
        let mut already_included = false
        for j = 0; j < matched_tracks.length(); j = j + 1 {
          if matched_tracks[j] == tid {
            already_included = true
            break
          }
        }
        if !already_included {
          matched_tracks.push(tid)
        }
      }
    }
  }

  matched_tracks
}

///|
/// Returns total number of indexed trajectory segments.
pub fn TrajectoryWindowIndex::num_segments(self : TrajectoryWindowIndex) -> Int {
  self.segments.length()
}

///|
/// Retrieves trajectory segment by index.
pub fn TrajectoryWindowIndex::get_segment(
  self : TrajectoryWindowIndex,
  index : Int,
) -> TrajectorySegment? {
  if index >= 0 && index < self.segments.length() {
    Some(self.segments[index])
  } else {
    None
  }
}
