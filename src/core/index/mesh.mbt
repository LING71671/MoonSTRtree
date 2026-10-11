///|
/// Packed 3D spatial index for polygonal triangle meshes with accelerated ray-tracing and segment intersection.
pub struct StrMeshTree3D {
  triangles : Array[@geometry.Triangle3D]
  tree : StrTree3D
} derive(Eq, Debug, Default)

///|
/// Builds a packed 3D mesh index from an array of Triangle3D primitives.
pub fn StrMeshTree3D::build(
  triangles : Array[@geometry.Triangle3D],
  node_capacity? : Int = 16,
) -> StrMeshTree3D {
  let items : Array[(@geometry.Box3D, Int)] = []
  for i = 0; i < triangles.length(); i = i + 1 {
    items.push((triangles[i].to_box(), i))
  }
  let tree = StrTree3D::build(items, node_capacity~)
  StrMeshTree3D::{ triangles: triangles.copy(), tree, }
}

///|
/// Returns total number of indexed mesh triangles.
pub fn StrMeshTree3D::num_triangles(self : StrMeshTree3D) -> Int {
  self.triangles.length()
}

///|
/// Retrieves triangle primitive by index.
pub fn StrMeshTree3D::get_triangle(
  self : StrMeshTree3D,
  id : Int,
) -> @geometry.Triangle3D {
  self.triangles[id]
}

///|
/// Queries triangle candidates intersecting a 3D bounding box.
pub fn StrMeshTree3D::query_box(
  self : StrMeshTree3D,
  search_box : @geometry.Box3D,
) -> Array[Int] {
  self.tree.query(search_box)
}

///|
/// Queries mesh triangles that precisely intersect a 3D line segment (x1, y1, z1) -> (x2, y2, z2).
pub fn StrMeshTree3D::query_segment(
  self : StrMeshTree3D,
  x1 : Double,
  y1 : Double,
  z1 : Double,
  x2 : Double,
  y2 : Double,
  z2 : Double,
) -> Array[Int] {
  let candidates = self.tree.query_segment(x1, y1, z1, x2, y2, z2)
  let results : Array[Int] = []
  for i = 0; i < candidates.length(); i = i + 1 {
    let id = candidates[i]
    if self.triangles[id].intersects_segment(x1, y1, z1, x2, y2, z2) {
      results.push(id)
    }
  }
  results
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
  let target_x = ox + dx * max_distance
  let target_y = oy + dy * max_distance
  let target_z = oz + dz * max_distance
  let candidates = self.tree.query_segment(
    ox, oy, oz, target_x, target_y, target_z,
  )

  let mut closest_id : Int? = None
  let mut min_t = max_distance

  for i = 0; i < candidates.length(); i = i + 1 {
    let id = candidates[i]
    let tri = self.triangles[id]
    match tri.ray_intersection(ox, oy, oz, dx, dy, dz) {
      Some(t) =>
        if t <= min_t {
          min_t = t
          closest_id = Some(id)
        }
      None => ()
    }
  }

  match closest_id {
    Some(id) => Some((id, min_t))
    None => None
  }
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
  let target_x = ox + dx * max_distance
  let target_y = oy + dy * max_distance
  let target_z = oz + dz * max_distance
  let candidates = self.tree.query_segment(
    ox, oy, oz, target_x, target_y, target_z,
  )

  let hits : Array[(Int, Double)] = []
  for i = 0; i < candidates.length(); i = i + 1 {
    let id = candidates[i]
    let tri = self.triangles[id]
    match tri.ray_intersection(ox, oy, oz, dx, dy, dz) {
      Some(t) => if t <= max_distance { hits.push((id, t)) }
      None => ()
    }
  }

  for i = 0; i < hits.length(); i = i + 1 {
    for j = i + 1; j < hits.length(); j = j + 1 {
      let (_, t_i) = hits[i]
      let (_, t_j) = hits[j]
      if t_j < t_i {
        let tmp = hits[i]
        hits[i] = hits[j]
        hits[j] = tmp
      }
    }
  }

  hits
}
