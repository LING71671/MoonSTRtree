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
  boxes_min_x : Array[Double]
  boxes_min_y : Array[Double]
  boxes_min_z : Array[Double]
  boxes_min_t : Array[Double]
  boxes_max_x : Array[Double]
  boxes_max_y : Array[Double]
  boxes_max_z : Array[Double]
  boxes_max_t : Array[Double]
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
fn sqrt_4d(val : Double) -> Double {
  if val <= 0.0 {
    return 0.0
  }
  let mut x = val
  for i = 0; i < 20; i = i + 1 {
    x = 0.5 * (x + val / x)
  }
  x
}

///|
fn cbrt_4d(val : Double) -> Double {
  if val <= 0.0 {
    return 0.0
  }
  let mut x = val
  for i = 0; i < 20; i = i + 1 {
    x = (2.0 * x + val / (x * x)) / 3.0
  }
  x
}

///|
fn fourth_root_4d(val : Double) -> Double {
  sqrt_4d(sqrt_4d(val))
}

///|
priv struct RawNode4D {
  min_x : Double
  min_y : Double
  min_z : Double
  min_t : Double
  max_x : Double
  max_y : Double
  max_z : Double
  max_t : Double
  item_id : Int
  children : Array[Int]
}

///|
fn sort_nodes_by_x(nodes : Array[RawNode4D]) -> Unit {
  for i = 0; i < nodes.length(); i = i + 1 {
    for j = i + 1; j < nodes.length(); j = j + 1 {
      let cx_i = (nodes[i].min_x + nodes[i].max_x) * 0.5
      let cx_j = (nodes[j].min_x + nodes[j].max_x) * 0.5
      if cx_j < cx_i {
        let tmp = nodes[i]
        nodes[i] = nodes[j]
        nodes[j] = tmp
      }
    }
  }
}

///|
fn sort_nodes_by_y(nodes : Array[RawNode4D]) -> Unit {
  for i = 0; i < nodes.length(); i = i + 1 {
    for j = i + 1; j < nodes.length(); j = j + 1 {
      let cy_i = (nodes[i].min_y + nodes[i].max_y) * 0.5
      let cy_j = (nodes[j].min_y + nodes[j].max_y) * 0.5
      if cy_j < cy_i {
        let tmp = nodes[i]
        nodes[i] = nodes[j]
        nodes[j] = tmp
      }
    }
  }
}

///|
fn sort_nodes_by_z(nodes : Array[RawNode4D]) -> Unit {
  for i = 0; i < nodes.length(); i = i + 1 {
    for j = i + 1; j < nodes.length(); j = j + 1 {
      let cz_i = (nodes[i].min_z + nodes[i].max_z) * 0.5
      let cz_j = (nodes[j].min_z + nodes[j].max_z) * 0.5
      if cz_j < cz_i {
        let tmp = nodes[i]
        nodes[i] = nodes[j]
        nodes[j] = tmp
      }
    }
  }
}

///|
fn sort_nodes_by_t(nodes : Array[RawNode4D]) -> Unit {
  for i = 0; i < nodes.length(); i = i + 1 {
    for j = i + 1; j < nodes.length(); j = j + 1 {
      let ct_i = (nodes[i].min_t + nodes[i].max_t) * 0.5
      let ct_j = (nodes[j].min_t + nodes[j].max_t) * 0.5
      if ct_j < ct_i {
        let tmp = nodes[i]
        nodes[i] = nodes[j]
        nodes[j] = tmp
      }
    }
  }
}

///|
/// Builds a packed 4D StrTree from an array of (Box4D, ID) pairs and optional node capacity.
pub fn StrTree4D::build(
  items : Array[(@geometry.Box4D, Int)],
  node_capacity? : Int = 16,
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
  let mut current_level_indices : Array[Int] = []

  for i = 0; i < num_items; i = i + 1 {
    let (b, id) = items[i]
    let idx = all_nodes.length()
    all_nodes.push(RawNode4D::{
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
    let parent_level_indices : Array[Int] = []
    let p_pages = (n + cap - 1) / cap
    let sx = if p_pages <= 1 {
      1
    } else {
      let r = fourth_root_4d(p_pages.to_double()).to_int()
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
    let slice_x_size = (n + sx - 1) / sx
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
      let px = (nx + cap - 1) / cap
      let sy = if px <= 1 {
        1
      } else {
        let r = cbrt_4d(px.to_double()).to_int()
        if r < 1 {
          1
        } else {
          r
        }
      }

      sort_nodes_by_y(x_slice)
      let slice_y_size = (nx + sy - 1) / sy
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
        let pxy = (nxy + cap - 1) / cap
        let sz = if pxy <= 1 {
          1
        } else {
          let r = sqrt_4d(pxy.to_double()).to_int()
          if r < 1 {
            1
          } else {
            r
          }
        }

        sort_nodes_by_z(y_slice)
        let slice_z_size = (nxy + sz - 1) / sz
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
            let ch_indices : Array[Int] = []

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

              // Find index of this child node in all_nodes
              for a = 0; a < all_nodes.length(); a = a + 1 {
                if all_nodes[a].item_id == child_node.item_id &&
                  all_nodes[a].min_x == child_node.min_x &&
                  all_nodes[a].min_y == child_node.min_y &&
                  all_nodes[a].min_z == child_node.min_z &&
                  all_nodes[a].min_t == child_node.min_t {
                  ch_indices.push(a)
                  break
                }
              }
            }

            let parent_idx = all_nodes.length()
            all_nodes.push(RawNode4D::{
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
  let child_indices_list : Array[Int] = []

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

///|
/// Performs 4D range intersection query using iterative stack DFS traversal.
pub fn StrTree4D::query(
  self : StrTree4D,
  search_box : @geometry.Box4D,
) -> Array[Int] {
  if self.root_index < 0 || self.num_items == 0 {
    return []
  }

  let root = self.root_index
  if search_box.max_x < self.boxes_min_x[root] ||
    search_box.min_x > self.boxes_max_x[root] ||
    search_box.max_y < self.boxes_min_y[root] ||
    search_box.min_y > self.boxes_max_y[root] ||
    search_box.max_z < self.boxes_min_z[root] ||
    search_box.min_z > self.boxes_max_z[root] ||
    search_box.max_t < self.boxes_min_t[root] ||
    search_box.min_t > self.boxes_max_t[root] {
    return []
  }

  let results : Array[Int] = []
  let stack : Array[Int] = [root]

  while !stack.is_empty() {
    let curr = stack.pop().unwrap()
    let count = self.child_count[curr]
    if count == 0 {
      let id = self.item_ids[curr]
      if id >= 0 {
        results.push(id)
      }
    } else {
      let offset = self.child_offset[curr]
      for i = 0; i < count; i = i + 1 {
        let child = self.child_indices[offset + i]
        if !(search_box.max_x < self.boxes_min_x[child] ||
          search_box.min_x > self.boxes_max_x[child] ||
          search_box.max_y < self.boxes_min_y[child] ||
          search_box.min_y > self.boxes_max_y[child] ||
          search_box.max_z < self.boxes_min_z[child] ||
          search_box.min_z > self.boxes_max_z[child] ||
          search_box.max_t < self.boxes_min_t[child] ||
          search_box.min_t > self.boxes_max_t[child]) {
          stack.push(child)
        }
      }
    }
  }

  results
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
  let search_box = @geometry.Box4D::from_point(x, y, z, t)
  self.query(search_box)
}

///|
/// Performs zero-allocation count of items intersecting a 4D search box.
pub fn StrTree4D::query_count(
  self : StrTree4D,
  search_box : @geometry.Box4D,
) -> Int {
  if self.root_index < 0 || self.num_items == 0 {
    return 0
  }

  let root = self.root_index
  if search_box.max_x < self.boxes_min_x[root] ||
    search_box.min_x > self.boxes_max_x[root] ||
    search_box.max_y < self.boxes_min_y[root] ||
    search_box.min_y > self.boxes_max_y[root] ||
    search_box.max_z < self.boxes_min_z[root] ||
    search_box.min_z > self.boxes_max_z[root] ||
    search_box.max_t < self.boxes_min_t[root] ||
    search_box.min_t > self.boxes_max_t[root] {
    return 0
  }

  let mut count = 0
  let stack : Array[Int] = [root]

  while !stack.is_empty() {
    let curr = stack.pop().unwrap()
    let c_count = self.child_count[curr]
    if c_count == 0 {
      let id = self.item_ids[curr]
      if id >= 0 {
        count = count + 1
      }
    } else {
      let offset = self.child_offset[curr]
      for i = 0; i < c_count; i = i + 1 {
        let child = self.child_indices[offset + i]
        if !(search_box.max_x < self.boxes_min_x[child] ||
          search_box.min_x > self.boxes_max_x[child] ||
          search_box.max_y < self.boxes_min_y[child] ||
          search_box.min_y > self.boxes_max_y[child] ||
          search_box.max_z < self.boxes_min_z[child] ||
          search_box.min_z > self.boxes_max_z[child] ||
          search_box.max_t < self.boxes_min_t[child] ||
          search_box.min_t > self.boxes_max_t[child]) {
          stack.push(child)
        }
      }
    }
  }

  count
}

///|
/// Queries 3D spatial region at specific time instant t.
pub fn StrTree4D::query_time_slice(
  self : StrTree4D,
  t : Double,
  box_3d : @geometry.Box3D,
) -> Array[Int] {
  let search_box = @geometry.Box4D::new(
    box_3d.min_x,
    box_3d.min_y,
    box_3d.min_z,
    t,
    box_3d.max_x,
    box_3d.max_y,
    box_3d.max_z,
    t,
  )
  self.query(search_box)
}

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
  let fill_factor = if leaves == 0 {
    1.0
  } else {
    self.num_items.to_double() / (leaves * self.node_capacity).to_double()
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
