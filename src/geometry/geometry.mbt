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
