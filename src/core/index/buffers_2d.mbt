///|
/// Raw contiguous array buffers of a packed StrTree for persistence with independently owned array copies.
pub struct FlatBuffers {
  boxes_min_x : Array[Double]
  boxes_min_y : Array[Double]
  boxes_max_x : Array[Double]
  boxes_max_y : Array[Double]
  child_offset : Array[Int]
  child_count : Array[Int]
  child_indices : Array[Int]
  item_ids : Array[Int]
  root_index : Int
  node_capacity : Int
  num_items : Int
  height : Int
} derive(Eq, Debug, Default)

///|
/// Exports raw contiguous array buffers.
pub fn StrTree::to_flat_buffers(self : StrTree) -> FlatBuffers {
  FlatBuffers::{
    boxes_min_x: self.boxes_min_x.copy(),
    boxes_min_y: self.boxes_min_y.copy(),
    boxes_max_x: self.boxes_max_x.copy(),
    boxes_max_y: self.boxes_max_y.copy(),
    child_offset: self.child_offset.copy(),
    child_count: self.child_count.copy(),
    child_indices: self.child_indices.copy(),
    item_ids: self.item_ids.copy(),
    root_index: self.root_index,
    node_capacity: self.node_capacity,
    num_items: self.num_items,
    height: self.height,
  }
}

///|
/// Reconstructs a StrTree directly from raw contiguous array buffers.
pub fn StrTree::from_flat_buffers(buffers : FlatBuffers) -> StrTree {
  StrTree::{
    boxes_min_x: buffers.boxes_min_x.copy(),
    boxes_min_y: buffers.boxes_min_y.copy(),
    boxes_max_x: buffers.boxes_max_x.copy(),
    boxes_max_y: buffers.boxes_max_y.copy(),
    child_offset: buffers.child_offset.copy(),
    child_count: buffers.child_count.copy(),
    child_indices: buffers.child_indices.copy(),
    item_ids: buffers.item_ids.copy(),
    root_index: buffers.root_index,
    node_capacity: buffers.node_capacity,
    num_items: buffers.num_items,
    height: buffers.height,
    contiguous_leaves: buffers.has_contiguous_leaves(),
  }
}

///|
/// Reconstruct this derived layout hint; it is not part of the persisted format.
fn FlatBuffers::has_contiguous_leaves(self : FlatBuffers) -> Bool {
  let nodes = self.item_ids.length()
  if nodes == 0 ||
    self.boxes_min_x.length() != nodes ||
    self.boxes_min_y.length() != nodes ||
    self.boxes_max_x.length() != nodes ||
    self.boxes_max_y.length() != nodes ||
    !validate_topology(
      self.child_offset,
      self.child_count,
      self.child_indices,
      self.item_ids,
      self.root_index,
      self.node_capacity,
      self.num_items,
      self.height,
    ) {
    return false
  }
  for i = 0; i < nodes; i = i + 1 {
    if (self.child_count[i] == 0) != (i < self.num_items) {
      return false
    }
  }
  // All subtree leaf intervals must follow the same depth-first order.
  let stack : Array[Int] = [self.root_index]
  let mut leaf = 0
  while !stack.is_empty() {
    let node = stack.unsafe_pop()
    let offset = self.child_offset[node]
    let count = self.child_count[node]
    let first = self.child_indices[offset]
    if first < self.num_items {
      for i = offset; i < offset + count; i = i + 1 {
        if self.child_indices[i] != leaf {
          return false
        }
        leaf = leaf + 1
      }
    } else {
      let mut i = offset + count
      while i > offset {
        i = i - 1
        stack.push(self.child_indices[i])
      }
    }
  }
  true
}
