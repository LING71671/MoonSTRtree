///|
/// Diagnostic statistics for a packed 4D StrTree.
pub struct TreeStats4D {
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
/// Computes structural diagnostic metrics for 4D StrTree.
pub fn StrTree4D::stats(self : StrTree4D) -> TreeStats4D {
  let mut leaves = 0
  let mut branches = 0
  for i = 0; i < self.num_nodes; i = i + 1 {
    if self.child_count[i] == 0 {
      leaves = leaves + 1
    } else {
      branches = branches + 1
    }
  }

  let total_edges = self.child_indices.length()
  let est_bytes = self.num_nodes * (8 * 8 + 4 * 4) + total_edges * 4
  let fill_factor = if branches == 0 {
    1.0
  } else {
    total_edges.to_double() /
    (branches.to_double() * self.node_capacity.to_double())
  }

  TreeStats4D::{
    num_items: self.num_items,
    num_nodes: self.num_nodes,
    height: self.height,
    node_capacity: self.node_capacity,
    fill_factor,
    leaf_nodes: leaves,
    branch_nodes: branches,
    total_edges,
    estimated_memory_bytes: est_bytes,
  }
}
