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
