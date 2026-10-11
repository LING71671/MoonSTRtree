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
