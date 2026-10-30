///|
/// Packed 3D spatial index tree with contiguous flat array storage.
pub struct StrTree3D {
  priv boxes_min_x : Array[Double]
  priv boxes_min_y : Array[Double]
  priv boxes_min_z : Array[Double]
  priv boxes_max_x : Array[Double]
  priv boxes_max_y : Array[Double]
  priv boxes_max_z : Array[Double]
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

///|
/// Builds a packed 3D StrTree from an array of (Box3D, ID) pairs and optional node capacity.
pub fn StrTree3D::build(
  items : Array[(@geometry.Box3D, Int32)],
  node_capacity~ : Int32 = 16,
) -> StrTree3D {
  let cap = if node_capacity < 2 { 2 } else { node_capacity }
  let num_items = items.length()

  if num_items == 0 {
    return StrTree3D::{
      boxes_min_x: [],
      boxes_min_y: [],
      boxes_min_z: [],
      boxes_max_x: [],
      boxes_max_y: [],
      boxes_max_z: [],
      child_offset: [],
      child_count: [],
      child_indices: [],
      item_ids: [],
      node_levels: [],
      num_items: 0,
      num_nodes: 0,
      height: 0,
      node_capacity: cap,
      root_index: -1,
    }
  }

  let str_items : Array[@str.STRItem3D] = []
  for i = 0; i < num_items; i = i + 1 {
    let (box, id) = items[i]
    str_items.push(@str.STRItem3D::new(box, id))
  }

  let build_result = @str.pack_str3d(str_items, node_capacity=cap)
  let raw_nodes = build_result.nodes
  let total_nodes = raw_nodes.length()

  let boxes_min_x = Array::make(total_nodes, 0.0)
  let boxes_min_y = Array::make(total_nodes, 0.0)
  let boxes_min_z = Array::make(total_nodes, 0.0)
  let boxes_max_x = Array::make(total_nodes, 0.0)
  let boxes_max_y = Array::make(total_nodes, 0.0)
  let boxes_max_z = Array::make(total_nodes, 0.0)
  let child_offset = Array::make(total_nodes, 0)
  let child_count = Array::make(total_nodes, 0)
  let item_ids = Array::make(total_nodes, -1)
  let node_levels = Array::make(total_nodes, 0)

  let child_indices_list : Array[Int32] = []

  // Assign levels using BFS queue
  let node_level_arr = Array::make(total_nodes, 0)
  let queue : Array[Int32] = []
  if build_result.root_index >= 0 {
    queue.push(build_result.root_index)
    node_level_arr[build_result.root_index] = build_result.height
  }

  let mut head = 0
  while head < queue.length() {
    let curr = queue[head]
    head = head + 1
    let parent_level = node_level_arr[curr]
    let c_list = raw_nodes[curr].children
    for i = 0; i < c_list.length(); i = i + 1 {
      let child = c_list[i]
      node_level_arr[child] = parent_level - 1
      queue.push(child)
    }
  }

  for i = 0; i < total_nodes; i = i + 1 {
    let node = raw_nodes[i]
    boxes_min_x[i] = node.box.min_x
    boxes_min_y[i] = node.box.min_y
    boxes_min_z[i] = node.box.min_z
    boxes_max_x[i] = node.box.max_x
    boxes_max_y[i] = node.box.max_y
    boxes_max_z[i] = node.box.max_z
    item_ids[i] = node.item_id
    node_levels[i] = node_level_arr[i]

    let num_c = node.children.length()
    child_count[i] = num_c
    if num_c > 0 {
      child_offset[i] = child_indices_list.length()
      for c = 0; c < num_c; c = c + 1 {
        child_indices_list.push(node.children[c])
      }
    } else {
      child_offset[i] = 0
    }
  }

  let child_indices = Array::make(child_indices_list.length(), 0)
  for i = 0; i < child_indices_list.length(); i = i + 1 {
    child_indices[i] = child_indices_list[i]
  }

  StrTree3D::{
    boxes_min_x,
    boxes_min_y,
    boxes_min_z,
    boxes_max_x,
    boxes_max_y,
    boxes_max_z,
    child_offset,
    child_count,
    child_indices,
    item_ids,
    node_levels,
    num_items,
    num_nodes: total_nodes,
    height: build_result.height,
    node_capacity: cap,
    root_index: build_result.root_index,
  }
}
