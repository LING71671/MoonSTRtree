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
