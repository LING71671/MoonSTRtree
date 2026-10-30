///|
priv struct RawNode4D {
  index : Int32
  level : Int32
  min_x : Double
  min_y : Double
  min_z : Double
  min_t : Double
  max_x : Double
  max_y : Double
  max_z : Double
  max_t : Double
  item_id : Int32
  children : Array[Int32]
}

///|
fn sort_nodes_by_x(nodes : Array[RawNode4D]) -> Unit {
  nodes.sort_by(fn(a, b) {
    let ac = a.min_x * 0.5 + a.max_x * 0.5
    let bc = b.min_x * 0.5 + b.max_x * 0.5
    if ac < bc {
      -1
    } else if ac > bc {
      1
    } else {
      0
    }
  })
}

///|
fn sort_nodes_by_y(nodes : Array[RawNode4D]) -> Unit {
  nodes.sort_by(fn(a, b) {
    let ac = a.min_y * 0.5 + a.max_y * 0.5
    let bc = b.min_y * 0.5 + b.max_y * 0.5
    if ac < bc {
      -1
    } else if ac > bc {
      1
    } else {
      0
    }
  })
}

///|
fn sort_nodes_by_z(nodes : Array[RawNode4D]) -> Unit {
  nodes.sort_by(fn(a, b) {
    let ac = a.min_z * 0.5 + a.max_z * 0.5
    let bc = b.min_z * 0.5 + b.max_z * 0.5
    if ac < bc {
      -1
    } else if ac > bc {
      1
    } else {
      0
    }
  })
}

///|
fn sort_nodes_by_t(nodes : Array[RawNode4D]) -> Unit {
  nodes.sort_by(fn(a, b) {
    let ac = a.min_t * 0.5 + a.max_t * 0.5
    let bc = b.min_t * 0.5 + b.max_t * 0.5
    if ac < bc {
      -1
    } else if ac > bc {
      1
    } else {
      0
    }
  })
}

///|
/// Builds a packed 4D StrTree from an array of (Box4D, ID) pairs and optional node capacity.
pub fn StrTree4D::build(
  items : Array[(@geometry.Box4D, Int32)],
  node_capacity~ : Int32 = 16,
) -> StrTree4D {
  let cap = if node_capacity < 2 { 2 } else { node_capacity }
  let num_items = items.length()

  if num_items == 0 {
    return StrTree4D::{
      boxes_min_x: [],
      boxes_min_y: [],
      boxes_min_z: [],
      boxes_min_t: [],
      boxes_max_x: [],
      boxes_max_y: [],
      boxes_max_z: [],
      boxes_max_t: [],
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

  // 1. Initialize leaf raw nodes
  let all_nodes : Array[RawNode4D] = []
  let mut current_level_indices : Array[Int32] = []

  for i = 0; i < num_items; i = i + 1 {
    let (b, id) = items[i]
    let idx = all_nodes.length()
    all_nodes.push(RawNode4D::{
      index: idx,
      level: 0,
      min_x: b.min_x,
      min_y: b.min_y,
      min_z: b.min_z,
      min_t: b.min_t,
      max_x: b.max_x,
      max_y: b.max_y,
      max_z: b.max_z,
      max_t: b.max_t,
      item_id: id,
      children: [],
    })
    current_level_indices.push(idx)
  }

  let mut tree_height = 1

  // 2. Hierarchical bulk packing loop
  while current_level_indices.length() > 1 {
    let n = current_level_indices.length()
    let parent_level_indices : Array[Int32] = []
    let p_pages = @str.ceil_div(n, cap)
    let sx = if p_pages <= 1 {
      1
    } else {
      let r = @str.isqrt(@str.isqrt(p_pages))
      if r < 1 {
        1
      } else {
        r
      }
    }

    // Extract current level nodes
    let level_nodes : Array[RawNode4D] = []
    for idx in current_level_indices {
      level_nodes.push(all_nodes[idx])
    }

    // Sort by X
    sort_nodes_by_x(level_nodes)

    // Slice along X
    let slice_x_size = @str.ceil_div(n, sx)
    let mut x_start = 0
    while x_start < n {
      let mut x_end = x_start + slice_x_size
      if x_end > n {
        x_end = n
      }
      let x_slice : Array[RawNode4D] = []
      for k = x_start; k < x_end; k = k + 1 {
        x_slice.push(level_nodes[k])
      }

      let nx = x_slice.length()
      let px = @str.ceil_div(nx, cap)
      let sy = if px <= 1 {
        1
      } else {
        let r = @str.icbrt(px)
        if r < 1 {
          1
        } else {
          r
        }
      }

      sort_nodes_by_y(x_slice)
      let slice_y_size = @str.ceil_div(nx, sy)
      let mut y_start = 0
      while y_start < nx {
        let mut y_end = y_start + slice_y_size
        if y_end > nx {
          y_end = nx
        }
        let y_slice : Array[RawNode4D] = []
        for k = y_start; k < y_end; k = k + 1 {
          y_slice.push(x_slice[k])
        }

        let nxy = y_slice.length()
        let pxy = @str.ceil_div(nxy, cap)
        let sz = if pxy <= 1 {
          1
        } else {
          let r = @str.isqrt(pxy)
          if r < 1 {
            1
          } else {
            r
          }
        }

        sort_nodes_by_z(y_slice)
        let slice_z_size = @str.ceil_div(nxy, sz)
        let mut z_start = 0
        while z_start < nxy {
          let mut z_end = z_start + slice_z_size
          if z_end > nxy {
            z_end = nxy
          }
          let z_slice : Array[RawNode4D] = []
          for k = z_start; k < z_end; k = k + 1 {
            z_slice.push(y_slice[k])
          }

          // Sort by T and group into cap
          sort_nodes_by_t(z_slice)
          let mut t_start = 0
          while t_start < z_slice.length() {
            let mut t_end = t_start + cap
            if t_end > z_slice.length() {
              t_end = z_slice.length()
            }

            let mut min_x = z_slice[t_start].min_x
            let mut min_y = z_slice[t_start].min_y
            let mut min_z = z_slice[t_start].min_z
            let mut min_t = z_slice[t_start].min_t
            let mut max_x = z_slice[t_start].max_x
            let mut max_y = z_slice[t_start].max_y
            let mut max_z = z_slice[t_start].max_z
            let mut max_t = z_slice[t_start].max_t
            let ch_indices : Array[Int32] = []

            for k = t_start; k < t_end; k = k + 1 {
              let child_node = z_slice[k]
              if child_node.min_x < min_x {
                min_x = child_node.min_x
              }
              if child_node.min_y < min_y {
                min_y = child_node.min_y
              }
              if child_node.min_z < min_z {
                min_z = child_node.min_z
              }
              if child_node.min_t < min_t {
                min_t = child_node.min_t
              }
              if child_node.max_x > max_x {
                max_x = child_node.max_x
              }
              if child_node.max_y > max_y {
                max_y = child_node.max_y
              }
              if child_node.max_z > max_z {
                max_z = child_node.max_z
              }
              if child_node.max_t > max_t {
                max_t = child_node.max_t
              }

              // Node identity survives sorting even when geometry and IDs tie.
              ch_indices.push(child_node.index)
            }

            let parent_idx = all_nodes.length()
            all_nodes.push(RawNode4D::{
              index: parent_idx,
              level: tree_height,
              min_x,
              min_y,
              min_z,
              min_t,
              max_x,
              max_y,
              max_z,
              max_t,
              item_id: -1,
              children: ch_indices,
            })
            parent_level_indices.push(parent_idx)

            t_start = t_end
          }

          z_start = z_end
        }

        y_start = y_end
      }

      x_start = x_end
    }

    current_level_indices = parent_level_indices
    tree_height = tree_height + 1
  }

  let root_index = if current_level_indices.is_empty() {
    -1
  } else {
    current_level_indices[0]
  }

  // 3. Flatten raw nodes into flat contiguous arrays
  let total_nodes = all_nodes.length()
  let boxes_min_x = Array::make(total_nodes, 0.0)
  let boxes_min_y = Array::make(total_nodes, 0.0)
  let boxes_min_z = Array::make(total_nodes, 0.0)
  let boxes_min_t = Array::make(total_nodes, 0.0)
  let boxes_max_x = Array::make(total_nodes, 0.0)
  let boxes_max_y = Array::make(total_nodes, 0.0)
  let boxes_max_z = Array::make(total_nodes, 0.0)
  let boxes_max_t = Array::make(total_nodes, 0.0)
  let child_offset = Array::make(total_nodes, 0)
  let child_count = Array::make(total_nodes, 0)
  let item_ids = Array::make(total_nodes, -1)
  let node_levels = Array::make(total_nodes, 0)
  let child_indices_list : Array[Int32] = []

  for i = 0; i < total_nodes; i = i + 1 {
    let node = all_nodes[i]
    boxes_min_x[i] = node.min_x
    boxes_min_y[i] = node.min_y
    boxes_min_z[i] = node.min_z
    boxes_min_t[i] = node.min_t
    boxes_max_x[i] = node.max_x
    boxes_max_y[i] = node.max_y
    boxes_max_z[i] = node.max_z
    boxes_max_t[i] = node.max_t
    item_ids[i] = node.item_id
    node_levels[i] = node.level
    child_offset[i] = child_indices_list.length()
    child_count[i] = node.children.length()
    for ch in node.children {
      child_indices_list.push(ch)
    }
  }

  StrTree4D::{
    boxes_min_x,
    boxes_min_y,
    boxes_min_z,
    boxes_min_t,
    boxes_max_x,
    boxes_max_y,
    boxes_max_z,
    boxes_max_t,
    child_offset,
    child_count,
    child_indices: child_indices_list,
    item_ids,
    node_levels,
    num_items,
    num_nodes: total_nodes,
    height: tree_height,
    node_capacity: cap,
    root_index,
  }
}
