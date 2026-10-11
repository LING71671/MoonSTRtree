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
    let len = len_sq.sqrt()
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
  0.5 * (nx * nx + ny * ny + nz * nz).sqrt()
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
