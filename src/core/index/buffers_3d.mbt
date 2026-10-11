///|
/// Raw contiguous array buffers of a packed StrTree3D for persistence with independently owned array copies.
pub struct FlatBuffers3D {
  boxes_min_x : Array[Double]
  boxes_min_y : Array[Double]
  boxes_min_z : Array[Double]
  boxes_max_x : Array[Double]
  boxes_max_y : Array[Double]
  boxes_max_z : Array[Double]
  child_offset : Array[Int]
  child_count : Array[Int]
  child_indices : Array[Int]
  item_ids : Array[Int]
  node_levels : Array[Int]
  num_items : Int
  num_nodes : Int
  height : Int
  node_capacity : Int
  root_index : Int
} derive(Eq, Debug, Default)

///|
/// Exports raw contiguous array buffers from StrTree3D.
pub fn StrTree3D::to_flat_buffers(self : StrTree3D) -> FlatBuffers3D {
  FlatBuffers3D::{
    boxes_min_x: self.boxes_min_x.copy(),
    boxes_min_y: self.boxes_min_y.copy(),
    boxes_min_z: self.boxes_min_z.copy(),
    boxes_max_x: self.boxes_max_x.copy(),
    boxes_max_y: self.boxes_max_y.copy(),
    boxes_max_z: self.boxes_max_z.copy(),
    child_offset: self.child_offset.copy(),
    child_count: self.child_count.copy(),
    child_indices: self.child_indices.copy(),
    item_ids: self.item_ids.copy(),
    node_levels: self.node_levels.copy(),
    num_items: self.num_items,
    num_nodes: self.num_nodes,
    height: self.height,
    node_capacity: self.node_capacity,
    root_index: self.root_index,
  }
}

///|
/// Reconstructs a StrTree3D directly from raw contiguous array buffers.
pub fn StrTree3D::from_flat_buffers(buffers : FlatBuffers3D) -> StrTree3D {
  StrTree3D::{
    boxes_min_x: buffers.boxes_min_x.copy(),
    boxes_min_y: buffers.boxes_min_y.copy(),
    boxes_min_z: buffers.boxes_min_z.copy(),
    boxes_max_x: buffers.boxes_max_x.copy(),
    boxes_max_y: buffers.boxes_max_y.copy(),
    boxes_max_z: buffers.boxes_max_z.copy(),
    child_offset: buffers.child_offset.copy(),
    child_count: buffers.child_count.copy(),
    child_indices: buffers.child_indices.copy(),
    item_ids: buffers.item_ids.copy(),
    node_levels: buffers.node_levels.copy(),
    num_items: buffers.num_items,
    num_nodes: buffers.num_nodes,
    height: buffers.height,
    node_capacity: buffers.node_capacity,
    root_index: buffers.root_index,
  }
}
