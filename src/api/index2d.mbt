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
  priv inner : @tree.StrTree
} derive(Eq, Debug, Default)

///|
/// Builds a packed StrTree from an array of (Rect, ID) pairs and optional node capacity.
pub fn StrTree::build(
  items : Array[(Rect, Int)],
  node_capacity? : Int = 16,
) -> StrTree {
  let inner = @tree.StrTree::build(items, node_capacity~)
  StrTree::{ inner, }
}

///|
/// Builds normalized rectangles from [minX, minY, maxX, maxY] coordinates.
/// IDs are their zero-based input positions. Length must be divisible by four.
pub fn StrTree::build_coordinates(
  coordinates : Array[Double],
  node_capacity? : Int = 16,
) -> StrTree {
  StrTree::{
    inner: @tree.StrTree::build_coordinates(coordinates, node_capacity~),
  }
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
  self.inner.query(search_window)
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
  self.inner.query_count(search_window)
}

///|
/// Performs point inclusion counting without allocating a result array.
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
  self.inner.query_first(search_window, predicate)
}

///|
/// Performs axis-aligned bounding box range intersection query with filter predicate.
pub fn StrTree::query_with_predicate(
  self : StrTree,
  search_window : Rect,
  predicate : (Int) -> Bool,
) -> Array[Int] {
  self.inner.query_with_predicate(search_window, predicate)
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
  self.inner.query_spatial_predicate(rect, predicate)
}

///|
/// Performs hierarchical spatial join between two trees filtering by a named topological predicate.
pub fn StrTree::spatial_join_predicate(
  self : StrTree,
  other : StrTree,
  predicate : SpatialPredicate,
) -> Array[(Int, Int)] {
  self.inner.spatial_join_predicate(other.inner, predicate)
}

///|
/// Raw contiguous array buffers of a packed StrTree for persistence with independently owned array copies.
pub struct FlatBuffers {
  priv inner : @tree.FlatBuffers
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
/// Restores only buffers with valid topology, metadata and finite bounds.
pub fn StrTree::from_flat_buffers_checked(buffers : FlatBuffers) -> StrTree? {
  match @tree.StrTree::from_flat_buffers_checked(buffers.inner) {
    Some(inner) => Some(StrTree::{ inner, })
    None => None
  }
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
/// Clears and reuses distinct caller-owned result and traversal buffers.
pub fn StrTree::query_into(
  self : StrTree,
  search_window : Rect,
  results : Array[Int],
  stack : Array[Int],
) -> Unit {
  self.inner.query_into(search_window, results, stack)
}

///|
/// Checks raw topology, metadata and finite geometric enclosures.
pub fn StrTree::validate_integrity(self : StrTree) -> Bool {
  self.inner.validate_integrity()
}
