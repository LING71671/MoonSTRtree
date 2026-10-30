///|
/// Diagnostic statistics for a packed 3D StrTree.
pub struct TreeStats3D {
  num_items : Int32
  num_nodes : Int32
  height : Int32
  node_capacity : Int32
  fill_factor : Double
  leaf_nodes : Int32
  branch_nodes : Int32
  total_edges : Int32
  estimated_memory_bytes : Int32
} derive(Eq, Debug, Default)

///|
/// Packed 3D spatial index tree with contiguous flat array storage.
pub struct StrTree3D {
  priv inner : @tree.StrTree3D
} derive(Eq, Debug, Default)

///|
/// Builds a packed 3D StrTree from an array of (Box3D, ID) pairs and optional node capacity.
pub fn StrTree3D::build(
  items : Array[(Box3D, Int32)],
  node_capacity~ : Int32 = 16,
) -> StrTree3D {
  let inner = @tree.StrTree3D::build(items, node_capacity~)
  StrTree3D::{ inner, }
}

///|
/// Performs 3D range query using iterative stack DFS traversal.
pub fn StrTree3D::query(self : StrTree3D, search_box : Box3D) -> Array[Int32] {
  self.inner.query(search_box)
}

///|
/// Counts intersecting items without materializing result IDs; traversal uses a temporary stack.
pub fn StrTree3D::query_count(self : StrTree3D, search_box : Box3D) -> Int32 {
  self.inner.query_count(search_box)
}

///|
/// Performs 3D point containment query.
pub fn StrTree3D::query_point(
  self : StrTree3D,
  x : Double,
  y : Double,
  z : Double,
) -> Array[Int32] {
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
) -> Array[Int32] {
  self.inner.query_sphere(cx, cy, cz, radius)
}

///|
/// Performs branch-and-bound k-Nearest Neighbor (k-NN) search in 3D Euclidean space.
pub fn StrTree3D::query_knn(
  self : StrTree3D,
  x : Double,
  y : Double,
  z : Double,
  k : Int32,
) -> Array[Int32] {
  self.inner.query_knn(x, y, z, k)
}

///|
/// Performs branch-and-bound 3D k-NN search returning pairs of (item_id, squared_distance).
pub fn StrTree3D::query_knn_with_distance(
  self : StrTree3D,
  x : Double,
  y : Double,
  z : Double,
  k : Int32,
) -> Array[(Int32, Double)] {
  self.inner.query_knn_with_distance(x, y, z, k)
}

///|
/// Performs branch-and-bound 3D k-NN search filtered by a user predicate closure.
pub fn StrTree3D::query_knn_with_predicate(
  self : StrTree3D,
  x : Double,
  y : Double,
  z : Double,
  k : Int32,
  predicate : (Int32) -> Bool,
) -> Array[Int32] {
  self.inner.query_knn_with_predicate(x, y, z, k, predicate)
}

///|
/// Performs branch-and-bound 3D k-NN search with predicate and distance pairs.
pub fn StrTree3D::query_knn_with_predicate_and_distance(
  self : StrTree3D,
  x : Double,
  y : Double,
  z : Double,
  k : Int32,
  predicate : (Int32) -> Bool,
) -> Array[(Int32, Double)] {
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
) -> Array[Int32] {
  self.inner.query_segment(x1, y1, z1, x2, y2, z2)
}

///|
/// Counts items containing a point without materializing result IDs; traversal uses a temporary stack.
pub fn StrTree3D::query_point_count(
  self : StrTree3D,
  x : Double,
  y : Double,
  z : Double,
) -> Int32 {
  self.inner.query_point_count(x, y, z)
}

///|
/// Counts sphere intersections without materializing result IDs; traversal uses a temporary stack.
pub fn StrTree3D::query_sphere_count(
  self : StrTree3D,
  cx : Double,
  cy : Double,
  cz : Double,
  radius : Double,
) -> Int32 {
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
) -> Array[(Int32, Int32)] {
  self.inner.spatial_join(other.inner)
}

///|
/// Performs 3D range intersection query returning first matching item ID satisfying predicate.
pub fn StrTree3D::query_first(
  self : StrTree3D,
  search_box : Box3D,
  predicate : (Int32) -> Bool,
) -> Int32? {
  self.inner.query_first(search_box, predicate)
}

///|
/// Performs 3D range intersection query with filter predicate.
pub fn StrTree3D::query_with_predicate(
  self : StrTree3D,
  search_box : Box3D,
  predicate : (Int32) -> Bool,
) -> Array[Int32] {
  self.inner.query_with_predicate(search_box, predicate)
}

///|
/// Raw contiguous array buffers of a packed StrTree3D for persistence with independently owned array copies.
pub struct FlatBuffers3D {
  priv inner : @tree.FlatBuffers3D
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
/// Restores only buffers with valid topology, metadata and finite bounds.
pub fn StrTree3D::from_flat_buffers_checked(
  buffers : FlatBuffers3D,
) -> StrTree3D? {
  match @tree.StrTree3D::from_flat_buffers_checked(buffers.inner) {
    Some(inner) => Some(StrTree3D::{ inner, })
    None => None
  }
}
