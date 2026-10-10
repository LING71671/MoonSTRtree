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
/// Metrics and decimated point collection resulting from trajectory simplification.
pub struct TrajectorySimplificationResult {
  points : Array[TrajectoryPoint]
  original_count : Int
  simplified_count : Int
  compression_ratio : Double
  max_error : Double
} derive(Eq, Debug, Default)

///|
/// Calculates perpendicular distance from point (px, py) to line segment (x1, y1) -> (x2, y2).
fn perpendicular_distance(
  px : Double,
  py : Double,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> Double {
  let dx = x2 - x1
  let dy = y2 - y1
  let len_sq = dx * dx + dy * dy
  if len_sq <= 1.0e-12 {
    let dpx = px - x1
    let dpy = py - y1
    let d_sq = dpx * dpx + dpy * dpy
    if d_sq <= 0.0 {
      0.0
    } else {
      let mut x = d_sq / 2.0
      if x <= 0.0 {
        x = 1.0
      }
      for step = 0; step < 12; step = step + 1 {
        x = 0.5 * (x + d_sq / x)
      }
      x
    }
  } else {
    // Numerator: |dy*px - dx*py + x2*y1 - y2*x1|
    let num = (dy * px - dx * py + x2 * y1 - y2 * x1).abs()
    let mut denom = len_sq / 2.0
    if denom <= 0.0 {
      denom = 1.0
    }
    for step = 0; step < 12; step = step + 1 {
      denom = 0.5 * (denom + len_sq / denom)
    }
    num / denom
  }
}

///|
/// Calculates Synchronized Euclidean Distance (SED) between waypoint p and segment start -> end at timestamp p.t.
fn synchronized_euclidean_distance(
  p : TrajectoryPoint,
  start : TrajectoryPoint,
  end : TrajectoryPoint,
) -> Double {
  let dt = end.t - start.t
  if dt.abs() <= 1.0e-9 {
    perpendicular_distance(p.x, p.y, start.x, start.y, end.x, end.y)
  } else {
    let alpha = (p.t - start.t) / dt
    let sync_x = start.x + alpha * (end.x - start.x)
    let sync_y = start.y + alpha * (end.y - start.y)
    let dx = p.x - sync_x
    let dy = p.y - sync_y
    let d_sq = dx * dx + dy * dy
    if d_sq <= 0.0 {
      0.0
    } else {
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
}

///|
/// Recursively decimates 2D trajectory points using classical Douglas-Peucker algorithm.
fn douglas_peucker_2d_recursive(
  pts : Array[TrajectoryPoint],
  first : Int,
  last : Int,
  epsilon : Double,
  keep : Array[Bool],
) -> Double {
  if last <= first + 1 {
    return 0.0
  }

  let mut d_max = 0.0
  let mut index = first
  let p_first = pts[first]
  let p_last = pts[last]

  for i = first + 1; i < last; i = i + 1 {
    let d = perpendicular_distance(
      pts[i].x,
      pts[i].y,
      p_first.x,
      p_first.y,
      p_last.x,
      p_last.y,
    )
    if d > d_max {
      d_max = d
      index = i
    }
  }

  if d_max > epsilon {
    keep[index] = true
    let left_err = douglas_peucker_2d_recursive(
      pts, first, index, epsilon, keep,
    )
    let right_err = douglas_peucker_2d_recursive(
      pts, index, last, epsilon, keep,
    )
    let mut err = d_max
    if left_err > err {
      err = left_err
    }
    if right_err > err {
      err = right_err
    }
    err
  } else {
    d_max
  }
}

///|
/// Recursively decimates spatiotemporal trajectory points using Synchronized Euclidean Distance (SED).
fn douglas_peucker_sed_recursive(
  pts : Array[TrajectoryPoint],
  first : Int,
  last : Int,
  epsilon : Double,
  keep : Array[Bool],
) -> Double {
  if last <= first + 1 {
    return 0.0
  }

  let mut d_max = 0.0
  let mut index = first
  let p_first = pts[first]
  let p_last = pts[last]

  for i = first + 1; i < last; i = i + 1 {
    let d = synchronized_euclidean_distance(pts[i], p_first, p_last)
    if d > d_max {
      d_max = d
      index = i
    }
  }

  if d_max > epsilon {
    keep[index] = true
    let left_err = douglas_peucker_sed_recursive(
      pts, first, index, epsilon, keep,
    )
    let right_err = douglas_peucker_sed_recursive(
      pts, index, last, epsilon, keep,
    )
    let mut err = d_max
    if left_err > err {
      err = left_err
    }
    if right_err > err {
      err = right_err
    }
    err
  } else {
    d_max
  }
}

///|
/// Simplifies a 2D trajectory waypoint sequence using the Douglas-Peucker algorithm with perpendicular distance threshold epsilon.
pub fn simplify_trajectory_2d(
  points : Array[TrajectoryPoint],
  epsilon : Double,
) -> TrajectorySimplificationResult {
  let n = points.length()
  if n <= 2 {
    return TrajectorySimplificationResult::{
      points,
      original_count: n,
      simplified_count: n,
      compression_ratio: 0.0,
      max_error: 0.0,
    }
  }

  let keep = Array::make(n, false)
  keep[0] = true
  keep[n - 1] = true

  let max_err = douglas_peucker_2d_recursive(points, 0, n - 1, epsilon, keep)

  let decimated : Array[TrajectoryPoint] = []
  for i = 0; i < n; i = i + 1 {
    if keep[i] {
      decimated.push(points[i])
    }
  }

  let simplified_count = decimated.length()
  let ratio = if n > 0 {
    (1.0 - simplified_count.to_double() / n.to_double()) * 100.0
  } else {
    0.0
  }

  TrajectorySimplificationResult::{
    points: decimated,
    original_count: n,
    simplified_count,
    compression_ratio: ratio,
    max_error: max_err,
  }
}

///|
/// Simplifies a spatiotemporal trajectory using Synchronized Euclidean Distance (SED) tolerance epsilon.
pub fn simplify_trajectory_spatiotemporal(
  points : Array[TrajectoryPoint],
  epsilon : Double,
) -> TrajectorySimplificationResult {
  let n = points.length()
  if n <= 2 {
    return TrajectorySimplificationResult::{
      points,
      original_count: n,
      simplified_count: n,
      compression_ratio: 0.0,
      max_error: 0.0,
    }
  }

  let keep = Array::make(n, false)
  keep[0] = true
  keep[n - 1] = true

  let max_err = douglas_peucker_sed_recursive(points, 0, n - 1, epsilon, keep)

  let decimated : Array[TrajectoryPoint] = []
  for i = 0; i < n; i = i + 1 {
    if keep[i] {
      decimated.push(points[i])
    }
  }

  let simplified_count = decimated.length()
  let ratio = if n > 0 {
    (1.0 - simplified_count.to_double() / n.to_double()) * 100.0
  } else {
    0.0
  }

  TrajectorySimplificationResult::{
    points: decimated,
    original_count: n,
    simplified_count,
    compression_ratio: ratio,
    max_error: max_err,
  }
}
