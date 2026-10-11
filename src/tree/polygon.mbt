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
/// A 2D point coordinate representing a polygon vertex.
pub struct Point2D {
  x : Double
  y : Double
} derive(Eq, Debug, Default)

///|
/// Creates a new 2D point coordinate.
pub fn Point2D::new(x : Double, y : Double) -> Point2D {
  Point2D::{ x, y, }
}

///|
/// Computes Euclidean distance to another 2D point.
pub fn Point2D::distance_to(self : Point2D, other : Point2D) -> Double {
  let dx = self.x - other.x
  let dy = self.y - other.y
  (dx * dx + dy * dy).sqrt()
}

///|
/// A 2D polygonal planar curve or ring defined by sequential vertices.
pub struct Polygon2D {
  vertices : Array[Point2D]
} derive(Eq, Debug, Default)

///|
/// Creates a new Polygon2D from an ordered array of 2D vertices.
pub fn Polygon2D::new(vertices : Array[Point2D]) -> Polygon2D {
  Polygon2D::{ vertices, }
}

///|
/// Helper to extract distinct sequential ring vertices without trailing duplicate closure.
fn get_open_ring(vertices : Array[Point2D]) -> Array[Point2D] {
  let n = vertices.length()
  if n > 1 &&
    vertices[0].x == vertices[n - 1].x &&
    vertices[0].y == vertices[n - 1].y {
    let res : Array[Point2D] = []
    for i = 0; i < n - 1; i = i + 1 {
      res.push(vertices[i])
    }
    res
  } else {
    vertices
  }
}

///|
/// Computes the planar signed/unsigned area using Green's theorem / Shoelace formula.
pub fn Polygon2D::area(self : Polygon2D) -> Double {
  let ring = get_open_ring(self.vertices)
  let n = ring.length()
  if n < 3 {
    return 0.0
  }
  let mut sum = 0.0
  for i = 0; i < n; i = i + 1 {
    let next_i = (i + 1) % n
    sum = sum + (ring[i].x * ring[next_i].y - ring[next_i].x * ring[i].y)
  }
  let a = sum * 0.5
  if a < 0.0 {
    -a
  } else {
    a
  }
}

///|
/// Computes total boundary perimeter length of the closed polygon.
pub fn Polygon2D::perimeter(self : Polygon2D) -> Double {
  let ring = get_open_ring(self.vertices)
  let n = ring.length()
  if n < 2 {
    return 0.0
  }
  let mut sum = 0.0
  for i = 0; i < n; i = i + 1 {
    let next_i = (i + 1) % n
    sum = sum + ring[i].distance_to(ring[next_i])
  }
  sum
}

///|
/// Returns the minimum axis-aligned bounding box (AABB) enveloping all vertices.
pub fn Polygon2D::envelope(self : Polygon2D) -> @geometry.Rect {
  let n = self.vertices.length()
  if n == 0 {
    return @geometry.Rect::new(0.0, 0.0, 0.0, 0.0)
  }
  let mut min_x = self.vertices[0].x
  let mut max_x = self.vertices[0].x
  let mut min_y = self.vertices[0].y
  let mut max_y = self.vertices[0].y
  for i = 1; i < n; i = i + 1 {
    let p = self.vertices[i]
    if p.x < min_x {
      min_x = p.x
    }
    if p.x > max_x {
      max_x = p.x
    }
    if p.y < min_y {
      min_y = p.y
    }
    if p.y > max_y {
      max_y = p.y
    }
  }
  @geometry.Rect::new(min_x, min_y, max_x, max_y)
}

///|
/// Tests whether a point (px, py) is contained within the polygon boundary using ray casting.
pub fn Polygon2D::contains_point(
  self : Polygon2D,
  px : Double,
  py : Double,
) -> Bool {
  let ring = get_open_ring(self.vertices)
  let n = ring.length()
  if n < 3 {
    return false
  }
  let mut inside = false
  for i = 0; i < n; i = i + 1 {
    let j = (i + 1) % n
    let xi = ring[i].x
    let yi = ring[i].y
    let xj = ring[j].x
    let yj = ring[j].y
    let intersects_edge = (yi > py) != (yj > py) &&
      px < (xj - xi) * (py - yi) / (yj - yi) + xi
    if intersects_edge {
      inside = !inside
    }
  }
  inside
}

///|
/// Computes the planar geometric centroid of the polygon.
pub fn Polygon2D::centroid(self : Polygon2D) -> Point2D {
  let ring = get_open_ring(self.vertices)
  let n = ring.length()
  if n == 0 {
    return Point2D::new(0.0, 0.0)
  }
  if n == 1 {
    return ring[0]
  }
  if n == 2 {
    return Point2D::new(
      (ring[0].x + ring[1].x) * 0.5,
      (ring[0].y + ring[1].y) * 0.5,
    )
  }
  let mut signed_area = 0.0
  let mut cx = 0.0
  let mut cy = 0.0
  for i = 0; i < n; i = i + 1 {
    let next_i = (i + 1) % n
    let factor = ring[i].x * ring[next_i].y - ring[next_i].x * ring[i].y
    signed_area = signed_area + factor
    cx = cx + (ring[i].x + ring[next_i].x) * factor
    cy = cy + (ring[i].y + ring[next_i].y) * factor
  }
  signed_area = signed_area * 0.5
  let abs_area = if signed_area < 0.0 { -signed_area } else { signed_area }
  if abs_area < 1.0e-12 {
    let mut sum_x = 0.0
    let mut sum_y = 0.0
    for i = 0; i < n; i = i + 1 {
      sum_x = sum_x + ring[i].x
      sum_y = sum_y + ring[i].y
    }
    return Point2D::new(sum_x / n.to_double(), sum_y / n.to_double())
  }
  let six_a = 6.0 * signed_area
  Point2D::new(cx / six_a, cy / six_a)
}
