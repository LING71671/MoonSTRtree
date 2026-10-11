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
/// Converts to internal geometry spatial predicate.
fn SpatialPredicate::to_geometry(
  self : SpatialPredicate,
) -> @geometry.SpatialPredicate {
  match self {
    Intersects => @geometry.SpatialPredicate::Intersects
    Contains => @geometry.SpatialPredicate::Contains
    Within => @geometry.SpatialPredicate::Within
    Touches => @geometry.SpatialPredicate::Touches
    Overlaps => @geometry.SpatialPredicate::Overlaps
    Disjoint => @geometry.SpatialPredicate::Disjoint
    Equals => @geometry.SpatialPredicate::Equals
    Covers => @geometry.SpatialPredicate::Covers
    CoveredBy => @geometry.SpatialPredicate::CoveredBy
  }
}

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
/// Returns true if this rectangle touches another rectangle.
pub fn Rect::touches(self : Rect, other : Rect) -> Bool {
  self.to_geometry().touches(other.to_geometry())
}

///|
/// Returns true if this rectangle topologically covers another rectangle.
pub fn Rect::covers(self : Rect, other : Rect) -> Bool {
  self.to_geometry().covers(other.to_geometry())
}

///|
/// Returns true if this rectangle is topologically covered by another rectangle.
pub fn Rect::covered_by(self : Rect, other : Rect) -> Bool {
  self.to_geometry().covered_by(other.to_geometry())
}

///|
/// Returns true if this rectangle contains another rectangle with non-empty interior intersection.
pub fn Rect::contains(self : Rect, other : Rect) -> Bool {
  self.to_geometry().contains(other.to_geometry())
}

///|
/// Returns true if this rectangle is within another rectangle.
pub fn Rect::within(self : Rect, other : Rect) -> Bool {
  self.to_geometry().within(other.to_geometry())
}

///|
/// Returns true if two rectangles have identical boundaries.
pub fn Rect::equals_exact(self : Rect, other : Rect) -> Bool {
  self.to_geometry().equals_exact(other.to_geometry())
}

///|
/// Returns true if two rectangles are completely disjoint (no common points).
pub fn Rect::disjoint(self : Rect, other : Rect) -> Bool {
  self.to_geometry().disjoint(other.to_geometry())
}

///|
/// Returns true if two rectangles overlap.
pub fn Rect::overlaps(self : Rect, other : Rect) -> Bool {
  self.to_geometry().overlaps(other.to_geometry())
}

///|
/// Evaluates a named spatial predicate between two rectangles.
pub fn Rect::evaluate_predicate(
  self : Rect,
  other : Rect,
  predicate : SpatialPredicate,
) -> Bool {
  self
  .to_geometry()
  .evaluate_predicate(other.to_geometry(), predicate.to_geometry())
}

///|
/// Computes the Dimensionally Extended 9-Intersection Model (DE-9IM) matrix string.
pub fn Rect::relate(self : Rect, other : Rect) -> String {
  self.to_geometry().relate(other.to_geometry())
}

///|
/// Checks whether a 9-character DE-9IM intersection matrix matches an intersection pattern.
pub fn matches_de9im_pattern(matrix : String, pattern : String) -> Bool {
  @geometry.matches_de9im_pattern(matrix, pattern)
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
/// Computes minimum Euclidean distance between this 3D box and another 3D box.
/// Returns 0.0 if boxes intersect or touch.
pub fn Box3D::distance_to_box(self : Box3D, other : Box3D) -> Double {
  self.to_geometry().distance_to_box(other.to_geometry())
}

///|
/// Computes volumetric Intersection over Union (IoU) of two 3D boxes in [0.0, 1.0].
pub fn Box3D::iou(self : Box3D, other : Box3D) -> Double {
  self.to_geometry().iou(other.to_geometry())
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
  self.to_geometry().intersects_sphere(cx, cy, cz, radius)
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
  self.to_geometry().intersects_segment(x1, y1, z1, x2, y2, z2)
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
/// Returns the bounding envelope enclosing the root node of the tree.
pub fn StrTree::envelope(self : StrTree) -> Rect {
  let r = self.inner.envelope()
  Rect::new(r.min_x, r.min_y, r.max_x, r.max_y)
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
/// Performs branch-and-bound k-Nearest Neighbor (k-NN) search filtered by user predicate.
/// Returns at most k item IDs satisfying predicate(id), sorted by ascending Euclidean distance to (x, y).
pub fn StrTree::query_knn_with_predicate(
  self : StrTree,
  x : Double,
  y : Double,
  k : Int,
  predicate : (Int) -> Bool,
) -> Array[Int] {
  self.inner.query_knn_with_predicate(x, y, k, predicate)
}

///|
/// Performs branch-and-bound k-Nearest Neighbor (k-NN) search filtered by user predicate.
/// Returns at most k pairs (item_id, squared_distance) satisfying predicate(id), sorted by ascending Euclidean distance to (x, y).
pub fn StrTree::query_knn_with_predicate_and_distance(
  self : StrTree,
  x : Double,
  y : Double,
  k : Int,
  predicate : (Int) -> Bool,
) -> Array[(Int, Double)] {
  self.inner.query_knn_with_predicate_and_distance(x, y, k, predicate)
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
/// Queries the spatial index using a named DE-9IM topological predicate.
pub fn StrTree::query_spatial_predicate(
  self : StrTree,
  rect : Rect,
  predicate : SpatialPredicate,
) -> Array[Int] {
  self.inner.query_spatial_predicate(
    rect.to_geometry(),
    predicate.to_geometry(),
  )
}

///|
/// Performs hierarchical spatial join between two trees filtering by a named topological predicate.
pub fn StrTree::spatial_join_predicate(
  self : StrTree,
  other : StrTree,
  predicate : SpatialPredicate,
) -> Array[(Int, Int)] {
  self.inner.spatial_join_predicate(other.inner, predicate.to_geometry())
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

///|
/// Diagnostic statistics for a packed 3D StrTree.
pub struct TreeStats3D {
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
/// Packed 3D spatial index tree with contiguous flat array storage.
pub struct StrTree3D {
  inner : @tree.StrTree3D
} derive(Eq, Debug, Default)

///|
/// Builds a packed 3D StrTree from an array of (Box3D, ID) pairs and optional node capacity.
pub fn StrTree3D::build(
  items : Array[(Box3D, Int)],
  node_capacity? : Int = 16,
) -> StrTree3D {
  let g_items : Array[(@geometry.Box3D, Int)] = []
  for i = 0; i < items.length(); i = i + 1 {
    let (b, id) = items[i]
    g_items.push((b.to_geometry(), id))
  }
  let inner = @tree.StrTree3D::build(g_items, node_capacity~)
  StrTree3D::{ inner, }
}

///|
/// Performs 3D range query using iterative stack DFS traversal.
pub fn StrTree3D::query(self : StrTree3D, search_box : Box3D) -> Array[Int] {
  self.inner.query(search_box.to_geometry())
}

///|
/// Performs zero-allocation count of items intersecting a 3D search box.
pub fn StrTree3D::query_count(self : StrTree3D, search_box : Box3D) -> Int {
  self.inner.query_count(search_box.to_geometry())
}

///|
/// Performs 3D point containment query.
pub fn StrTree3D::query_point(
  self : StrTree3D,
  x : Double,
  y : Double,
  z : Double,
) -> Array[Int] {
  self.inner.query_point(x, y, z)
}

///|
/// Performs 3D sphere range intersection query.
pub fn StrTree3D::query_sphere(
  self : StrTree3D,
  cx : Double,
  cy : Double,
  cz : Double,
  radius : Double,
) -> Array[Int] {
  self.inner.query_sphere(cx, cy, cz, radius)
}

///|
/// Performs branch-and-bound k-Nearest Neighbor (k-NN) search in 3D Euclidean space.
pub fn StrTree3D::query_knn(
  self : StrTree3D,
  x : Double,
  y : Double,
  z : Double,
  k : Int,
) -> Array[Int] {
  self.inner.query_knn(x, y, z, k)
}

///|
/// Performs branch-and-bound 3D k-NN search returning pairs of (item_id, squared_distance).
pub fn StrTree3D::query_knn_with_distance(
  self : StrTree3D,
  x : Double,
  y : Double,
  z : Double,
  k : Int,
) -> Array[(Int, Double)] {
  self.inner.query_knn_with_distance(x, y, z, k)
}

///|
/// Performs branch-and-bound 3D k-NN search filtered by a user predicate closure.
pub fn StrTree3D::query_knn_with_predicate(
  self : StrTree3D,
  x : Double,
  y : Double,
  z : Double,
  k : Int,
  predicate : (Int) -> Bool,
) -> Array[Int] {
  self.inner.query_knn_with_predicate(x, y, z, k, predicate)
}

///|
/// Performs branch-and-bound 3D k-NN search with predicate and distance pairs.
pub fn StrTree3D::query_knn_with_predicate_and_distance(
  self : StrTree3D,
  x : Double,
  y : Double,
  z : Double,
  k : Int,
  predicate : (Int) -> Bool,
) -> Array[(Int, Double)] {
  self.inner.query_knn_with_predicate_and_distance(x, y, z, k, predicate)
}

///|
/// Performs 3D line segment / ray intersection query using iterative stack DFS.
pub fn StrTree3D::query_segment(
  self : StrTree3D,
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
/// Performs zero-allocation count of items containing point (x, y, z).
pub fn StrTree3D::query_point_count(
  self : StrTree3D,
  x : Double,
  y : Double,
  z : Double,
) -> Int {
  self.inner.query_point_count(x, y, z)
}

///|
/// Performs zero-allocation count of items intersecting a sphere.
pub fn StrTree3D::query_sphere_count(
  self : StrTree3D,
  cx : Double,
  cy : Double,
  cz : Double,
  radius : Double,
) -> Int {
  self.inner.query_sphere_count(cx, cy, cz, radius)
}

///|
/// Computes structural diagnostic metrics for 3D StrTree.
pub fn StrTree3D::stats(self : StrTree3D) -> TreeStats3D {
  let s = self.inner.stats()
  TreeStats3D::{
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
/// Performs dual-tree hierarchical spatial join between two StrTree3D indexes.
pub fn StrTree3D::spatial_join(
  self : StrTree3D,
  other : StrTree3D,
) -> Array[(Int, Int)] {
  self.inner.spatial_join(other.inner)
}

///|
/// Performs 3D range intersection query returning first matching item ID satisfying predicate.
pub fn StrTree3D::query_first(
  self : StrTree3D,
  search_box : Box3D,
  predicate : (Int) -> Bool,
) -> Int? {
  self.inner.query_first(search_box.to_geometry(), predicate)
}

///|
/// Performs 3D range intersection query with filter predicate.
pub fn StrTree3D::query_with_predicate(
  self : StrTree3D,
  search_box : Box3D,
  predicate : (Int) -> Bool,
) -> Array[Int] {
  self.inner.query_with_predicate(search_box.to_geometry(), predicate)
}

///|
/// Raw contiguous array buffers of a packed StrTree3D for persistence and zero-copy transfer.
pub struct FlatBuffers3D {
  inner : @tree.FlatBuffers3D
} derive(Eq, Debug, Default)

///|
/// Exports raw contiguous array buffers from StrTree3D.
pub fn StrTree3D::to_flat_buffers(self : StrTree3D) -> FlatBuffers3D {
  FlatBuffers3D::{ inner: self.inner.to_flat_buffers(), }
}

///|
/// Reconstructs a StrTree3D directly from raw contiguous array buffers.
pub fn StrTree3D::from_flat_buffers(buffers : FlatBuffers3D) -> StrTree3D {
  StrTree3D::{ inner: @tree.StrTree3D::from_flat_buffers(buffers.inner), }
}

///|
/// Generates uniform randomly distributed 3D bounding boxes.
pub fn generate_boxes_3d_uniform(
  rng : Rng,
  count : Int,
  domain_x? : Double = 1000.0,
  domain_y? : Double = 1000.0,
  domain_z? : Double = 1000.0,
  max_box_size? : Double = 20.0,
) -> Array[(Box3D, Int)] {
  let g = @generator.generate_boxes_3d_uniform(
    rng.inner,
    count,
    domain_x~,
    domain_y~,
    domain_z~,
    max_box_size~,
  )
  let result : Array[(Box3D, Int)] = []
  for i = 0; i < g.length(); i = i + 1 {
    let (b, id) = g[i]
    result.push(
      (Box3D::new(b.min_x, b.min_y, b.min_z, b.max_x, b.max_y, b.max_z), id),
    )
  }
  result
}

///|
/// Generates clustered Gaussian distributed 3D bounding boxes.
pub fn generate_boxes_3d_clustered(
  rng : Rng,
  count : Int,
  num_clusters? : Int = 4,
  domain_x? : Double = 1000.0,
  domain_y? : Double = 1000.0,
  domain_z? : Double = 1000.0,
) -> Array[(Box3D, Int)] {
  let g = @generator.generate_boxes_3d_clustered(
    rng.inner,
    count,
    num_clusters~,
    domain_x~,
    domain_y~,
    domain_z~,
  )
  let result : Array[(Box3D, Int)] = []
  for i = 0; i < g.length(); i = i + 1 {
    let (b, id) = g[i]
    result.push(
      (Box3D::new(b.min_x, b.min_y, b.min_z, b.max_x, b.max_y, b.max_z), id),
    )
  }
  result
}

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
  inner : @tree.StrMeshTree3D
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
  self.inner.query_box(search_box.to_geometry())
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
/// Converts to internal geometry primitive.
fn Box4D::to_geometry(self : Box4D) -> @geometry.Box4D {
  @geometry.Box4D::new(
    self.min_x,
    self.min_y,
    self.min_z,
    self.min_t,
    self.max_x,
    self.max_y,
    self.max_z,
    self.max_t,
  )
}

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
  let g = @geometry.Box4D::new(
    min_x, min_y, min_z, min_t, max_x, max_y, max_z, max_t,
  )
  Box4D::{
    min_x: g.min_x,
    min_y: g.min_y,
    min_z: g.min_z,
    min_t: g.min_t,
    max_x: g.max_x,
    max_y: g.max_y,
    max_z: g.max_z,
    max_t: g.max_t,
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
  self.to_geometry().intersects(other.to_geometry())
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
  self.to_geometry().contains_point(x, y, z, t)
}

///|
/// Returns true if this box completely contains another 4D box.
pub fn Box4D::contains_box(self : Box4D, other : Box4D) -> Bool {
  self.to_geometry().contains_box(other.to_geometry())
}

///|
/// Computes the Minimum Bounding Hypervolume enclosing both 4D boxes.
pub fn Box4D::union(self : Box4D, other : Box4D) -> Box4D {
  let u = self.to_geometry().union(other.to_geometry())
  Box4D::new(
    u.min_x,
    u.min_y,
    u.min_z,
    u.min_t,
    u.max_x,
    u.max_y,
    u.max_z,
    u.max_t,
  )
}

///|
/// Computes intersection of two 4D boxes, or None if disjoint.
pub fn Box4D::intersection(self : Box4D, other : Box4D) -> Box4D? {
  match self.to_geometry().intersection(other.to_geometry()) {
    Some(i) =>
      Some(
        Box4D::new(
          i.min_x,
          i.min_y,
          i.min_z,
          i.min_t,
          i.max_x,
          i.max_y,
          i.max_z,
          i.max_t,
        ),
      )
    None => None
  }
}

///|
/// Computes the 4D hypervolume.
pub fn Box4D::hyper_volume(self : Box4D) -> Double {
  self.to_geometry().hyper_volume()
}

///|
/// Extracts the spatial 3D bounding box (Box3D) ignoring time dimension.
pub fn Box4D::to_box3d(self : Box4D) -> Box3D {
  let b = self.to_geometry().to_box3d()
  Box3D::new(b.min_x, b.min_y, b.min_z, b.max_x, b.max_y, b.max_z)
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
  let e = self.to_geometry().expand(dx, dy, dz, dt)
  Box4D::new(
    e.min_x,
    e.min_y,
    e.min_z,
    e.min_t,
    e.max_x,
    e.max_y,
    e.max_z,
    e.max_t,
  )
}

///|
/// Checks if this 4D box intersects another at a specific instant of time t.
pub fn Box4D::intersects_at_time(
  self : Box4D,
  other : Box4D,
  t : Double,
) -> Bool {
  self.to_geometry().intersects_at_time(other.to_geometry(), t)
}

///|
/// Diagnostic statistics for a packed 4D StrTree.
pub struct TreeStats4D {
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
/// Packed 4D spatiotemporal index tree with contiguous flat array storage.
pub struct StrTree4D {
  inner : @tree.StrTree4D
} derive(Eq, Debug, Default)

///|
/// Builds a packed 4D StrTree from an array of (Box4D, ID) pairs and optional node capacity.
pub fn StrTree4D::build(
  items : Array[(Box4D, Int)],
  node_capacity? : Int = 16,
) -> StrTree4D {
  let g_items : Array[(@geometry.Box4D, Int)] = []
  for i = 0; i < items.length(); i = i + 1 {
    let (b, id) = items[i]
    g_items.push((b.to_geometry(), id))
  }
  let inner = @tree.StrTree4D::build(g_items, node_capacity~)
  StrTree4D::{ inner, }
}

///|
/// Performs 4D range intersection query using iterative stack DFS traversal.
pub fn StrTree4D::query(self : StrTree4D, search_box : Box4D) -> Array[Int] {
  self.inner.query(search_box.to_geometry())
}

///|
/// Performs 4D point containment query.
pub fn StrTree4D::query_point(
  self : StrTree4D,
  x : Double,
  y : Double,
  z : Double,
  t : Double,
) -> Array[Int] {
  self.inner.query_point(x, y, z, t)
}

///|
/// Performs zero-allocation count of items intersecting a 4D search box.
pub fn StrTree4D::query_count(self : StrTree4D, search_box : Box4D) -> Int {
  self.inner.query_count(search_box.to_geometry())
}

///|
/// Queries 3D spatial region at specific time instant t.
pub fn StrTree4D::query_time_slice(
  self : StrTree4D,
  t : Double,
  box_3d : Box3D,
) -> Array[Int] {
  self.inner.query_time_slice(t, box_3d.to_geometry())
}

///|
/// Computes structural diagnostic metrics for 4D StrTree.
pub fn StrTree4D::stats(self : StrTree4D) -> TreeStats4D {
  let s = self.inner.stats()
  TreeStats4D::{
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
/// Result of spatial density-based clustering (DBSCAN).
pub struct ClusterResult {
  labels : Array[Int]
  num_clusters : Int
  num_noise : Int
  cluster_sizes : Array[Int]
} derive(Eq, Debug, Default)

///|
/// A discrete 2D spatial grid cell with item density count and bounding rectangle.
pub struct GridCell {
  col : Int
  row : Int
  count : Int
  bounds : Rect
} derive(Eq, Debug, Default)

///|
/// Aggregated spatial grid density summary and hotspot metrics.
pub struct GridDensitySummary {
  cells : Array[GridCell]
  total_cells : Int
  max_density : Int
  avg_density : Double
  hotspot_cells : Array[GridCell]
} derive(Eq, Debug, Default)

///|
/// Performs spatial index-accelerated Density-Based Spatial Clustering of Applications with Noise (DBSCAN).
pub fn StrTree::dbscan(
  self : StrTree,
  eps : Double,
  min_pts : Int,
) -> ClusterResult {
  let res = self.inner.dbscan(eps, min_pts)
  ClusterResult::{
    labels: res.labels,
    num_clusters: res.num_clusters,
    num_noise: res.num_noise,
    cluster_sizes: res.cluster_sizes,
  }
}

///|
/// Partitions spatial items into uniform rectangular grid cells and computes density distribution.
pub fn StrTree::aggregate_grid(
  self : StrTree,
  cell_width : Double,
  cell_height : Double,
  hotspot_threshold? : Int = 1,
) -> GridDensitySummary {
  let s = self.inner.aggregate_grid(cell_width, cell_height, hotspot_threshold~)
  let cells : Array[GridCell] = []
  for i = 0; i < s.cells.length(); i = i + 1 {
    let c = s.cells[i]
    cells.push(GridCell::{
      col: c.col,
      row: c.row,
      count: c.count,
      bounds: Rect::{
        min_x: c.bounds.min_x,
        min_y: c.bounds.min_y,
        max_x: c.bounds.max_x,
        max_y: c.bounds.max_y,
      },
    })
  }
  let hotspots : Array[GridCell] = []
  for i = 0; i < s.hotspot_cells.length(); i = i + 1 {
    let c = s.hotspot_cells[i]
    hotspots.push(GridCell::{
      col: c.col,
      row: c.row,
      count: c.count,
      bounds: Rect::{
        min_x: c.bounds.min_x,
        min_y: c.bounds.min_y,
        max_x: c.bounds.max_x,
        max_y: c.bounds.max_y,
      },
    })
  }
  GridDensitySummary::{
    cells,
    total_cells: s.total_cells,
    max_density: s.max_density,
    avg_density: s.avg_density,
    hotspot_cells: hotspots,
  }
}

///|
/// Performs spatial index-accelerated 3D DBSCAN clustering.
pub fn StrTree3D::dbscan(
  self : StrTree3D,
  eps : Double,
  min_pts : Int,
) -> ClusterResult {
  let res = self.inner.dbscan(eps, min_pts)
  ClusterResult::{
    labels: res.labels,
    num_clusters: res.num_clusters,
    num_noise: res.num_noise,
    cluster_sizes: res.cluster_sizes,
  }
}

///|
/// Discrete transition event emitted when an entity crosses or resides within a geofence.
pub(all) enum GeofenceEvent {
  Enter(Int, Int)
  Exit(Int, Int)
  Stay(Int, Int)
} derive(Eq, Debug)

///|
/// Formats geofence transition event.
pub fn GeofenceEvent::to_string(self : GeofenceEvent) -> String {
  match self {
    Enter(item_id, fence_id) =>
      "Enter(" + item_id.to_string() + ", " + fence_id.to_string() + ")"
    Exit(item_id, fence_id) =>
      "Exit(" + item_id.to_string() + ", " + fence_id.to_string() + ")"
    Stay(item_id, fence_id) =>
      "Stay(" + item_id.to_string() + ", " + fence_id.to_string() + ")"
  }
}

///|
/// Extracts the moving entity ID.
pub fn GeofenceEvent::item_id(self : GeofenceEvent) -> Int {
  match self {
    Enter(id, _) => id
    Exit(id, _) => id
    Stay(id, _) => id
  }
}

///|
/// Extracts the target geofence ID.
pub fn GeofenceEvent::fence_id(self : GeofenceEvent) -> Int {
  match self {
    Enter(_, fid) => fid
    Exit(_, fid) => fid
    Stay(_, fid) => fid
  }
}

///|
/// State tracker monitoring moving entity positions against a spatial index of geofences.
pub struct GeofenceMonitor {
  inner : @tree.GeofenceMonitor
} derive(Eq, Debug, Default)

///|
/// Instantiates a new GeofenceMonitor indexing the supplied geofence bounding boxes.
pub fn GeofenceMonitor::new(
  fences : Array[(Rect, Int)],
  node_capacity? : Int = 16,
) -> GeofenceMonitor {
  let g_fences : Array[(@geometry.Rect, Int)] = []
  for i = 0; i < fences.length(); i = i + 1 {
    let (r, id) = fences[i]
    g_fences.push((r.to_geometry(), id))
  }
  let inner = @tree.GeofenceMonitor::new(g_fences, node_capacity~)
  GeofenceMonitor::{ inner, }
}

///|
fn map_event(ev : @tree.GeofenceEvent) -> GeofenceEvent {
  match ev {
    Enter(item_id, fence_id) => GeofenceEvent::Enter(item_id, fence_id)
    Exit(item_id, fence_id) => GeofenceEvent::Exit(item_id, fence_id)
    Stay(item_id, fence_id) => GeofenceEvent::Stay(item_id, fence_id)
  }
}

///|
/// Updates entity position with a 2D bounding rectangle and returns generated transition events.
pub fn GeofenceMonitor::update_rect(
  self : GeofenceMonitor,
  item_id : Int,
  bounds : Rect,
) -> Array[GeofenceEvent] {
  let evs = self.inner.update_rect(item_id, bounds.to_geometry())
  let res : Array[GeofenceEvent] = []
  for i = 0; i < evs.length(); i = i + 1 {
    res.push(map_event(evs[i]))
  }
  res
}

///|
/// Updates entity position with a 2D point coordinate (x, y) and returns generated events.
pub fn GeofenceMonitor::update_point(
  self : GeofenceMonitor,
  item_id : Int,
  x : Double,
  y : Double,
) -> Array[GeofenceEvent] {
  let evs = self.inner.update_point(item_id, x, y)
  let res : Array[GeofenceEvent] = []
  for i = 0; i < evs.length(); i = i + 1 {
    res.push(map_event(evs[i]))
  }
  res
}

///|
/// Unregisters tracked entity and returns Exit events for all fences it was previously inside.
pub fn GeofenceMonitor::remove_item(
  self : GeofenceMonitor,
  item_id : Int,
) -> Array[GeofenceEvent] {
  let evs = self.inner.remove_item(item_id)
  let res : Array[GeofenceEvent] = []
  for i = 0; i < evs.length(); i = i + 1 {
    res.push(map_event(evs[i]))
  }
  res
}

///|
/// Returns currently active geofence IDs occupied by the entity.
pub fn GeofenceMonitor::active_fences(
  self : GeofenceMonitor,
  item_id : Int,
) -> Array[Int] {
  self.inner.active_fences(item_id)
}

///|
/// Returns true if the entity is currently tracked inside the specified geofence.
pub fn GeofenceMonitor::is_in_fence(
  self : GeofenceMonitor,
  item_id : Int,
  fence_id : Int,
) -> Bool {
  self.inner.is_in_fence(item_id, fence_id)
}

///|
/// Returns the number of currently tracked entities.
pub fn GeofenceMonitor::tracked_count(self : GeofenceMonitor) -> Int {
  self.inner.tracked_count()
}

///|
/// Clears all tracked entities.
pub fn GeofenceMonitor::clear(self : GeofenceMonitor) -> Unit {
  self.inner.clear()
}

///|
/// A timestamped 2D trajectory waypoint coordinate.
pub struct TrajectoryPoint {
  x : Double
  y : Double
  t : Double
  track_id : Int
} derive(Eq, Debug, Default)

///|
/// Creates a new timestamped trajectory waypoint.
pub fn TrajectoryPoint::new(
  x : Double,
  y : Double,
  t : Double,
  track_id : Int,
) -> TrajectoryPoint {
  TrajectoryPoint::{ x, y, t, track_id, }
}

///|
/// A directed 2D trajectory segment connecting two consecutive waypoints in spacetime.
pub struct TrajectorySegment {
  p0_x : Double
  p0_y : Double
  p0_t : Double
  p1_x : Double
  p1_y : Double
  p1_t : Double
  track_id : Int
  segment_id : Int
} derive(Eq, Debug, Default)

///|
/// Creates a new directed trajectory segment with track and segment IDs.
pub fn TrajectorySegment::new(
  p0_x : Double,
  p0_y : Double,
  p0_t : Double,
  p1_x : Double,
  p1_y : Double,
  p1_t : Double,
  track_id : Int,
  segment_id : Int,
) -> TrajectorySegment {
  TrajectorySegment::{
    p0_x,
    p0_y,
    p0_t,
    p1_x,
    p1_y,
    p1_t,
    track_id,
    segment_id,
  }
}

///|
/// Computes 2D spatial bounding box enclosing the trajectory segment.
pub fn TrajectorySegment::bounding_rect(self : TrajectorySegment) -> Rect {
  let min_x = if self.p0_x < self.p1_x { self.p0_x } else { self.p1_x }
  let max_x = if self.p0_x > self.p1_x { self.p0_x } else { self.p1_x }
  let min_y = if self.p0_y < self.p1_y { self.p0_y } else { self.p1_y }
  let max_y = if self.p0_y > self.p1_y { self.p0_y } else { self.p1_y }
  Rect::new(min_x, min_y, max_x, max_y)
}

///|
/// Computes temporal duration (|p1_t - p0_t|).
pub fn TrajectorySegment::duration(self : TrajectorySegment) -> Double {
  let dt = self.p1_t - self.p0_t
  if dt < 0.0 {
    -dt
  } else {
    dt
  }
}

///|
/// Computes Euclidean 2D spatial path length.
pub fn TrajectorySegment::length(self : TrajectorySegment) -> Double {
  let dx = self.p1_x - self.p0_x
  let dy = self.p1_y - self.p0_y
  let d_sq = dx * dx + dy * dy
  if d_sq <= 0.0 {
    0.0
  } else {
    let mut x = d_sq / 2.0
    if x <= 0.0 {
      x = 1.0
    }
    for step = 0; step < 12; step = step + 1 {
      x = 0.5 * (x + d_sq / x)
    }
    x
  }
}

///|
/// Computes average kinematic speed (length / duration).
pub fn TrajectorySegment::speed(self : TrajectorySegment) -> Double {
  let dur = self.duration()
  if dur <= 1.0e-9 {
    0.0
  } else {
    self.length() / dur
  }
}

///|
/// Linearly interpolates (x, y) spatial coordinates at timestamp t.
pub fn TrajectorySegment::interpolate_position(
  self : TrajectorySegment,
  t : Double,
) -> (Double, Double)? {
  let t_start = if self.p0_t < self.p1_t { self.p0_t } else { self.p1_t }
  let t_end = if self.p0_t > self.p1_t { self.p0_t } else { self.p1_t }
  if t < t_start || t > t_end {
    return None
  }
  let span = self.p1_t - self.p0_t
  if span.abs() <= 1.0e-9 {
    return Some((self.p0_x, self.p0_y))
  }
  let alpha = (t - self.p0_t) / span
  let ix = self.p0_x + alpha * (self.p1_x - self.p0_x)
  let iy = self.p0_y + alpha * (self.p1_y - self.p0_y)
  Some((ix, iy))
}

///|
/// Spatiotemporal sliding-window trajectory segment index.
pub struct TrajectoryWindowIndex {
  inner : @tree.TrajectoryWindowIndex
} derive(Eq, Debug, Default)

///|
/// Builds a TrajectoryWindowIndex from an array of TrajectorySegments.
pub fn TrajectoryWindowIndex::build(
  segments : Array[TrajectorySegment],
  node_capacity? : Int = 16,
) -> TrajectoryWindowIndex {
  let t_segs : Array[@tree.TrajectorySegment] = []
  for i = 0; i < segments.length(); i = i + 1 {
    let s = segments[i]
    t_segs.push(
      @tree.TrajectorySegment::new(
        s.p0_x,
        s.p0_y,
        s.p0_t,
        s.p1_x,
        s.p1_y,
        s.p1_t,
        s.track_id,
        s.segment_id,
      ),
    )
  }
  let inner = @tree.TrajectoryWindowIndex::build(t_segs, node_capacity~)
  TrajectoryWindowIndex::{ inner, }
}

///|
/// Converts consecutive trajectory waypoints into directed segments, joining points with matching track_id.
pub fn TrajectoryWindowIndex::segments_from_points(
  points : Array[TrajectoryPoint],
) -> Array[TrajectorySegment] {
  let t_pts : Array[@tree.TrajectoryPoint] = []
  for i = 0; i < points.length(); i = i + 1 {
    let p = points[i]
    t_pts.push(@tree.TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  let t_segs = @tree.TrajectoryWindowIndex::segments_from_points(t_pts)
  let res : Array[TrajectorySegment] = []
  for i = 0; i < t_segs.length(); i = i + 1 {
    let s = t_segs[i]
    res.push(
      TrajectorySegment::new(
        s.p0_x,
        s.p0_y,
        s.p0_t,
        s.p1_x,
        s.p1_y,
        s.p1_t,
        s.track_id,
        s.segment_id,
      ),
    )
  }
  res
}

///|
/// Queries all trajectory segment IDs whose spatial bounding box intersects search_window
/// and whose temporal lifespan overlaps [t_min, t_max].
pub fn TrajectoryWindowIndex::query_window(
  self : TrajectoryWindowIndex,
  spatial_window : Rect,
  t_min : Double,
  t_max : Double,
) -> Array[Int] {
  self.inner.query_window(spatial_window.to_geometry(), t_min, t_max)
}

///|
/// Queries unique track IDs that intersected search_window during temporal interval [t_min, t_max].
pub fn TrajectoryWindowIndex::query_tracks_in_window(
  self : TrajectoryWindowIndex,
  spatial_window : Rect,
  t_min : Double,
  t_max : Double,
) -> Array[Int] {
  self.inner.query_tracks_in_window(spatial_window.to_geometry(), t_min, t_max)
}

///|
/// Returns total number of indexed trajectory segments.
pub fn TrajectoryWindowIndex::num_segments(self : TrajectoryWindowIndex) -> Int {
  self.inner.num_segments()
}

///|
/// Metrics and decimated point collection resulting from trajectory simplification.
pub struct TrajectorySimplificationResult {
  points : Array[TrajectoryPoint]
  original_count : Int
  simplified_count : Int
  compression_ratio : Double
  max_error : Double
} derive(Eq, Debug, Default)

///|
/// Simplifies a 2D trajectory waypoint sequence using Douglas-Peucker algorithm with tolerance epsilon.
pub fn simplify_trajectory_2d(
  points : Array[TrajectoryPoint],
  epsilon : Double,
) -> TrajectorySimplificationResult {
  let t_pts : Array[@tree.TrajectoryPoint] = []
  for i = 0; i < points.length(); i = i + 1 {
    let p = points[i]
    t_pts.push(@tree.TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  let res = @tree.simplify_trajectory_2d(t_pts, epsilon)
  let out_pts : Array[TrajectoryPoint] = []
  for i = 0; i < res.points.length(); i = i + 1 {
    let p = res.points[i]
    out_pts.push(TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  TrajectorySimplificationResult::{
    points: out_pts,
    original_count: res.original_count,
    simplified_count: res.simplified_count,
    compression_ratio: res.compression_ratio,
    max_error: res.max_error,
  }
}

///|
/// Simplifies a spatiotemporal trajectory using Synchronized Euclidean Distance (SED) tolerance epsilon.
pub fn simplify_trajectory_spatiotemporal(
  points : Array[TrajectoryPoint],
  epsilon : Double,
) -> TrajectorySimplificationResult {
  let t_pts : Array[@tree.TrajectoryPoint] = []
  for i = 0; i < points.length(); i = i + 1 {
    let p = points[i]
    t_pts.push(@tree.TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  let res = @tree.simplify_trajectory_spatiotemporal(t_pts, epsilon)
  let out_pts : Array[TrajectoryPoint] = []
  for i = 0; i < res.points.length(); i = i + 1 {
    let p = res.points[i]
    out_pts.push(TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  TrajectorySimplificationResult::{
    points: out_pts,
    original_count: res.original_count,
    simplified_count: res.simplified_count,
    compression_ratio: res.compression_ratio,
    max_error: res.max_error,
  }
}

///|
/// Online streaming trajectory compressor performing real-time decimation against error tolerance.
pub struct StreamingTrajectoryCompressor {
  inner : @tree.StreamingTrajectoryCompressor
} derive(Eq, Debug)

///|
/// Instantiates an online trajectory compressor with error bound epsilon and optional SED calculation.
pub fn StreamingTrajectoryCompressor::new(
  epsilon : Double,
  use_sed? : Bool = false,
) -> StreamingTrajectoryCompressor {
  let inner = @tree.StreamingTrajectoryCompressor::new(epsilon, use_sed~)
  StreamingTrajectoryCompressor::{ inner, }
}

///|
/// Ingests a new trajectory waypoint and returns any newly finalized anchor waypoints.
pub fn StreamingTrajectoryCompressor::push(
  self : StreamingTrajectoryCompressor,
  pt : TrajectoryPoint,
) -> Array[TrajectoryPoint] {
  let emitted = self.inner.push(
    @tree.TrajectoryPoint::new(pt.x, pt.y, pt.t, pt.track_id),
  )
  let res : Array[TrajectoryPoint] = []
  for i = 0; i < emitted.length(); i = i + 1 {
    let p = emitted[i]
    res.push(TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  res
}

///|
/// Flushes the remaining trajectory stream and returns all preserved decimated waypoints.
pub fn StreamingTrajectoryCompressor::finish(
  self : StreamingTrajectoryCompressor,
) -> Array[TrajectoryPoint] {
  let final_pts = self.inner.finish()
  let res : Array[TrajectoryPoint] = []
  for i = 0; i < final_pts.length(); i = i + 1 {
    let p = final_pts[i]
    res.push(TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  res
}

///|
/// Returns total number of incoming points received so far.
pub fn StreamingTrajectoryCompressor::total_received(
  self : StreamingTrajectoryCompressor,
) -> Int {
  self.inner.total_received()
}

///|
/// Returns total number of finalized waypoints emitted so far.
pub fn StreamingTrajectoryCompressor::total_emitted(
  self : StreamingTrajectoryCompressor,
) -> Int {
  self.inner.total_emitted()
}

///|
/// Computes point decimation percentage ((1 - emitted / received) * 100).
pub fn StreamingTrajectoryCompressor::compression_ratio(
  self : StreamingTrajectoryCompressor,
) -> Double {
  self.inner.compression_ratio()
}

///|
/// Computes Dynamic Time Warping (DTW) distance between two trajectories with optional Sakoe-Chiba window constraint.
pub fn trajectory_dtw_distance(
  a : Array[TrajectoryPoint],
  b : Array[TrajectoryPoint],
  window? : Int = -1,
) -> Double {
  let t_a : Array[@tree.TrajectoryPoint] = []
  for i = 0; i < a.length(); i = i + 1 {
    let p = a[i]
    t_a.push(@tree.TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  let t_b : Array[@tree.TrajectoryPoint] = []
  for i = 0; i < b.length(); i = i + 1 {
    let p = b[i]
    t_b.push(@tree.TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  @tree.trajectory_dtw_distance(t_a, t_b, window~)
}

///|
/// Computes length-normalized DTW distance (total_dtw / (len_a + len_b)).
pub fn trajectory_dtw_normalized(
  a : Array[TrajectoryPoint],
  b : Array[TrajectoryPoint],
  window? : Int = -1,
) -> Double {
  let t_a : Array[@tree.TrajectoryPoint] = []
  for i = 0; i < a.length(); i = i + 1 {
    let p = a[i]
    t_a.push(@tree.TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  let t_b : Array[@tree.TrajectoryPoint] = []
  for i = 0; i < b.length(); i = i + 1 {
    let p = b[i]
    t_b.push(@tree.TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  @tree.trajectory_dtw_normalized(t_a, t_b, window~)
}

///|
/// Computes Discrete Fréchet Distance between two polygonal trajectory curves.
pub fn trajectory_frechet_distance(
  a : Array[TrajectoryPoint],
  b : Array[TrajectoryPoint],
) -> Double {
  let t_a : Array[@tree.TrajectoryPoint] = []
  for i = 0; i < a.length(); i = i + 1 {
    let p = a[i]
    t_a.push(@tree.TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  let t_b : Array[@tree.TrajectoryPoint] = []
  for i = 0; i < b.length(); i = i + 1 {
    let p = b[i]
    t_b.push(@tree.TrajectoryPoint::new(p.x, p.y, p.t, p.track_id))
  }
  @tree.trajectory_frechet_distance(t_a, t_b)
}

///|
/// A 2D point coordinate representing a polygon vertex.
pub struct Point2D {
  x : Double
  y : Double
} derive(Eq, Debug, Default)

///|
/// Creates a new 2D point coordinate.
pub fn Point2D::new(x : Double, y : Double) -> Point2D {
  Point2D::{ x, y, }
}

///|
/// Computes Euclidean distance to another 2D point.
pub fn Point2D::distance_to(self : Point2D, other : Point2D) -> Double {
  let dx = self.x - other.x
  let dy = self.y - other.y
  (dx * dx + dy * dy).sqrt()
}

///|
/// A 2D polygonal planar curve or ring defined by sequential vertices.
pub struct Polygon2D {
  vertices : Array[Point2D]
} derive(Eq, Debug, Default)

///|
/// Creates a new Polygon2D from an ordered array of 2D vertices.
pub fn Polygon2D::new(vertices : Array[Point2D]) -> Polygon2D {
  Polygon2D::{ vertices, }
}

///|
fn Polygon2D::to_tree(self : Polygon2D) -> @tree.Polygon2D {
  let vs : Array[@tree.Point2D] = []
  for i = 0; i < self.vertices.length(); i = i + 1 {
    let p = self.vertices[i]
    vs.push(@tree.Point2D::new(p.x, p.y))
  }
  @tree.Polygon2D::new(vs)
}

///|
fn Polygon2D::from_tree(poly : @tree.Polygon2D) -> Polygon2D {
  let vs : Array[Point2D] = []
  for i = 0; i < poly.vertices.length(); i = i + 1 {
    let p = poly.vertices[i]
    vs.push(Point2D::new(p.x, p.y))
  }
  Polygon2D::new(vs)
}

///|
/// Computes the planar signed/unsigned area using Green's theorem / Shoelace formula.
pub fn Polygon2D::area(self : Polygon2D) -> Double {
  self.to_tree().area()
}

///|
/// Computes total boundary perimeter length of the closed polygon.
pub fn Polygon2D::perimeter(self : Polygon2D) -> Double {
  self.to_tree().perimeter()
}

///|
/// Returns the minimum axis-aligned bounding box (AABB) enveloping all vertices.
pub fn Polygon2D::envelope(self : Polygon2D) -> Rect {
  let r = self.to_tree().envelope()
  Rect::new(r.min_x, r.min_y, r.max_x, r.max_y)
}

///|
/// Tests whether a point (px, py) is contained within the polygon boundary.
pub fn Polygon2D::contains_point(
  self : Polygon2D,
  px : Double,
  py : Double,
) -> Bool {
  self.to_tree().contains_point(px, py)
}

///|
/// Computes the planar geometric centroid of the polygon.
pub fn Polygon2D::centroid(self : Polygon2D) -> Point2D {
  let c = self.to_tree().centroid()
  Point2D::new(c.x, c.y)
}

///|
/// Sutherland-Hodgman polygon clipping against an axis-aligned rectangular bounding box.
pub fn Polygon2D::clip_rect(self : Polygon2D, clip_box : Rect) -> Polygon2D {
  let res = self.to_tree().clip_rect(clip_box.to_geometry())
  Polygon2D::from_tree(res)
}

///|
/// Sutherland-Hodgman polygon clipping against an arbitrary convex polygon.
pub fn Polygon2D::clip_convex(
  self : Polygon2D,
  clip_poly : Polygon2D,
) -> Polygon2D {
  let res = self.to_tree().clip_convex(clip_poly.to_tree())
  Polygon2D::from_tree(res)
}

///|
/// A packed spatial index managing collections of 2D polygonal planar shapes.
pub struct StrPolygonIndex {
  inner : @tree.StrPolygonIndex
} derive(Eq, Debug, Default)

///|
/// Builds a packed StrPolygonIndex from an array of 2D polygons and optional node capacity.
pub fn StrPolygonIndex::build(
  polygons : Array[Polygon2D],
  node_capacity? : Int = 16,
) -> StrPolygonIndex {
  let t_polys : Array[@tree.Polygon2D] = []
  for i = 0; i < polygons.length(); i = i + 1 {
    t_polys.push(polygons[i].to_tree())
  }
  let inner = @tree.StrPolygonIndex::build(t_polys, node_capacity~)
  StrPolygonIndex::{ inner, }
}

///|
/// Returns total count of indexed polygons.
pub fn StrPolygonIndex::total_polygons(self : StrPolygonIndex) -> Int {
  self.inner.total_polygons()
}

///|
/// Returns the global bounding envelope encompassing all indexed polygons.
pub fn StrPolygonIndex::envelope(self : StrPolygonIndex) -> Rect {
  let r = self.inner.envelope()
  Rect::new(r.min_x, r.min_y, r.max_x, r.max_y)
}

///|
/// Queries polygon indices whose bounding envelopes intersect the query window.
pub fn StrPolygonIndex::query_window(
  self : StrPolygonIndex,
  window : Rect,
) -> Array[Int] {
  self.inner.query_window(window.to_geometry())
}

///|
/// Returns the count of candidate polygons intersecting the query window without allocation.
pub fn StrPolygonIndex::query_count(
  self : StrPolygonIndex,
  window : Rect,
) -> Int {
  self.inner.query_count(window.to_geometry())
}

///|
/// Retrieves all full Polygon2D instances intersecting the query window.
pub fn StrPolygonIndex::query_polygons(
  self : StrPolygonIndex,
  window : Rect,
) -> Array[Polygon2D] {
  let polys = self.inner.query_polygons(window.to_geometry())
  let res : Array[Polygon2D] = []
  for i = 0; i < polys.length(); i = i + 1 {
    res.push(Polygon2D::from_tree(polys[i]))
  }
  res
}

///|
/// Hierarchically queries polygons intersecting the window and clips each with Sutherland-Hodgman,
/// returning only valid planar fragments strictly contained inside the window.
pub fn StrPolygonIndex::query_clipped_polygons(
  self : StrPolygonIndex,
  window : Rect,
) -> Array[Polygon2D] {
  let polys = self.inner.query_clipped_polygons(window.to_geometry())
  let res : Array[Polygon2D] = []
  for i = 0; i < polys.length(); i = i + 1 {
    res.push(Polygon2D::from_tree(polys[i]))
  }
  res
}
