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
