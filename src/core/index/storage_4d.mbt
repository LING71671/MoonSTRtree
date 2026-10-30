///|
/// Packed 4D spatiotemporal index tree with contiguous flat array storage.
pub struct StrTree4D {
  priv boxes_min_x : Array[Double]
  priv boxes_min_y : Array[Double]
  priv boxes_min_z : Array[Double]
  priv boxes_min_t : Array[Double]
  priv boxes_max_x : Array[Double]
  priv boxes_max_y : Array[Double]
  priv boxes_max_z : Array[Double]
  priv boxes_max_t : Array[Double]
  priv child_offset : Array[Int32]
  priv child_count : Array[Int32]
  priv child_indices : Array[Int32]
  priv item_ids : Array[Int32]
  priv node_levels : Array[Int32]
  priv num_items : Int32
  priv num_nodes : Int32
  priv height : Int32
  priv node_capacity : Int32
  priv root_index : Int32
} derive(Eq, Debug, Default)
