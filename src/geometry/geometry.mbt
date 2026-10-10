///|
/// Axis-Aligned Bounding Box (AABB) in continuous 2D space.
pub struct Rect {
  min_x : Double
  min_y : Double
  max_x : Double
  max_y : Double
} derive(Eq, Debug, Default)

///|
/// Constructs a new normalized Rect where min_x <= max_x and min_y <= max_y.
pub fn Rect::new(
  min_x : Double,
  min_y : Double,
  max_x : Double,
  max_y : Double,
) -> Rect {
  let (actual_min_x, actual_max_x) = if min_x > max_x {
    (max_x, min_x)
  } else {
    (min_x, max_x)
  }
  let (actual_min_y, actual_max_y) = if min_y > max_y {
    (max_y, min_y)
  } else {
    (min_y, max_y)
  }
  Rect::{
    min_x: actual_min_x,
    min_y: actual_min_y,
    max_x: actual_max_x,
    max_y: actual_max_y,
  }
}

///|
/// Constructs a degenerate zero-area rectangle centered at (x, y).
pub fn Rect::from_point(x : Double, y : Double) -> Rect {
  Rect::{ min_x: x, min_y: y, max_x: x, max_y: y, }
}

///|
/// Returns true if this rectangle intersects or touches another rectangle.
pub fn Rect::intersects(self : Rect, other : Rect) -> Bool {
  !(self.max_x < other.min_x ||
  self.min_x > other.max_x ||
  self.max_y < other.min_y ||
  self.min_y > other.max_y)
}

///|
/// Returns true if point (x, y) is contained within or on the boundaries of this rectangle.
pub fn Rect::contains_point(self : Rect, x : Double, y : Double) -> Bool {
  self.min_x <= x && x <= self.max_x && self.min_y <= y && y <= self.max_y
}

///|
/// Returns true if this rectangle completely contains another rectangle.
pub fn Rect::contains_rect(self : Rect, other : Rect) -> Bool {
  self.min_x <= other.min_x &&
  other.max_x <= self.max_x &&
  self.min_y <= other.min_y &&
  other.max_y <= self.max_y
}

///|
/// Returns the Minimum Bounding Rectangle (MBR) enclosing both rectangles.
pub fn Rect::union(self : Rect, other : Rect) -> Rect {
  let min_x = if self.min_x < other.min_x { self.min_x } else { other.min_x }
  let min_y = if self.min_y < other.min_y { self.min_y } else { other.min_y }
  let max_x = if self.max_x > other.max_x { self.max_x } else { other.max_x }
  let max_y = if self.max_y > other.max_y { self.max_y } else { other.max_y }
  Rect::{ min_x, min_y, max_x, max_y, }
}

///|
/// Returns the horizontal center coordinate.
pub fn Rect::center_x(self : Rect) -> Double {
  (self.min_x + self.max_x) / 2.0
}

///|
/// Returns the vertical center coordinate.
pub fn Rect::center_y(self : Rect) -> Double {
  (self.min_y + self.max_y) / 2.0
}

///|
/// Returns the width of the rectangle.
pub fn Rect::width(self : Rect) -> Double {
  self.max_x - self.min_x
}

///|
/// Returns the height of the rectangle.
pub fn Rect::height(self : Rect) -> Double {
  self.max_y - self.min_y
}

///|
/// Returns the area of the rectangle.
pub fn Rect::area(self : Rect) -> Double {
  self.width() * self.height()
}

///|
/// Validates that coordinates are non-NaN and min <= max.
pub fn Rect::is_valid(self : Rect) -> Bool {
  self.min_x == self.min_x &&
  self.min_y == self.min_y &&
  self.max_x == self.max_x &&
  self.max_y == self.max_y &&
  self.min_x <= self.max_x &&
  self.min_y <= self.max_y
}

///|
/// Computes the minimum squared Euclidean distance from this rectangle to a point (x, y).
/// Returns 0.0 if the point is inside or on the boundary of the rectangle.
pub fn Rect::distance_squared_to_point(
  self : Rect,
  x : Double,
  y : Double,
) -> Double {
  let dx = if x < self.min_x {
    self.min_x - x
  } else if x > self.max_x {
    x - self.max_x
  } else {
    0.0
  }
  let dy = if y < self.min_y {
    self.min_y - y
  } else if y > self.max_y {
    y - self.max_y
  } else {
    0.0
  }
  dx * dx + dy * dy
}

///|
/// Computes the minimum Euclidean distance from this rectangle to a point (x, y).
pub fn Rect::distance_to_point(self : Rect, x : Double, y : Double) -> Double {
  let sq = self.distance_squared_to_point(x, y)
  if sq <= 0.0 {
    0.0
  } else {
    let mut guess = sq / 2.0
    if guess <= 0.0 {
      guess = 1.0
    }
    for i = 0; i < 20; i = i + 1 {
      guess = (guess + sq / guess) / 2.0
    }
    guess
  }
}

///|
/// Returns true if this rectangle intersects the line segment between (x1, y1) and (x2, y2).
pub fn Rect::intersects_segment(
  self : Rect,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> Bool {
  let seg_min_x = if x1 < x2 { x1 } else { x2 }
  let seg_max_x = if x1 > x2 { x1 } else { x2 }
  let seg_min_y = if y1 < y2 { y1 } else { y2 }
  let seg_max_y = if y1 > y2 { y1 } else { y2 }

  if seg_max_x < self.min_x ||
    seg_min_x > self.max_x ||
    seg_max_y < self.min_y ||
    seg_min_y > self.max_y {
    return false
  }

  if self.contains_point(x1, y1) || self.contains_point(x2, y2) {
    return true
  }

  let dx = x2 - x1
  let dy = y2 - y1

  let mut t_min = 0.0
  let mut t_max = 1.0

  if dx == 0.0 {
    if x1 < self.min_x || x1 > self.max_x {
      return false
    }
  } else {
    let mut t1 = (self.min_x - x1) / dx
    let mut t2 = (self.max_x - x1) / dx
    if t1 > t2 {
      let tmp = t1
      t1 = t2
      t2 = tmp
    }
    if t1 > t_min {
      t_min = t1
    }
    if t2 < t_max {
      t_max = t2
    }
    if t_min > t_max {
      return false
    }
  }

  if dy == 0.0 {
    if y1 < self.min_y || y1 > self.max_y {
      return false
    }
  } else {
    let mut t1 = (self.min_y - y1) / dy
    let mut t2 = (self.max_y - y1) / dy
    if t1 > t2 {
      let tmp = t1
      t1 = t2
      t2 = tmp
    }
    if t1 > t_min {
      t_min = t1
    }
    if t2 < t_max {
      t_max = t2
    }
    if t_min > t_max {
      return false
    }
  }

  t_min <= t_max
}

///|
/// Computes the intersection rectangle of two rectangles.
/// Returns None if the rectangles do not intersect.
pub fn Rect::intersection(self : Rect, other : Rect) -> Rect? {
  if !self.intersects(other) {
    None
  } else {
    let min_x = if self.min_x > other.min_x { self.min_x } else { other.min_x }
    let min_y = if self.min_y > other.min_y { self.min_y } else { other.min_y }
    let max_x = if self.max_x < other.max_x { self.max_x } else { other.max_x }
    let max_y = if self.max_y < other.max_y { self.max_y } else { other.max_y }
    Some(Rect::{ min_x, min_y, max_x, max_y, })
  }
}

///|
/// Returns a new rectangle expanded uniformly by delta on all 4 sides.
/// If delta is negative, the rectangle shrinks (normalized so min <= max).
pub fn Rect::expand(self : Rect, delta : Double) -> Rect {
  Rect::new(
    self.min_x - delta,
    self.min_y - delta,
    self.max_x + delta,
    self.max_y + delta,
  )
}

///|
/// Computes minimum squared Euclidean distance between two rectangles.
/// Returns 0.0 if the rectangles intersect.
pub fn Rect::distance_squared_to_rect(self : Rect, other : Rect) -> Double {
  if self.intersects(other) {
    0.0
  } else {
    let dx = if self.max_x < other.min_x {
      other.min_x - self.max_x
    } else if self.min_x > other.max_x {
      self.min_x - other.max_x
    } else {
      0.0
    }
    let dy = if self.max_y < other.min_y {
      other.min_y - self.max_y
    } else if self.min_y > other.max_y {
      self.min_y - other.max_y
    } else {
      0.0
    }
    dx * dx + dy * dy
  }
}

///|
/// Computes minimum Euclidean distance between two rectangles.
pub fn Rect::distance_to_rect(self : Rect, other : Rect) -> Double {
  let sq = self.distance_squared_to_rect(other)
  if sq <= 0.0 {
    0.0
  } else {
    let mut guess = sq / 2.0
    if guess <= 0.0 {
      guess = 1.0
    }
    for i = 0; i < 20; i = i + 1 {
      guess = (guess + sq / guess) / 2.0
    }
    guess
  }
}

///|
/// Computes Intersection over Union (IoU) metric in [0.0, 1.0].
pub fn Rect::iou(self : Rect, other : Rect) -> Double {
  match self.intersection(other) {
    None => 0.0
    Some(inter) => {
      let inter_area = inter.area()
      let union_area = self.area() + other.area() - inter_area
      if union_area <= 0.0 {
        0.0
      } else {
        inter_area / union_area
      }
    }
  }
}

///|
/// Returns true if this rectangle intersects or touches a circle centered at (cx, cy) with given radius.
pub fn Rect::intersects_circle(
  self : Rect,
  cx : Double,
  cy : Double,
  radius : Double,
) -> Bool {
  if radius < 0.0 {
    false
  } else {
    self.distance_squared_to_point(cx, cy) <= radius * radius
  }
}

///|
/// Axis-Aligned Bounding Box (AABB) in continuous 3D space.
pub struct Box3D {
  min_x : Double
  min_y : Double
  min_z : Double
  max_x : Double
  max_y : Double
  max_z : Double
} derive(Eq, Debug, Default)

///|
/// Constructs a new normalized Box3D where min <= max along all 3 axes.
pub fn Box3D::new(
  min_x : Double,
  min_y : Double,
  min_z : Double,
  max_x : Double,
  max_y : Double,
  max_z : Double,
) -> Box3D {
  let actual_min_x = if min_x > max_x { max_x } else { min_x }
  let actual_max_x = if min_x > max_x { min_x } else { max_x }
  let actual_min_y = if min_y > max_y { max_y } else { min_y }
  let actual_max_y = if min_y > max_y { min_y } else { max_y }
  let actual_min_z = if min_z > max_z { max_z } else { min_z }
  let actual_max_z = if min_z > max_z { min_z } else { max_z }
  Box3D::{
    min_x: actual_min_x,
    min_y: actual_min_y,
    min_z: actual_min_z,
    max_x: actual_max_x,
    max_y: actual_max_y,
    max_z: actual_max_z,
  }
}

///|
/// Constructs a degenerate zero-volume box centered at (x, y, z).
pub fn Box3D::from_point(x : Double, y : Double, z : Double) -> Box3D {
  Box3D::{ min_x: x, min_y: y, min_z: z, max_x: x, max_y: y, max_z: z, }
}

///|
/// Returns true if this box intersects or touches another 3D box.
pub fn Box3D::intersects(self : Box3D, other : Box3D) -> Bool {
  !(self.max_x < other.min_x ||
  self.min_x > other.max_x ||
  self.max_y < other.min_y ||
  self.min_y > other.max_y ||
  self.max_z < other.min_z ||
  self.min_z > other.max_z)
}

///|
/// Returns true if point (x, y, z) is contained within or on the boundaries of this 3D box.
pub fn Box3D::contains_point(
  self : Box3D,
  x : Double,
  y : Double,
  z : Double,
) -> Bool {
  self.min_x <= x &&
  x <= self.max_x &&
  self.min_y <= y &&
  y <= self.max_y &&
  self.min_z <= z &&
  z <= self.max_z
}

///|
/// Returns true if this box completely encloses another 3D box.
pub fn Box3D::contains_box(self : Box3D, other : Box3D) -> Bool {
  self.min_x <= other.min_x &&
  other.max_x <= self.max_x &&
  self.min_y <= other.min_y &&
  other.max_y <= self.max_y &&
  self.min_z <= other.min_z &&
  other.max_z <= self.max_z
}

///|
/// Returns the Minimum Bounding Box (MBB) enclosing both 3D boxes.
pub fn Box3D::union(self : Box3D, other : Box3D) -> Box3D {
  let min_x = if self.min_x < other.min_x { self.min_x } else { other.min_x }
  let min_y = if self.min_y < other.min_y { self.min_y } else { other.min_y }
  let min_z = if self.min_z < other.min_z { self.min_z } else { other.min_z }
  let max_x = if self.max_x > other.max_x { self.max_x } else { other.max_x }
  let max_y = if self.max_y > other.max_y { self.max_y } else { other.max_y }
  let max_z = if self.max_z > other.max_z { self.max_z } else { other.max_z }
  Box3D::{ min_x, min_y, min_z, max_x, max_y, max_z, }
}

///|
/// Computes the intersection 3D box of two boxes, or None if disjoint.
pub fn Box3D::intersection(self : Box3D, other : Box3D) -> Box3D? {
  if !self.intersects(other) {
    None
  } else {
    let min_x = if self.min_x > other.min_x { self.min_x } else { other.min_x }
    let min_y = if self.min_y > other.min_y { self.min_y } else { other.min_y }
    let min_z = if self.min_z > other.min_z { self.min_z } else { other.min_z }
    let max_x = if self.max_x < other.max_x { self.max_x } else { other.max_x }
    let max_y = if self.max_y < other.max_y { self.max_y } else { other.max_y }
    let max_z = if self.max_z < other.max_z { self.max_z } else { other.max_z }
    Some(Box3D::{ min_x, min_y, min_z, max_x, max_y, max_z, })
  }
}

///|
/// Computes the volume of this 3D box.
pub fn Box3D::volume(self : Box3D) -> Double {
  (self.max_x - self.min_x) *
  (self.max_y - self.min_y) *
  (self.max_z - self.min_z)
}

///|
/// Computes total surface area of this 3D box.
pub fn Box3D::surface_area(self : Box3D) -> Double {
  let dx = self.max_x - self.min_x
  let dy = self.max_y - self.min_y
  let dz = self.max_z - self.min_z
  2.0 * (dx * dy + dy * dz + dz * dx)
}

///|
/// Center X coordinate.
pub fn Box3D::center_x(self : Box3D) -> Double {
  (self.min_x + self.max_x) / 2.0
}

///|
/// Center Y coordinate.
pub fn Box3D::center_y(self : Box3D) -> Double {
  (self.min_y + self.max_y) / 2.0
}

///|
/// Center Z coordinate.
pub fn Box3D::center_z(self : Box3D) -> Double {
  (self.min_z + self.max_z) / 2.0
}

///|
/// Returns a new 3D box expanded uniformly by delta along all 6 faces.
pub fn Box3D::expand(self : Box3D, delta : Double) -> Box3D {
  Box3D::new(
    self.min_x - delta,
    self.min_y - delta,
    self.min_z - delta,
    self.max_x + delta,
    self.max_y + delta,
    self.max_z + delta,
  )
}

///|
/// Computes squared Euclidean distance from this 3D box to point (x, y, z).
pub fn Box3D::distance_squared_to_point(
  self : Box3D,
  x : Double,
  y : Double,
  z : Double,
) -> Double {
  let dx = if x < self.min_x {
    self.min_x - x
  } else if x > self.max_x {
    x - self.max_x
  } else {
    0.0
  }
  let dy = if y < self.min_y {
    self.min_y - y
  } else if y > self.max_y {
    y - self.max_y
  } else {
    0.0
  }
  let dz = if z < self.min_z {
    self.min_z - z
  } else if z > self.max_z {
    z - self.max_z
  } else {
    0.0
  }
  dx * dx + dy * dy + dz * dz
}

///|
/// Computes minimum Euclidean distance between this 3D box and another 3D box.
/// Returns 0.0 if boxes intersect or touch.
pub fn Box3D::distance_to_box(self : Box3D, other : Box3D) -> Double {
  if self.intersects(other) {
    0.0
  } else {
    let dx = if self.max_x < other.min_x {
      other.min_x - self.max_x
    } else if other.max_x < self.min_x {
      self.min_x - other.max_x
    } else {
      0.0
    }
    let dy = if self.max_y < other.min_y {
      other.min_y - self.max_y
    } else if other.max_y < self.min_y {
      self.min_y - other.max_y
    } else {
      0.0
    }
    let dz = if self.max_z < other.min_z {
      other.min_z - self.max_z
    } else if other.max_z < self.min_z {
      self.min_z - other.max_z
    } else {
      0.0
    }
    (dx * dx + dy * dy + dz * dz).sqrt()
  }
}

///|
/// Computes volumetric Intersection over Union (IoU) of two 3D boxes in [0.0, 1.0].
pub fn Box3D::iou(self : Box3D, other : Box3D) -> Double {
  match self.intersection(other) {
    None => 0.0
    Some(inter) => {
      let inter_vol = inter.volume()
      let union_vol = self.volume() + other.volume() - inter_vol
      if union_vol <= 0.0 {
        0.0
      } else {
        inter_vol / union_vol
      }
    }
  }
}

///|
/// Returns true if this 3D box intersects a sphere centered at (cx, cy, cz) with given radius.
pub fn Box3D::intersects_sphere(
  self : Box3D,
  cx : Double,
  cy : Double,
  cz : Double,
  radius : Double,
) -> Bool {
  if radius < 0.0 {
    false
  } else {
    self.distance_squared_to_point(cx, cy, cz) <= radius * radius
  }
}

///|
/// Returns true if this 3D box intersects the 3D line segment between (x1, y1, z1) and (x2, y2, z2).
pub fn Box3D::intersects_segment(
  self : Box3D,
  x1 : Double,
  y1 : Double,
  z1 : Double,
  x2 : Double,
  y2 : Double,
  z2 : Double,
) -> Bool {
  let seg_min_x = if x1 < x2 { x1 } else { x2 }
  let seg_max_x = if x1 > x2 { x1 } else { x2 }
  let seg_min_y = if y1 < y2 { y1 } else { y2 }
  let seg_max_y = if y1 > y2 { y1 } else { y2 }
  let seg_min_z = if z1 < z2 { z1 } else { z2 }
  let seg_max_z = if z1 > z2 { z1 } else { z2 }

  if seg_max_x < self.min_x ||
    seg_min_x > self.max_x ||
    seg_max_y < self.min_y ||
    seg_min_y > self.max_y ||
    seg_max_z < self.min_z ||
    seg_min_z > self.max_z {
    return false
  }

  if self.contains_point(x1, y1, z1) || self.contains_point(x2, y2, z2) {
    return true
  }

  let dx = x2 - x1
  let dy = y2 - y1
  let dz = z2 - z1

  let mut t_min = 0.0
  let mut t_max = 1.0

  if dx == 0.0 {
    if x1 < self.min_x || x1 > self.max_x {
      return false
    }
  } else {
    let mut t1 = (self.min_x - x1) / dx
    let mut t2 = (self.max_x - x1) / dx
    if t1 > t2 {
      let tmp = t1
      t1 = t2
      t2 = tmp
    }
    if t1 > t_min {
      t_min = t1
    }
    if t2 < t_max {
      t_max = t2
    }
    if t_min > t_max {
      return false
    }
  }

  if dy == 0.0 {
    if y1 < self.min_y || y1 > self.max_y {
      return false
    }
  } else {
    let mut t1 = (self.min_y - y1) / dy
    let mut t2 = (self.max_y - y1) / dy
    if t1 > t2 {
      let tmp = t1
      t1 = t2
      t2 = tmp
    }
    if t1 > t_min {
      t_min = t1
    }
    if t2 < t_max {
      t_max = t2
    }
    if t_min > t_max {
      return false
    }
  }

  if dz == 0.0 {
    if z1 < self.min_z || z1 > self.max_z {
      return false
    }
  } else {
    let mut t1 = (self.min_z - z1) / dz
    let mut t2 = (self.max_z - z1) / dz
    if t1 > t2 {
      let tmp = t1
      t1 = t2
      t2 = tmp
    }
    if t1 > t_min {
      t_min = t1
    }
    if t2 < t_max {
      t_max = t2
    }
    if t_min > t_max {
      return false
    }
  }

  t_min <= t_max
}

///|
fn min3(a : Double, b : Double, c : Double) -> Double {
  let m1 = if a < b { a } else { b }
  if m1 < c {
    m1
  } else {
    c
  }
}

///|
fn max3(a : Double, b : Double, c : Double) -> Double {
  let m1 = if a > b { a } else { b }
  if m1 > c {
    m1
  } else {
    c
  }
}

///|
fn sqrt_nr(val : Double) -> Double {
  if val <= 0.0 {
    return 0.0
  }
  let mut x = val
  for i = 0; i < 20; i = i + 1 {
    x = 0.5 * (x + val / x)
  }
  x
}

///|
/// 3D Triangle represented by three 3D vertices in continuous space.
pub struct Triangle3D {
  p0_x : Double
  p0_y : Double
  p0_z : Double
  p1_x : Double
  p1_y : Double
  p1_z : Double
  p2_x : Double
  p2_y : Double
  p2_z : Double
} derive(Eq, Debug, Default)

///|
/// Constructs a new Triangle3D with vertices (p0, p1, p2).
pub fn Triangle3D::new(
  p0_x : Double,
  p0_y : Double,
  p0_z : Double,
  p1_x : Double,
  p1_y : Double,
  p1_z : Double,
  p2_x : Double,
  p2_y : Double,
  p2_z : Double,
) -> Triangle3D {
  Triangle3D::{ p0_x, p0_y, p0_z, p1_x, p1_y, p1_z, p2_x, p2_y, p2_z, }
}

///|
/// Computes the tight Axis-Aligned Bounding Box (Box3D) enclosing the triangle.
pub fn Triangle3D::to_box(self : Triangle3D) -> Box3D {
  let min_x = min3(self.p0_x, self.p1_x, self.p2_x)
  let min_y = min3(self.p0_y, self.p1_y, self.p2_y)
  let min_z = min3(self.p0_z, self.p1_z, self.p2_z)
  let max_x = max3(self.p0_x, self.p1_x, self.p2_x)
  let max_y = max3(self.p0_y, self.p1_y, self.p2_y)
  let max_z = max3(self.p0_z, self.p1_z, self.p2_z)
  Box3D::{ min_x, min_y, min_z, max_x, max_y, max_z, }
}

///|
/// Computes the centroid (arithmetic center) of the triangle.
pub fn Triangle3D::centroid(self : Triangle3D) -> (Double, Double, Double) {
  (
    (self.p0_x + self.p1_x + self.p2_x) / 3.0,
    (self.p0_y + self.p1_y + self.p2_y) / 3.0,
    (self.p0_z + self.p1_z + self.p2_z) / 3.0,
  )
}

///|
/// Computes the surface normal vector of the triangle (unnormalized if degenerate, normalized otherwise).
pub fn Triangle3D::normal(self : Triangle3D) -> (Double, Double, Double) {
  let e1_x = self.p1_x - self.p0_x
  let e1_y = self.p1_y - self.p0_y
  let e1_z = self.p1_z - self.p0_z
  let e2_x = self.p2_x - self.p0_x
  let e2_y = self.p2_y - self.p0_y
  let e2_z = self.p2_z - self.p0_z
  let nx = e1_y * e2_z - e1_z * e2_y
  let ny = e1_z * e2_x - e1_x * e2_z
  let nz = e1_x * e2_y - e1_y * e2_x
  let len_sq = nx * nx + ny * ny + nz * nz
  if len_sq < 1.0e-18 {
    (0.0, 0.0, 1.0)
  } else {
    let len = sqrt_nr(len_sq)
    (nx / len, ny / len, nz / len)
  }
}

///|
/// Computes the surface area of the triangle.
pub fn Triangle3D::area(self : Triangle3D) -> Double {
  let e1_x = self.p1_x - self.p0_x
  let e1_y = self.p1_y - self.p0_y
  let e1_z = self.p1_z - self.p0_z
  let e2_x = self.p2_x - self.p0_x
  let e2_y = self.p2_y - self.p0_y
  let e2_z = self.p2_z - self.p0_z
  let nx = e1_y * e2_z - e1_z * e2_y
  let ny = e1_z * e2_x - e1_x * e2_z
  let nz = e1_x * e2_y - e1_y * e2_x
  0.5 * sqrt_nr(nx * nx + ny * ny + nz * nz)
}

///|
/// Tests if a 3D ray from (ox, oy, oz) with direction (dx, dy, dz) intersects the triangle.
/// Returns Some(t) where t >= 0.0 is the ray distance if hit, or None if missed.
/// Implemented using the two-sided Möller–Trumbore intersection algorithm.
pub fn Triangle3D::ray_intersection(
  self : Triangle3D,
  ox : Double,
  oy : Double,
  oz : Double,
  dx : Double,
  dy : Double,
  dz : Double,
) -> Double? {
  let e1_x = self.p1_x - self.p0_x
  let e1_y = self.p1_y - self.p0_y
  let e1_z = self.p1_z - self.p0_z
  let e2_x = self.p2_x - self.p0_x
  let e2_y = self.p2_y - self.p0_y
  let e2_z = self.p2_z - self.p0_z

  let p_x = dy * e2_z - dz * e2_y
  let p_y = dz * e2_x - dx * e2_z
  let p_z = dx * e2_y - dy * e2_x

  let det = e1_x * p_x + e1_y * p_y + e1_z * p_z
  if det > -1.0e-12 && det < 1.0e-12 {
    return None
  }
  let inv_det = 1.0 / det

  let t_x = ox - self.p0_x
  let t_y = oy - self.p0_y
  let t_z = oz - self.p0_z

  let u = (t_x * p_x + t_y * p_y + t_z * p_z) * inv_det
  if u < 0.0 || u > 1.0 {
    return None
  }

  let q_x = t_y * e1_z - t_z * e1_y
  let q_y = t_z * e1_x - t_x * e1_z
  let q_z = t_x * e1_y - t_y * e1_x

  let v = (dx * q_x + dy * q_y + dz * q_z) * inv_det
  if v < 0.0 || u + v > 1.0 {
    return None
  }

  let t = (e2_x * q_x + e2_y * q_y + e2_z * q_z) * inv_det
  if t < 0.0 {
    None
  } else {
    Some(t)
  }
}

///|
/// Tests if a finite 3D line segment (x1, y1, z1) -> (x2, y2, z2) intersects the triangle.
pub fn Triangle3D::intersects_segment(
  self : Triangle3D,
  x1 : Double,
  y1 : Double,
  z1 : Double,
  x2 : Double,
  y2 : Double,
  z2 : Double,
) -> Bool {
  let dx = x2 - x1
  let dy = y2 - y1
  let dz = z2 - z1
  match self.ray_intersection(x1, y1, z1, dx, dy, dz) {
    Some(t) => t >= 0.0 && t <= 1.0
    None => false
  }
}

///|
/// Axis-Aligned Spatiotemporal Bounding Box (4D Hypervolume) in continuous (x, y, z, t) space.
pub struct Box4D {
  min_x : Double
  min_y : Double
  min_z : Double
  min_t : Double
  max_x : Double
  max_y : Double
  max_z : Double
  max_t : Double
} derive(Eq, Debug, Default)

///|
/// Constructs a new normalized Box4D where min <= max along each axis.
pub fn Box4D::new(
  min_x : Double,
  min_y : Double,
  min_z : Double,
  min_t : Double,
  max_x : Double,
  max_y : Double,
  max_z : Double,
  max_t : Double,
) -> Box4D {
  let norm_min_x = if min_x < max_x { min_x } else { max_x }
  let norm_max_x = if min_x > max_x { min_x } else { max_x }
  let norm_min_y = if min_y < max_y { min_y } else { max_y }
  let norm_max_y = if min_y > max_y { min_y } else { max_y }
  let norm_min_z = if min_z < max_z { min_z } else { max_z }
  let norm_max_z = if min_z > max_z { min_z } else { max_z }
  let norm_min_t = if min_t < max_t { min_t } else { max_t }
  let norm_max_t = if min_t > max_t { min_t } else { max_t }
  Box4D::{
    min_x: norm_min_x,
    min_y: norm_min_y,
    min_z: norm_min_z,
    min_t: norm_min_t,
    max_x: norm_max_x,
    max_y: norm_max_y,
    max_z: norm_max_z,
    max_t: norm_max_t,
  }
}

///|
/// Constructs a degenerate zero-hypervolume Box4D centered at (x, y, z, t).
pub fn Box4D::from_point(
  x : Double,
  y : Double,
  z : Double,
  t : Double,
) -> Box4D {
  Box4D::{
    min_x: x,
    min_y: y,
    min_z: z,
    min_t: t,
    max_x: x,
    max_y: y,
    max_z: z,
    max_t: t,
  }
}

///|
/// Returns true if this 4D box intersects another 4D box across all dimensions (x, y, z, t).
pub fn Box4D::intersects(self : Box4D, other : Box4D) -> Bool {
  !(self.max_x < other.min_x ||
  self.min_x > other.max_x ||
  self.max_y < other.min_y ||
  self.min_y > other.max_y ||
  self.max_z < other.min_z ||
  self.min_z > other.max_z ||
  self.max_t < other.min_t ||
  self.min_t > other.max_t)
}

///|
/// Returns true if 4D coordinate (x, y, z, t) is contained within or on boundaries.
pub fn Box4D::contains_point(
  self : Box4D,
  x : Double,
  y : Double,
  z : Double,
  t : Double,
) -> Bool {
  self.min_x <= x &&
  x <= self.max_x &&
  self.min_y <= y &&
  y <= self.max_y &&
  self.min_z <= z &&
  z <= self.max_z &&
  self.min_t <= t &&
  t <= self.max_t
}

///|
/// Returns true if this box completely contains another 4D box.
pub fn Box4D::contains_box(self : Box4D, other : Box4D) -> Bool {
  self.min_x <= other.min_x &&
  other.max_x <= self.max_x &&
  self.min_y <= other.min_y &&
  other.max_y <= self.max_y &&
  self.min_z <= other.min_z &&
  other.max_z <= self.max_z &&
  self.min_t <= other.min_t &&
  other.max_t <= self.max_t
}

///|
/// Computes the Minimum Bounding Hypervolume enclosing both 4D boxes.
pub fn Box4D::union(self : Box4D, other : Box4D) -> Box4D {
  let min_x = if self.min_x < other.min_x { self.min_x } else { other.min_x }
  let min_y = if self.min_y < other.min_y { self.min_y } else { other.min_y }
  let min_z = if self.min_z < other.min_z { self.min_z } else { other.min_z }
  let min_t = if self.min_t < other.min_t { self.min_t } else { other.min_t }
  let max_x = if self.max_x > other.max_x { self.max_x } else { other.max_x }
  let max_y = if self.max_y > other.max_y { self.max_y } else { other.max_y }
  let max_z = if self.max_z > other.max_z { self.max_z } else { other.max_z }
  let max_t = if self.max_t > other.max_t { self.max_t } else { other.max_t }
  Box4D::{ min_x, min_y, min_z, min_t, max_x, max_y, max_z, max_t, }
}

///|
/// Computes intersection of two 4D boxes, or None if disjoint.
pub fn Box4D::intersection(self : Box4D, other : Box4D) -> Box4D? {
  if !self.intersects(other) {
    None
  } else {
    let min_x = if self.min_x > other.min_x { self.min_x } else { other.min_x }
    let min_y = if self.min_y > other.min_y { self.min_y } else { other.min_y }
    let min_z = if self.min_z > other.min_z { self.min_z } else { other.min_z }
    let min_t = if self.min_t > other.min_t { self.min_t } else { other.min_t }
    let max_x = if self.max_x < other.max_x { self.max_x } else { other.max_x }
    let max_y = if self.max_y < other.max_y { self.max_y } else { other.max_y }
    let max_z = if self.max_z < other.max_z { self.max_z } else { other.max_z }
    let max_t = if self.max_t < other.max_t { self.max_t } else { other.max_t }
    Some(Box4D::{ min_x, min_y, min_z, min_t, max_x, max_y, max_z, max_t, })
  }
}

///|
/// Computes the 4D hypervolume (length_x * length_y * length_z * length_t).
pub fn Box4D::hyper_volume(self : Box4D) -> Double {
  (self.max_x - self.min_x) *
  (self.max_y - self.min_y) *
  (self.max_z - self.min_z) *
  (self.max_t - self.min_t)
}

///|
/// Extracts the spatial 3D bounding box (Box3D) ignoring time dimension.
pub fn Box4D::to_box3d(self : Box4D) -> Box3D {
  Box3D::{
    min_x: self.min_x,
    min_y: self.min_y,
    min_z: self.min_z,
    max_x: self.max_x,
    max_y: self.max_y,
    max_z: self.max_z,
  }
}

///|
/// Expands 4D box by delta margins along each dimension.
pub fn Box4D::expand(
  self : Box4D,
  dx : Double,
  dy : Double,
  dz : Double,
  dt : Double,
) -> Box4D {
  Box4D::new(
    self.min_x - dx,
    self.min_y - dy,
    self.min_z - dz,
    self.min_t - dt,
    self.max_x + dx,
    self.max_y + dy,
    self.max_z + dz,
    self.max_t + dt,
  )
}

///|
/// Checks if this 4D box intersects another at a specific instant of time t.
pub fn Box4D::intersects_at_time(
  self : Box4D,
  other : Box4D,
  t : Double,
) -> Bool {
  if t < self.min_t || t > self.max_t || t < other.min_t || t > other.max_t {
    false
  } else {
    self.to_box3d().intersects(other.to_box3d())
  }
}

///|
/// Named spatial predicates for Dimensionally Extended 9-Intersection Model (DE-9IM).
pub(all) enum SpatialPredicate {
  Intersects
  Contains
  Within
  Touches
  Overlaps
  Disjoint
  Equals
  Covers
  CoveredBy
} derive(Eq, Debug)

///|
/// Parses a string representation into a SpatialPredicate.
pub fn SpatialPredicate::from_string(name : String) -> SpatialPredicate? {
  match name {
    "intersects" => Some(Intersects)
    "contains" => Some(Contains)
    "within" => Some(Within)
    "touches" => Some(Touches)
    "overlaps" => Some(Overlaps)
    "disjoint" => Some(Disjoint)
    "equals" => Some(Equals)
    "covers" => Some(Covers)
    "covered_by" => Some(CoveredBy)
    _ => None
  }
}

///|
/// Converts a SpatialPredicate into its standard name string.
pub fn SpatialPredicate::to_string(self : SpatialPredicate) -> String {
  match self {
    Intersects => "intersects"
    Contains => "contains"
    Within => "within"
    Touches => "touches"
    Overlaps => "overlaps"
    Disjoint => "disjoint"
    Equals => "equals"
    Covers => "covers"
    CoveredBy => "covered_by"
  }
}

///|
/// Returns true if this rectangle touches another rectangle (boundaries intersect, interiors disjoint).
pub fn Rect::touches(self : Rect, other : Rect) -> Bool {
  if !self.intersects(other) {
    return false
  }
  let overlap_x = self.min_x < other.max_x && self.max_x > other.min_x
  let overlap_y = self.min_y < other.max_y && self.max_y > other.min_y
  !(overlap_x && overlap_y)
}

///|
/// Returns true if this rectangle topologically covers another rectangle.
pub fn Rect::covers(self : Rect, other : Rect) -> Bool {
  self.contains_rect(other)
}

///|
/// Returns true if this rectangle is topologically covered by another rectangle.
pub fn Rect::covered_by(self : Rect, other : Rect) -> Bool {
  other.contains_rect(self)
}

///|
/// Returns true if this rectangle contains another rectangle with non-empty interior intersection.
pub fn Rect::contains(self : Rect, other : Rect) -> Bool {
  if !self.covers(other) {
    return false
  }
  let overlap_x = self.min_x < other.max_x && self.max_x > other.min_x
  let overlap_y = self.min_y < other.max_y && self.max_y > other.min_y
  overlap_x && overlap_y
}

///|
/// Returns true if this rectangle is within another rectangle.
pub fn Rect::within(self : Rect, other : Rect) -> Bool {
  other.contains(self)
}

///|
/// Returns true if two rectangles have identical boundaries.
pub fn Rect::equals_exact(self : Rect, other : Rect) -> Bool {
  self.min_x == other.min_x &&
  self.min_y == other.min_y &&
  self.max_x == other.max_x &&
  self.max_y == other.max_y
}

///|
/// Returns true if two rectangles are completely disjoint (no common points).
pub fn Rect::disjoint(self : Rect, other : Rect) -> Bool {
  !self.intersects(other)
}

///|
/// Returns true if two rectangles overlap (interiors intersect, but neither covers the other).
pub fn Rect::overlaps(self : Rect, other : Rect) -> Bool {
  let overlap_x = self.min_x < other.max_x && self.max_x > other.min_x
  let overlap_y = self.min_y < other.max_y && self.max_y > other.min_y
  overlap_x && overlap_y && !self.covers(other) && !other.covers(self)
}

///|
/// Evaluates a named spatial predicate between two rectangles.
pub fn Rect::evaluate_predicate(
  self : Rect,
  other : Rect,
  predicate : SpatialPredicate,
) -> Bool {
  match predicate {
    Intersects => self.intersects(other)
    Contains => self.contains(other)
    Within => self.within(other)
    Touches => self.touches(other)
    Overlaps => self.overlaps(other)
    Disjoint => self.disjoint(other)
    Equals => self.equals_exact(other)
    Covers => self.covers(other)
    CoveredBy => self.covered_by(other)
  }
}

///|
/// Computes the Dimensionally Extended 9-Intersection Model (DE-9IM) matrix string (9 characters).
pub fn Rect::relate(self : Rect, other : Rect) -> String {
  let overlap_x = self.min_x < other.max_x && self.max_x > other.min_x
  let overlap_y = self.min_y < other.max_y && self.max_y > other.min_y

  let c0 = if overlap_x && overlap_y { '2' } else { 'F' }

  let b_in_ia = (
      other.min_x > self.min_x && other.min_x < self.max_x && overlap_y
    ) ||
    (other.max_x > self.min_x && other.max_x < self.max_x && overlap_y) ||
    (other.min_y > self.min_y && other.min_y < self.max_y && overlap_x) ||
    (other.max_y > self.min_y && other.max_y < self.max_y && overlap_x)
  let c1 = if b_in_ia { '1' } else { 'F' }

  let c2 = if other.covers(self) { 'F' } else { '2' }

  let a_in_ib = (
      self.min_x > other.min_x && self.min_x < other.max_x && overlap_y
    ) ||
    (self.max_x > other.min_x && self.max_x < other.max_x && overlap_y) ||
    (self.min_y > other.min_y && self.min_y < other.max_y && overlap_x) ||
    (self.max_y > other.min_y && self.max_y < other.max_y && overlap_x)
  let c3 = if a_in_ib { '1' } else { 'F' }

  let share_1d = (
      (
        self.min_x == other.min_x ||
        self.min_x == other.max_x ||
        self.max_x == other.min_x ||
        self.max_x == other.max_x
      ) &&
      overlap_y
    ) ||
    (
      (
        self.min_y == other.min_y ||
        self.min_y == other.max_y ||
        self.max_y == other.min_y ||
        self.max_y == other.max_y
      ) &&
      overlap_x
    )
  let c4 = if share_1d {
    '1'
  } else if self.intersects(other) {
    '0'
  } else {
    'F'
  }

  let a_strictly_in_ib = other.min_x < self.min_x &&
    other.max_x > self.max_x &&
    other.min_y < self.min_y &&
    other.max_y > self.max_y
  let c5 = if self.equals_exact(other) || a_strictly_in_ib { 'F' } else { '1' }

  let c6 = if self.covers(other) { 'F' } else { '2' }

  let b_strictly_in_ia = self.min_x < other.min_x &&
    self.max_x > other.max_x &&
    self.min_y < other.min_y &&
    self.max_y > other.max_y
  let c7 = if self.equals_exact(other) || b_strictly_in_ia { 'F' } else { '1' }

  let c8 = '2'

  let buf = StringBuilder()
  buf.write_char(c0)
  buf.write_char(c1)
  buf.write_char(c2)
  buf.write_char(c3)
  buf.write_char(c4)
  buf.write_char(c5)
  buf.write_char(c6)
  buf.write_char(c7)
  buf.write_char(c8)
  buf.to_string()
}

///|
/// Checks whether a 9-character DE-9IM intersection matrix matches an intersection pattern.
pub fn matches_de9im_pattern(matrix : String, pattern : String) -> Bool {
  if matrix.length() != 9 || pattern.length() != 9 {
    return false
  }
  for i = 0; i < 9; i = i + 1 {
    let p = pattern[i]
    let m = matrix[i]
    if p == '*' {
      continue
    }
    if p == 'T' {
      if m != '0' && m != '1' && m != '2' {
        return false
      }
      continue
    }
    if p == 'F' {
      if m != 'F' {
        return false
      }
      continue
    }
    if p != m {
      return false
    }
  }
  true
}
