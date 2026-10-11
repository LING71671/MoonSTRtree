///|
/// Triangle represented by three 3D vertices in continuous space.
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
/// Converts to internal geometry primitive.
fn Triangle3D::to_geometry(self : Triangle3D) -> @geometry.Triangle3D {
  @geometry.Triangle3D::new(
    self.p0_x,
    self.p0_y,
    self.p0_z,
    self.p1_x,
    self.p1_y,
    self.p1_z,
    self.p2_x,
    self.p2_y,
    self.p2_z,
  )
}

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
  let b = self.to_geometry().to_box()
  Box3D::new(b.min_x, b.min_y, b.min_z, b.max_x, b.max_y, b.max_z)
}

///|
/// Computes the centroid (arithmetic center) of the triangle.
pub fn Triangle3D::centroid(self : Triangle3D) -> (Double, Double, Double) {
  self.to_geometry().centroid()
}

///|
/// Computes the surface normal vector of the triangle.
pub fn Triangle3D::normal(self : Triangle3D) -> (Double, Double, Double) {
  self.to_geometry().normal()
}

///|
/// Computes the surface area of the triangle.
pub fn Triangle3D::area(self : Triangle3D) -> Double {
  self.to_geometry().area()
}

///|
/// Tests if a 3D ray intersects the triangle, returning hit distance t.
pub fn Triangle3D::ray_intersection(
  self : Triangle3D,
  ox : Double,
  oy : Double,
  oz : Double,
  dx : Double,
  dy : Double,
  dz : Double,
) -> Double? {
  self.to_geometry().ray_intersection(ox, oy, oz, dx, dy, dz)
}

///|
/// Tests if a finite 3D line segment intersects the triangle.
pub fn Triangle3D::intersects_segment(
  self : Triangle3D,
  x1 : Double,
  y1 : Double,
  z1 : Double,
  x2 : Double,
  y2 : Double,
  z2 : Double,
) -> Bool {
  self.to_geometry().intersects_segment(x1, y1, z1, x2, y2, z2)
}

///|
/// Packed 3D spatial index for polygonal triangle meshes with accelerated ray-tracing and segment intersection.
pub struct StrMeshTree3D {
  priv inner : @tree.StrMeshTree3D
} derive(Eq, Debug, Default)

///|
/// Builds a packed 3D mesh index from an array of Triangle3D primitives.
pub fn StrMeshTree3D::build(
  triangles : Array[Triangle3D],
  node_capacity? : Int = 16,
) -> StrMeshTree3D {
  let g_triangles : Array[@geometry.Triangle3D] = []
  for i = 0; i < triangles.length(); i = i + 1 {
    g_triangles.push(triangles[i].to_geometry())
  }
  let inner = @tree.StrMeshTree3D::build(g_triangles, node_capacity~)
  StrMeshTree3D::{ inner, }
}

///|
/// Returns total number of indexed mesh triangles.
pub fn StrMeshTree3D::num_triangles(self : StrMeshTree3D) -> Int {
  self.inner.num_triangles()
}

///|
/// Retrieves triangle primitive by index.
pub fn StrMeshTree3D::get_triangle(
  self : StrMeshTree3D,
  id : Int,
) -> Triangle3D {
  let t = self.inner.get_triangle(id)
  Triangle3D::new(
    t.p0_x,
    t.p0_y,
    t.p0_z,
    t.p1_x,
    t.p1_y,
    t.p1_z,
    t.p2_x,
    t.p2_y,
    t.p2_z,
  )
}

///|
/// Queries triangle candidates intersecting a 3D bounding box.
pub fn StrMeshTree3D::query_box(
  self : StrMeshTree3D,
  search_box : Box3D,
) -> Array[Int] {
  self.inner.query_box(search_box)
}

///|
/// Queries mesh triangles that precisely intersect a 3D line segment.
pub fn StrMeshTree3D::query_segment(
  self : StrMeshTree3D,
  x1 : Double,
  y1 : Double,
  z1 : Double,
  x2 : Double,
  y2 : Double,
  z2 : Double,
) -> Array[Int] {
  self.inner.query_segment(x1, y1, z1, x2, y2, z2)
}

///|
/// Traces a ray and returns the closest intersecting triangle ID and distance t, or None if missed.
pub fn StrMeshTree3D::query_first_ray_hit(
  self : StrMeshTree3D,
  ox : Double,
  oy : Double,
  oz : Double,
  dx : Double,
  dy : Double,
  dz : Double,
  max_distance? : Double = 1000000.0,
) -> (Int, Double)? {
  self.inner.query_first_ray_hit(ox, oy, oz, dx, dy, dz, max_distance~)
}

///|
/// Traces a ray and returns all intersecting triangle IDs and hit distances t, sorted by distance ascending.
pub fn StrMeshTree3D::query_all_ray_hits(
  self : StrMeshTree3D,
  ox : Double,
  oy : Double,
  oz : Double,
  dx : Double,
  dy : Double,
  dz : Double,
  max_distance? : Double = 1000000.0,
) -> Array[(Int, Double)] {
  self.inner.query_all_ray_hits(ox, oy, oz, dx, dy, dz, max_distance~)
}
