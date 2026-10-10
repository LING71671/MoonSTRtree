///|
/// Axis-Aligned Bounding Box (AABB) in continuous 2D space.
pub struct Rect {
  min_x : Double
  min_y : Double
  max_x : Double
  max_y : Double
} derive(Eq, Debug, Default)

///|
/// Converts to internal geometry primitive.
fn Rect::to_geometry(self : Rect) -> @geometry.Rect {
  @geometry.Rect::new(self.min_x, self.min_y, self.max_x, self.max_y)
}

///|
/// Constructs a new normalized Rect where min_x <= max_x and min_y <= max_y.
pub fn Rect::new(
  min_x : Double,
  min_y : Double,
  max_x : Double,
  max_y : Double,
) -> Rect {
  let g = @geometry.Rect::new(min_x, min_y, max_x, max_y)
  Rect::{ min_x: g.min_x, min_y: g.min_y, max_x: g.max_x, max_y: g.max_y, }
}

///|
/// Constructs a degenerate zero-area rectangle centered at (x, y).
pub fn Rect::from_point(x : Double, y : Double) -> Rect {
  let g = @geometry.Rect::from_point(x, y)
  Rect::{ min_x: g.min_x, min_y: g.min_y, max_x: g.max_x, max_y: g.max_y, }
}

///|
/// Returns true if this rectangle intersects or touches another rectangle.
pub fn Rect::intersects(self : Rect, other : Rect) -> Bool {
  self.to_geometry().intersects(other.to_geometry())
}

///|
/// Returns true if point (x, y) is contained within this rectangle.
pub fn Rect::contains_point(self : Rect, x : Double, y : Double) -> Bool {
  self.to_geometry().contains_point(x, y)
}

///|
/// Returns true if this rectangle completely contains another rectangle.
pub fn Rect::contains_rect(self : Rect, other : Rect) -> Bool {
  self.to_geometry().contains_rect(other.to_geometry())
}

///|
/// Returns the Minimum Bounding Rectangle (MBR) enclosing both rectangles.
pub fn Rect::union(self : Rect, other : Rect) -> Rect {
  let u = self.to_geometry().union(other.to_geometry())
  Rect::{ min_x: u.min_x, min_y: u.min_y, max_x: u.max_x, max_y: u.max_y, }
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
  self.to_geometry().intersects_segment(x1, y1, x2, y2)
}

///|
/// Returns true if this rectangle intersects or touches a circle centered at (cx, cy) with given radius.
pub fn Rect::intersects_circle(
  self : Rect,
  cx : Double,
  cy : Double,
  radius : Double,
) -> Bool {
  self.to_geometry().intersects_circle(cx, cy, radius)
}

///|
/// Computes the intersection rectangle of two rectangles.
/// Returns None if the rectangles do not intersect.
pub fn Rect::intersection(self : Rect, other : Rect) -> Rect? {
  match self.to_geometry().intersection(other.to_geometry()) {
    None => None
    Some(g) =>
      Some(Rect::{
        min_x: g.min_x,
        min_y: g.min_y,
        max_x: g.max_x,
        max_y: g.max_y,
      })
  }
}

///|
/// Returns a new rectangle expanded uniformly by delta on all 4 sides.
pub fn Rect::expand(self : Rect, delta : Double) -> Rect {
  let g = self.to_geometry().expand(delta)
  Rect::{ min_x: g.min_x, min_y: g.min_y, max_x: g.max_x, max_y: g.max_y, }
}

///|
/// Computes minimum squared Euclidean distance between two rectangles.
/// Returns 0.0 if the rectangles intersect.
pub fn Rect::distance_squared_to_rect(self : Rect, other : Rect) -> Double {
  self.to_geometry().distance_squared_to_rect(other.to_geometry())
}

///|
/// Computes minimum Euclidean distance between two rectangles.
pub fn Rect::distance_to_rect(self : Rect, other : Rect) -> Double {
  self.to_geometry().distance_to_rect(other.to_geometry())
}

///|
/// Computes Intersection over Union (IoU) metric in [0.0, 1.0].
pub fn Rect::iou(self : Rect, other : Rect) -> Double {
  self.to_geometry().iou(other.to_geometry())
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
/// Converts to internal geometry primitive.
fn Box3D::to_geometry(self : Box3D) -> @geometry.Box3D {
  @geometry.Box3D::new(
    self.min_x,
    self.min_y,
    self.min_z,
    self.max_x,
    self.max_y,
    self.max_z,
  )
}

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
  let g = @geometry.Box3D::new(min_x, min_y, min_z, max_x, max_y, max_z)
  Box3D::{
    min_x: g.min_x,
    min_y: g.min_y,
    min_z: g.min_z,
    max_x: g.max_x,
    max_y: g.max_y,
    max_z: g.max_z,
  }
}

///|
/// Constructs a degenerate zero-volume box centered at (x, y, z).
pub fn Box3D::from_point(x : Double, y : Double, z : Double) -> Box3D {
  let g = @geometry.Box3D::from_point(x, y, z)
  Box3D::{
    min_x: g.min_x,
    min_y: g.min_y,
    min_z: g.min_z,
    max_x: g.max_x,
    max_y: g.max_y,
    max_z: g.max_z,
  }
}

///|
/// Returns true if this box intersects or touches another 3D box.
pub fn Box3D::intersects(self : Box3D, other : Box3D) -> Bool {
  self.to_geometry().intersects(other.to_geometry())
}

///|
/// Returns true if point (x, y, z) is contained within or on the boundaries of this 3D box.
pub fn Box3D::contains_point(
  self : Box3D,
  x : Double,
  y : Double,
  z : Double,
) -> Bool {
  self.to_geometry().contains_point(x, y, z)
}

///|
/// Returns true if this box completely encloses another 3D box.
pub fn Box3D::contains_box(self : Box3D, other : Box3D) -> Bool {
  self.to_geometry().contains_box(other.to_geometry())
}

///|
/// Returns the Minimum Bounding Box (MBB) enclosing both 3D boxes.
pub fn Box3D::union(self : Box3D, other : Box3D) -> Box3D {
  let u = self.to_geometry().union(other.to_geometry())
  Box3D::{
    min_x: u.min_x,
    min_y: u.min_y,
    min_z: u.min_z,
    max_x: u.max_x,
    max_y: u.max_y,
    max_z: u.max_z,
  }
}

///|
/// Computes the intersection 3D box of two boxes, or None if disjoint.
pub fn Box3D::intersection(self : Box3D, other : Box3D) -> Box3D? {
  match self.to_geometry().intersection(other.to_geometry()) {
    None => None
    Some(g) =>
      Some(Box3D::{
        min_x: g.min_x,
        min_y: g.min_y,
        min_z: g.min_z,
        max_x: g.max_x,
        max_y: g.max_y,
        max_z: g.max_z,
      })
  }
}

///|
/// Computes the volume of this 3D box.
pub fn Box3D::volume(self : Box3D) -> Double {
  self.to_geometry().volume()
}

///|
/// Computes total surface area of this 3D box.
pub fn Box3D::surface_area(self : Box3D) -> Double {
  self.to_geometry().surface_area()
}

///|
/// Center X coordinate.
pub fn Box3D::center_x(self : Box3D) -> Double {
  self.to_geometry().center_x()
}

///|
/// Center Y coordinate.
pub fn Box3D::center_y(self : Box3D) -> Double {
  self.to_geometry().center_y()
}

///|
/// Center Z coordinate.
pub fn Box3D::center_z(self : Box3D) -> Double {
  self.to_geometry().center_z()
}

///|
/// Returns a new 3D box expanded uniformly by delta along all 6 faces.
pub fn Box3D::expand(self : Box3D, delta : Double) -> Box3D {
  let g = self.to_geometry().expand(delta)
  Box3D::{
    min_x: g.min_x,
    min_y: g.min_y,
    min_z: g.min_z,
    max_x: g.max_x,
    max_y: g.max_y,
    max_z: g.max_z,
  }
}

///|
/// Computes squared Euclidean distance from this 3D box to point (x, y, z).
pub fn Box3D::distance_squared_to_point(
  self : Box3D,
  x : Double,
  y : Double,
  z : Double,
) -> Double {
  self.to_geometry().distance_squared_to_point(x, y, z)
}

///|
/// Comprehensive structural and memory diagnostics for a packed StrTree.
pub struct TreeStats {
  num_items : Int
  num_nodes : Int
  height : Int
  node_capacity : Int
  fill_factor : Double
  leaf_nodes : Int
  branch_nodes : Int
  total_edges : Int
  estimated_memory_bytes : Int
} derive(Eq, Debug, Default)

///|
/// Packed 2D spatial index tree with contiguous flat array storage.
pub struct StrTree {
  inner : @tree.StrTree
} derive(Eq, Debug, Default)

///|
/// Builds a packed StrTree from an array of (Rect, ID) pairs and optional node capacity.
pub fn StrTree::build(
  items : Array[(Rect, Int)],
  node_capacity? : Int = 16,
) -> StrTree {
  let g_items : Array[(@geometry.Rect, Int)] = []
  for i = 0; i < items.length(); i = i + 1 {
    let (r, id) = items[i]
    g_items.push((r.to_geometry(), id))
  }
  let inner = @tree.StrTree::build(g_items, node_capacity~)
  StrTree::{ inner, }
}

///|
/// Performs axis-aligned bounding box range intersection query using iterative stack DFS.
pub fn StrTree::query(self : StrTree, search_window : Rect) -> Array[Int] {
  self.inner.query(search_window.to_geometry())
}

///|
/// Performs point inclusion query using iterative stack DFS.
pub fn StrTree::query_point(
  self : StrTree,
  x : Double,
  y : Double,
) -> Array[Int] {
  self.inner.query_point(x, y)
}

///|
/// Performs axis-aligned bounding box range intersection counting with zero result allocation.
pub fn StrTree::query_count(self : StrTree, search_window : Rect) -> Int {
  self.inner.query_count(search_window.to_geometry())
}

///|
/// Performs point inclusion counting with zero heap allocation.
pub fn StrTree::query_point_count(
  self : StrTree,
  x : Double,
  y : Double,
) -> Int {
  self.inner.query_point_count(x, y)
}

///|
/// Returns the first item ID intersecting search_window that satisfies the predicate, or None.
pub fn StrTree::query_first(
  self : StrTree,
  search_window : Rect,
  predicate : (Int) -> Bool,
) -> Int? {
  self.inner.query_first(search_window.to_geometry(), predicate)
}

///|
/// Performs axis-aligned bounding box range intersection query with filter predicate.
pub fn StrTree::query_with_predicate(
  self : StrTree,
  search_window : Rect,
  predicate : (Int) -> Bool,
) -> Array[Int] {
  self.inner.query_with_predicate(search_window.to_geometry(), predicate)
}

///|
/// Performs branch-and-bound k-Nearest Neighbor (k-NN) search.
/// Returns at most k item IDs sorted by ascending Euclidean distance to (x, y).
pub fn StrTree::query_knn(
  self : StrTree,
  x : Double,
  y : Double,
  k : Int,
) -> Array[Int] {
  self.inner.query_knn(x, y, k)
}

///|
/// Performs branch-and-bound k-Nearest Neighbor (k-NN) search.
/// Returns at most k pairs (item_id, squared_distance) sorted by ascending Euclidean distance to (x, y).
pub fn StrTree::query_knn_with_distance(
  self : StrTree,
  x : Double,
  y : Double,
  k : Int,
) -> Array[(Int, Double)] {
  self.inner.query_knn_with_distance(x, y, k)
}

///|
/// Performs line segment / ray intersection query using iterative stack DFS.
/// Returns item IDs of all indexed elements whose bounding boxes intersect the segment (x1, y1) -> (x2, y2).
pub fn StrTree::query_segment(
  self : StrTree,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> Array[Int] {
  self.inner.query_segment(x1, y1, x2, y2)
}

///|
/// Performs circular / radius range query using iterative stack DFS.
/// Returns item IDs of all indexed elements whose bounding boxes intersect the circle.
pub fn StrTree::query_circle(
  self : StrTree,
  cx : Double,
  cy : Double,
  radius : Double,
) -> Array[Int] {
  self.inner.query_circle(cx, cy, radius)
}

///|
/// Performs circular / radius range counting with zero result allocation.
pub fn StrTree::query_circle_count(
  self : StrTree,
  cx : Double,
  cy : Double,
  radius : Double,
) -> Int {
  self.inner.query_circle_count(cx, cy, radius)
}

///|
/// Performs dual-tree hierarchical spatial join between two StrTree indexes.
/// Returns all pairs of item IDs (id_a, id_b) whose bounding boxes intersect.
pub fn StrTree::spatial_join(
  self : StrTree,
  other : StrTree,
) -> Array[(Int, Int)] {
  self.inner.spatial_join(other.inner)
}

///|
/// Raw contiguous array buffers of a packed StrTree for persistence and zero-copy transfer.
pub struct FlatBuffers {
  inner : @tree.FlatBuffers
} derive(Eq, Debug, Default)

///|
/// Exports raw contiguous array buffers for serialization.
pub fn StrTree::to_flat_buffers(self : StrTree) -> FlatBuffers {
  FlatBuffers::{ inner: self.inner.to_flat_buffers(), }
}

///|
/// Reconstructs a StrTree directly from raw contiguous array buffers.
pub fn StrTree::from_flat_buffers(buffers : FlatBuffers) -> StrTree {
  StrTree::{ inner: @tree.StrTree::from_flat_buffers(buffers.inner), }
}

///|
/// Computes structural diagnostic metrics from a StrTree.
pub fn StrTree::stats(self : StrTree) -> TreeStats {
  let s = @stats.TreeStats::compute(self.inner)
  TreeStats::{
    num_items: s.num_items,
    num_nodes: s.num_nodes,
    height: s.height,
    node_capacity: s.node_capacity,
    fill_factor: s.fill_factor,
    leaf_nodes: s.leaf_nodes,
    branch_nodes: s.branch_nodes,
    total_edges: s.total_edges,
    estimated_memory_bytes: s.estimated_memory_bytes,
  }
}

///|
/// Deterministic Linear Congruential Generator.
pub struct Rng {
  inner : @generator.Rng
} derive(Eq, Debug, Default)

///|
/// Constructs an Rng with initial seed.
pub fn Rng::new(seed : Int) -> Rng {
  Rng::{ inner: @generator.Rng::new(seed), }
}

///|
/// Generates uniform randomly distributed bounding boxes.
pub fn generate_uniform(
  rng : Rng,
  count : Int,
  domain_width? : Double = 1000.0,
  domain_height? : Double = 1000.0,
  max_box_size? : Double = 20.0,
) -> Array[(Rect, Int)] {
  let g = @generator.generate_uniform(
    rng.inner,
    count,
    domain_width~,
    domain_height~,
    max_box_size~,
  )
  let result : Array[(Rect, Int)] = []
  for i = 0; i < g.length(); i = i + 1 {
    let (r, id) = g[i]
    result.push((Rect::new(r.min_x, r.min_y, r.max_x, r.max_y), id))
  }
  result
}

///|
/// Generates clustered Gaussian distributed bounding boxes.
pub fn generate_clustered(
  rng : Rng,
  count : Int,
  num_clusters? : Int = 5,
  domain_width? : Double = 1000.0,
  domain_height? : Double = 1000.0,
) -> Array[(Rect, Int)] {
  let g = @generator.generate_clustered(
    rng.inner,
    count,
    num_clusters~,
    domain_width~,
    domain_height~,
  )
  let result : Array[(Rect, Int)] = []
  for i = 0; i < g.length(); i = i + 1 {
    let (r, id) = g[i]
    result.push((Rect::new(r.min_x, r.min_y, r.max_x, r.max_y), id))
  }
  result
}

///|
/// Generates diagonal collinear bounding boxes.
pub fn generate_diagonal(
  rng : Rng,
  count : Int,
  domain_size? : Double = 1000.0,
) -> Array[(Rect, Int)] {
  let g = @generator.generate_diagonal(rng.inner, count, domain_size~)
  let result : Array[(Rect, Int)] = []
  for i = 0; i < g.length(); i = i + 1 {
    let (r, id) = g[i]
    result.push((Rect::new(r.min_x, r.min_y, r.max_x, r.max_y), id))
  }
  result
}

///|
/// Generates concentric nested bounding boxes.
pub fn generate_concentric(
  count : Int,
  center_x? : Double = 500.0,
  center_y? : Double = 500.0,
  step? : Double = 2.0,
) -> Array[(Rect, Int)] {
  let g = @generator.generate_concentric(count, center_x~, center_y~, step~)
  let result : Array[(Rect, Int)] = []
  for i = 0; i < g.length(); i = i + 1 {
    let (r, id) = g[i]
    result.push((Rect::new(r.min_x, r.min_y, r.max_x, r.max_y), id))
  }
  result
}

///|
/// Generates regularly spaced grid tiles.
pub fn generate_grid(
  rows : Int,
  cols : Int,
  cell_size? : Double = 10.0,
  spacing? : Double = 2.0,
) -> Array[(Rect, Int)] {
  let g = @generator.generate_grid(rows, cols, cell_size~, spacing~)
  let result : Array[(Rect, Int)] = []
  for i = 0; i < g.length(); i = i + 1 {
    let (r, id) = g[i]
    result.push((Rect::new(r.min_x, r.min_y, r.max_x, r.max_y), id))
  }
  result
}
