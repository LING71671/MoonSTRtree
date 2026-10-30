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
/// Computes structural diagnostic metrics for 3D StrTree.
pub fn StrTree3D::stats(self : StrTree3D) -> TreeStats3D {
  let mut leaf_nodes = 0
  let mut branch_nodes = 0
  for i = 0; i < self.num_nodes; i = i + 1 {
    if self.child_count[i] == 0 {
      leaf_nodes = leaf_nodes + 1
    } else {
      branch_nodes = branch_nodes + 1
    }
  }

  let fill_factor = if branch_nodes == 0 {
    1.0
  } else {
    self.child_indices.length().to_double() /
    (branch_nodes.to_double() * self.node_capacity.to_double())
  }

  let estimated_memory_bytes = self.num_nodes * (8 * 6 + 4 * 4) +
    self.child_indices.length() * 4

  TreeStats3D::{
    num_items: self.num_items,
    num_nodes: self.num_nodes,
    height: self.height,
    node_capacity: self.node_capacity,
    fill_factor,
    leaf_nodes,
    branch_nodes,
    total_edges: self.child_indices.length(),
    estimated_memory_bytes,
  }
}
