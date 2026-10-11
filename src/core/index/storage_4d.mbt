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
  priv child_offset : Array[Int]
  priv child_count : Array[Int]
  priv child_indices : Array[Int]
  priv item_ids : Array[Int]
  priv node_levels : Array[Int]
  priv num_items : Int
  priv num_nodes : Int
  priv height : Int
  priv node_capacity : Int
  priv root_index : Int
} derive(Eq, Debug, Default)
