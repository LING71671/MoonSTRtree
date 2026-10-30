///|
/// Comprehensive structural and memory diagnostics for a packed StrTree.
pub struct TreeStats {
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
/// Returns root bounding box of the indexed tree.
pub fn TreeStats::root_bounds(tree : @tree.StrTree) -> @geometry.Rect? {
  tree.root_bounds()
}

///|
/// Computes structural diagnostic metrics from a StrTree.
pub fn TreeStats::compute(tree : @tree.StrTree) -> TreeStats {
  let num_items = tree.num_items()
  let num_nodes = tree.num_nodes()
  let height = tree.height()
  let node_capacity = tree.node_capacity()
  let total_edges = tree.total_edges()

  if num_nodes == 0 {
    return TreeStats::{
      num_items: 0,
      num_nodes: 0,
      height: 0,
      node_capacity,
      fill_factor: 1.0,
      leaf_nodes: 0,
      branch_nodes: 0,
      total_edges: 0,
      estimated_memory_bytes: 0,
    }
  }

  let mut leaf_nodes = 0
  let mut branch_nodes = 0
  let mut total_branch_children = 0

  for i = 0; i < num_nodes; i = i + 1 {
    if tree.is_leaf_at(i) {
      leaf_nodes = leaf_nodes + 1
    } else {
      branch_nodes = branch_nodes + 1
      total_branch_children = total_branch_children + tree.child_count_at(i)
    }
  }

  let fill_factor = if branch_nodes == 0 {
    1.0
  } else {
    total_branch_children.to_double() /
    (branch_nodes.to_double() * node_capacity.to_double())
  }

  // Node overhead: 4 doubles (32 bytes) + 3 ints (12 bytes) = 44 bytes per node
  // Edge overhead: 4 bytes per edge in child_indices
  let estimated_memory_bytes = num_nodes * 44 + total_edges * 4

  TreeStats::{
    num_items,
    num_nodes,
    height,
    node_capacity,
    fill_factor,
    leaf_nodes,
    branch_nodes,
    total_edges,
    estimated_memory_bytes,
  }
}

///|
/// Validates complete hierarchical geometric integrity:
/// 1. All node bounding boxes are valid (non-NaN, min <= max).
/// 2. Every branch node strictly encloses all of its children's bounding boxes.
/// 3. Every leaf item has a valid non-negative user ID.
pub fn TreeStats::validate_integrity(tree : @tree.StrTree) -> Bool {
  tree.validate_integrity()
}
