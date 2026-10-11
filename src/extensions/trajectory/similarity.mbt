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
/// Euclidean distance between two 2D trajectory waypoints.
fn point_distance(p1 : TrajectoryPoint, p2 : TrajectoryPoint) -> Double {
  let dx = p1.x - p2.x
  let dy = p1.y - p2.y
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

///|
/// Computes Dynamic Time Warping (DTW) accumulated distance between two trajectory waypoint sequences.
/// Supports optional Sakoe-Chiba warping window constraint (window < 0 indicates unconstrained DTW).
pub fn trajectory_dtw_distance(
  a : Array[TrajectoryPoint],
  b : Array[TrajectoryPoint],
  window? : Int = -1,
) -> Double {
  let n = a.length()
  let m = b.length()
  if n == 0 && m == 0 {
    return 0.0
  }
  if n == 0 || m == 0 {
    return 1.0e30 // Effectively infinity
  }

  let inf = 1.0e30

  // We optimize memory by maintaining only two rows of length m
  let mut prev = Array::make(m, inf)
  let mut curr = Array::make(m, inf)

  // Initialize first row (i = 0)
  let w_clamped = if window < 0 { m } else { window }

  for j = 0; j < m; j = j + 1 {
    if (0 - j).abs() <= w_clamped {
      let d = point_distance(a[0], b[j])
      if j == 0 {
        prev[0] = d
      } else {
        prev[j] = prev[j - 1] + d
      }
    }
  }

  // Iterate over remaining rows (i = 1 .. n - 1)
  for i = 1; i < n; i = i + 1 {
    for j = 0; j < m; j = j + 1 {
      curr[j] = inf
    }

    for j = 0; j < m; j = j + 1 {
      if (i - j).abs() <= w_clamped {
        let cost = point_distance(a[i], b[j])
        let mut min_prev = prev[j] // Insertion (i-1, j)

        if j > 0 {
          if curr[j - 1] < min_prev {
            min_prev = curr[j - 1] // Deletion (i, j-1)
          }
          if prev[j - 1] < min_prev {
            min_prev = prev[j - 1] // Match (i-1, j-1)
          }
        }

        if min_prev < inf {
          curr[j] = cost + min_prev
        }
      }
    }

    // Swap row buffers
    let tmp = prev
    prev = curr
    curr = tmp
  }

  prev[m - 1]
}

///|
/// Computes length-normalized DTW distance (total_dtw / (len_a + len_b)).
pub fn trajectory_dtw_normalized(
  a : Array[TrajectoryPoint],
  b : Array[TrajectoryPoint],
  window? : Int = -1,
) -> Double {
  let d = trajectory_dtw_distance(a, b, window~)
  let total_len = a.length() + b.length()
  if total_len <= 0 {
    0.0
  } else {
    d / total_len.to_double()
  }
}

///|
/// Computes Discrete Fréchet Distance between two polygonal trajectory curves.
pub fn trajectory_frechet_distance(
  a : Array[TrajectoryPoint],
  b : Array[TrajectoryPoint],
) -> Double {
  let n = a.length()
  let m = b.length()
  if n == 0 && m == 0 {
    return 0.0
  }
  if n == 0 || m == 0 {
    return 1.0e30
  }

  let mut prev = Array::make(m, 0.0)
  let mut curr = Array::make(m, 0.0)

  // Initialize first cell (0, 0)
  prev[0] = point_distance(a[0], b[0])

  // Initialize first row (i = 0, j = 1 .. m - 1)
  for j = 1; j < m; j = j + 1 {
    let d = point_distance(a[0], b[j])
    prev[j] = if d > prev[j - 1] { d } else { prev[j - 1] }
  }

  // Iterate over remaining rows (i = 1 .. n - 1)
  for i = 1; i < n; i = i + 1 {
    // First column of current row: (i, 0)
    let d0 = point_distance(a[i], b[0])
    curr[0] = if d0 > prev[0] { d0 } else { prev[0] }

    for j = 1; j < m; j = j + 1 {
      let d = point_distance(a[i], b[j])
      let mut min_prev = prev[j]
      if curr[j - 1] < min_prev {
        min_prev = curr[j - 1]
      }
      if prev[j - 1] < min_prev {
        min_prev = prev[j - 1]
      }
      curr[j] = if d > min_prev { d } else { min_prev }
    }

    let tmp = prev
    prev = curr
    curr = tmp
  }

  prev[m - 1]
}
