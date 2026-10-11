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
  priv inner : @tree.StrTree4D
} derive(Eq, Debug, Default)

///|
/// Builds a packed 4D StrTree from an array of (Box4D, ID) pairs and optional node capacity.
pub fn StrTree4D::build(
  items : Array[(Box4D, Int)],
  node_capacity? : Int = 16,
) -> StrTree4D {
  let inner = @tree.StrTree4D::build(items, node_capacity~)
  StrTree4D::{ inner, }
}

///|
/// Performs 4D range intersection query using iterative stack DFS traversal.
pub fn StrTree4D::query(self : StrTree4D, search_box : Box4D) -> Array[Int] {
  self.inner.query(search_box)
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
  self.inner.query_count(search_box)
}

///|
/// Queries 3D spatial region at specific time instant t.
pub fn StrTree4D::query_time_slice(
  self : StrTree4D,
  t : Double,
  box_3d : Box3D,
) -> Array[Int] {
  self.inner.query_time_slice(t, box_3d)
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
