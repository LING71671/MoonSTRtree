///|
/// Spatial 3D item representing an input Box3D and object ID.
pub struct STRItem3D {
  box : @geometry.Box3D
  id : Int
} derive(Eq, Debug, Default)

///|
/// Constructs a new STRItem3D.
pub fn STRItem3D::new(box : @geometry.Box3D, id : Int) -> STRItem3D {
  STRItem3D::{ box, id, }
}

///|
/// Internal or leaf node representation during 3D STR partitioning.
pub struct STRNode3D {
  box : @geometry.Box3D
  children : Array[Int]
  item_id : Int
} derive(Eq, Debug, Default)

///|
/// Constructs a new STRNode3D.
pub fn STRNode3D::new(
  box : @geometry.Box3D,
  children : Array[Int],
  item_id : Int,
) -> STRNode3D {
  STRNode3D::{ box, children, item_id, }
}

///|
/// Returns true if this node represents an original leaf item with valid item_id.
pub fn STRNode3D::is_leaf_item(self : STRNode3D) -> Bool {
  self.item_id >= 0
}

///|
/// Result of 3D STR bulk loading hierarchy construction.
pub struct STRBuildResult3D {
  nodes : Array[STRNode3D]
  root_index : Int
  height : Int
  num_items : Int
} derive(Eq, Debug, Default)

///|
/// Computes integer cube root for non-negative integers.
pub fn icbrt(n : Int) -> Int {
  if n <= 0 {
    return 0
  }
  let mut low = 0
  let mut high = if n < 1290 { n } else { 1290 }
  while low < high {
    let mid = low + (high - low + 1) / 2
    if mid <= n / mid / mid {
      low = mid
    } else {
      high = mid - 1
    }
  }
  low
}

///|
/// Computes ceiling cube root: ceil(n^(1/3)).
pub fn ceil_cbrt(n : Int) -> Int {
  if n <= 0 {
    return 0
  }
  let r = icbrt(n)
  if r * r * r < n {
    r + 1
  } else {
    r
  }
}

///|
/// Sorts a slice of items [start, end) by center Z coordinate.
fn sort_sub_items_by_z(
  items : Array[STRItem3D],
  start : Int,
  end : Int,
) -> Unit {
  let len = end - start
  if len <= 1 {
    return
  }
  let sub = items.mut_view(start~, end~)
  sub.sort_by(fn(a, b) {
    let az = a.box.center_z()
    let bz = b.box.center_z()
    if az < bz {
      -1
    } else if az > bz {
      1
    } else {
      0
    }
  })
}

///|
/// Sorts a slice of items [start, end) by center Y coordinate.
fn sort_sub_items_by_y_3d(
  items : Array[STRItem3D],
  start : Int,
  end : Int,
) -> Unit {
  let len = end - start
  if len <= 1 {
    return
  }
  let sub = items.mut_view(start~, end~)
  sub.sort_by(fn(a, b) {
    let ay = a.box.center_y()
    let by = b.box.center_y()
    if ay < by {
      -1
    } else if ay > by {
      1
    } else {
      0
    }
  })
}

///|
/// Sorts items array in-place into 3D Sort-Tile-Recursive order.
fn sort_str3d_items(items : Array[STRItem3D], cap : Int) -> Unit {
  let n = items.length()
  if n <= cap {
    return
  }
  let pages = ceil_div(n, cap)
  let slabs = ceil_cbrt(pages)
  let pages_per_slab = ceil_div(pages, slabs)
  let slab_capacity = pages_per_slab * cap

  // 1. Sort along X axis center
  items.sort_by(fn(a, b) {
    let ax = a.box.center_x()
    let bx = b.box.center_x()
    if ax < bx {
      -1
    } else if ax > bx {
      1
    } else {
      0
    }
  })

  // 2. For each X slab, sort along Y, then along Z
  let mut slab_start = 0
  while slab_start < n {
    let slab_end = if slab_start + slab_capacity < n {
      slab_start + slab_capacity
    } else {
      n
    }
    let slab_len = slab_end - slab_start
    let slab_pages = ceil_div(slab_len, cap)
    let cols = ceil_sqrt(slab_pages)
    let pages_per_col = ceil_div(slab_pages, cols)
    let col_capacity = pages_per_col * cap

    sort_sub_items_by_y_3d(items, slab_start, slab_end)

    let mut col_start = slab_start
    while col_start < slab_end {
      let col_end = if col_start + col_capacity < slab_end {
        col_start + col_capacity
      } else {
        slab_end
      }
      sort_sub_items_by_z(items, col_start, col_end)
      col_start = col_end
    }

    slab_start = slab_end
  }
}

///|
/// Sorts a slice of level node indices [start, end) by center Z coordinate.
fn sort_sub_nodes_by_z(
  all_nodes : Array[STRNode3D],
  level : Array[Int],
  start : Int,
  end : Int,
) -> Unit {
  let len = end - start
  if len <= 1 {
    return
  }
  let sub = level.mut_view(start~, end~)
  sub.sort_by(fn(idx_a, idx_b) {
    let az = all_nodes[idx_a].box.center_z()
    let bz = all_nodes[idx_b].box.center_z()
    if az < bz {
      -1
    } else if az > bz {
      1
    } else {
      0
    }
  })
}

///|
/// Sorts a slice of level node indices [start, end) by center Y coordinate.
fn sort_sub_nodes_by_y_3d(
  all_nodes : Array[STRNode3D],
  level : Array[Int],
  start : Int,
  end : Int,
) -> Unit {
  let len = end - start
  if len <= 1 {
    return
  }
  let sub = level.mut_view(start~, end~)
  sub.sort_by(fn(idx_a, idx_b) {
    let ay = all_nodes[idx_a].box.center_y()
    let by = all_nodes[idx_b].box.center_y()
    if ay < by {
      -1
    } else if ay > by {
      1
    } else {
      0
    }
  })
}

///|
/// Sorts level node indices in-place using 3D STR partitioning.
fn sort_level3d_nodes(
  all_nodes : Array[STRNode3D],
  level : Array[Int],
  cap : Int,
) -> Unit {
  let n = level.length()
  if n <= cap {
    return
  }
  let pages = ceil_div(n, cap)
  let slabs = ceil_cbrt(pages)
  let pages_per_slab = ceil_div(pages, slabs)
  let slab_capacity = pages_per_slab * cap

  // 1. Sort along X axis center
  level.sort_by(fn(idx_a, idx_b) {
    let ax = all_nodes[idx_a].box.center_x()
    let bx = all_nodes[idx_b].box.center_x()
    if ax < bx {
      -1
    } else if ax > bx {
      1
    } else {
      0
    }
  })

  // 2. For each X slab, sort along Y, then along Z
  let mut slab_start = 0
  while slab_start < n {
    let slab_end = if slab_start + slab_capacity < n {
      slab_start + slab_capacity
    } else {
      n
    }
    let slab_len = slab_end - slab_start
    let slab_pages = ceil_div(slab_len, cap)
    let cols = ceil_sqrt(slab_pages)
    let pages_per_col = ceil_div(slab_pages, cols)
    let col_capacity = pages_per_col * cap

    sort_sub_nodes_by_y_3d(all_nodes, level, slab_start, slab_end)

    let mut col_start = slab_start
    while col_start < slab_end {
      let col_end = if col_start + col_capacity < slab_end {
        col_start + col_capacity
      } else {
        slab_end
      }
      sort_sub_nodes_by_z(all_nodes, level, col_start, col_end)
      col_start = col_end
    }

    slab_start = slab_end
  }
}

///|
/// Constructs a 3D STR tree hierarchy from items and maximum node capacity.
pub fn pack_str3d(
  items : Array[STRItem3D],
  node_capacity? : Int = 16,
) -> STRBuildResult3D {
  let cap = if node_capacity < 2 { 2 } else { node_capacity }
  let num_items = items.length()
  if num_items == 0 {
    return STRBuildResult3D::{
      nodes: [],
      root_index: -1,
      height: 0,
      num_items: 0,
    }
  }
  if num_items == 1 {
    let leaf = STRNode3D::new(items[0].box, [], items[0].id)
    let root = STRNode3D::new(items[0].box, [0], -1)
    return STRBuildResult3D::{
      nodes: [leaf, root],
      root_index: 1,
      height: 1,
      num_items: 1,
    }
  }

  let ordered_items = items.copy()
  sort_str3d_items(ordered_items, cap)

  let all_nodes : Array[STRNode3D] = []
  let mut current_level : Array[Int] = []

  // Create level 0: leaf items
  for i = 0; i < ordered_items.length(); i = i + 1 {
    let item = ordered_items[i]
    let node_idx = all_nodes.length()
    all_nodes.push(STRNode3D::new(item.box, [], item.id))
    current_level.push(node_idx)
  }

  let mut height = 1

  // Build upper levels recursively
  while current_level.length() > 1 {
    let next_level : Array[Int] = []
    let len = current_level.length()
    if len <= cap {
      // Final root node
      let mut union_box = all_nodes[current_level[0]].box
      let children : Array[Int] = []
      for i = 0; i < len; i = i + 1 {
        let idx = current_level[i]
        children.push(idx)
        union_box = union_box.union(all_nodes[idx].box)
      }
      let root_idx = all_nodes.length()
      all_nodes.push(STRNode3D::new(union_box, children, -1))
      return STRBuildResult3D::{
        nodes: all_nodes,
        root_index: root_idx,
        height,
        num_items,
      }
    }

    sort_level3d_nodes(all_nodes, current_level, cap)

    let mut chunk_start = 0
    while chunk_start < current_level.length() {
      let chunk_end = if chunk_start + cap < current_level.length() {
        chunk_start + cap
      } else {
        current_level.length()
      }
      let mut union_box = all_nodes[current_level[chunk_start]].box
      let children : Array[Int] = []
      for i = chunk_start; i < chunk_end; i = i + 1 {
        let idx = current_level[i]
        children.push(idx)
        union_box = union_box.union(all_nodes[idx].box)
      }
      let parent_idx = all_nodes.length()
      all_nodes.push(STRNode3D::new(union_box, children, -1))
      next_level.push(parent_idx)
      chunk_start = chunk_end
    }

    current_level = next_level
    height = height + 1
  }

  let root_index = if current_level.is_empty() { -1 } else { current_level[0] }
  STRBuildResult3D::{ nodes: all_nodes, root_index, height, num_items, }
}
