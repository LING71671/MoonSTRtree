///|
/// Spatial item representing an input geometry bound and object ID.
pub struct STRItem {
  rect : @geometry.Rect
  id : Int
} derive(Eq, Debug, Default)

///|
/// Constructs a new STRItem.
pub fn STRItem::new(rect : @geometry.Rect, id : Int) -> STRItem {
  STRItem::{ rect, id, }
}

///|
/// Internal or leaf node representation during STR partitioning.
pub struct STRNode {
  rect : @geometry.Rect
  children : Array[Int]
  item_id : Int
} derive(Eq, Debug, Default)

///|
/// Constructs a new STRNode.
pub fn STRNode::new(
  rect : @geometry.Rect,
  children : Array[Int],
  item_id : Int,
) -> STRNode {
  STRNode::{ rect, children, item_id, }
}

///|
/// Returns true if this node represents an original leaf item with valid item_id.
pub fn STRNode::is_leaf_item(self : STRNode) -> Bool {
  self.item_id >= 0
}

///|
/// Result of STR bulk loading hierarchy construction.
pub struct STRBuildResult {
  nodes : Array[STRNode]
  root_index : Int
  height : Int
  num_items : Int
} derive(Eq, Debug, Default)

///|
/// Computes integer square root using Newton's method.
pub fn isqrt(n : Int) -> Int {
  if n <= 0 {
    return 0
  }
  let mut x = n
  let mut y = x / 2 + 1
  while y < x {
    x = y
    y = (x + n / x) / 2
  }
  x
}

///|
/// Computes ceiling division (a / b).
pub fn ceil_div(a : Int, b : Int) -> Int {
  if a <= 0 || b <= 0 {
    0
  } else {
    a / b + (if a % b == 0 { 0 } else { 1 })
  }
}

///|
/// Computes ceiling square root: ceil(sqrt(n)).
pub fn ceil_sqrt(n : Int) -> Int {
  if n <= 0 {
    return 0
  }
  let s = isqrt(n)
  if s * s < n {
    s + 1
  } else {
    s
  }
}

///|
/// Sorts a slice of items [start, end) by center Y coordinate.
fn sort_sub_items_by_y(items : Array[STRItem], start : Int, end : Int) -> Unit {
  let len = end - start
  if len <= 1 {
    return
  }
  let sub = items.mut_view(start~, end~)
  sub.sort_by(fn(a, b) {
    let ay = a.rect.center_y()
    let by = b.rect.center_y()
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
/// Sorts items array in-place into Sort-Tile-Recursive order.
fn sort_str_items(items : Array[STRItem], cap : Int) -> Unit {
  let n = items.length()
  if n <= cap {
    return
  }
  let pages = ceil_div(n, cap)
  let slices = ceil_sqrt(pages)
  let pages_per_slice = ceil_div(pages, slices)
  let slice_capacity = pages_per_slice * cap

  // 1. Sort along X axis center
  items.sort_by(fn(a, b) {
    let ax = a.rect.center_x()
    let bx = b.rect.center_x()
    if ax < bx {
      -1
    } else if ax > bx {
      1
    } else {
      0
    }
  })

  // 2. Sort within each vertical slice along Y axis center
  let mut slice_start = 0
  while slice_start < n {
    let slice_end = if slice_start + slice_capacity < n {
      slice_start + slice_capacity
    } else {
      n
    }
    sort_sub_items_by_y(items, slice_start, slice_end)
    slice_start = slice_end
  }
}

///|
/// Sorts a slice of level node indices [start, end) by center Y coordinate.
fn sort_sub_nodes_by_y(
  all_nodes : Array[STRNode],
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
    let ay = all_nodes[idx_a].rect.center_y()
    let by = all_nodes[idx_b].rect.center_y()
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
/// Sorts level node indices in-place using STR partitioning.
fn sort_level_nodes(
  all_nodes : Array[STRNode],
  level : Array[Int],
  cap : Int,
) -> Unit {
  let n = level.length()
  if n <= cap {
    return
  }
  let pages = ceil_div(n, cap)
  let slices = ceil_sqrt(pages)
  let pages_per_slice = ceil_div(pages, slices)
  let slice_capacity = pages_per_slice * cap

  // 1. Sort along X axis center
  level.sort_by(fn(idx_a, idx_b) {
    let ax = all_nodes[idx_a].rect.center_x()
    let bx = all_nodes[idx_b].rect.center_x()
    if ax < bx {
      -1
    } else if ax > bx {
      1
    } else {
      0
    }
  })

  // 2. Sort within each vertical slice along Y axis center
  let mut slice_start = 0
  while slice_start < n {
    let slice_end = if slice_start + slice_capacity < n {
      slice_start + slice_capacity
    } else {
      n
    }
    sort_sub_nodes_by_y(all_nodes, level, slice_start, slice_end)
    slice_start = slice_end
  }
}

///|
/// Constructs an STR tree hierarchy from items and maximum node capacity.
pub fn pack_str(
  items : Array[STRItem],
  node_capacity? : Int = 16,
) -> STRBuildResult {
  let cap = if node_capacity < 2 { 2 } else { node_capacity }
  let num_items = items.length()
  if num_items == 0 {
    return STRBuildResult::{
      nodes: [],
      root_index: -1,
      height: 0,
      num_items: 0,
    }
  }
  if num_items == 1 {
    let leaf = STRNode::new(items[0].rect, [], items[0].id)
    let root = STRNode::new(items[0].rect, [0], -1)
    return STRBuildResult::{
      nodes: [leaf, root],
      root_index: 1,
      height: 1,
      num_items: 1,
    }
  }

  // Clone items to avoid mutating input array
  let ordered_items = items.copy()
  sort_str_items(ordered_items, cap)

  let all_nodes : Array[STRNode] = []
  let mut current_level : Array[Int] = []

  // Create level 0: leaf items
  for i = 0; i < ordered_items.length(); i = i + 1 {
    let item = ordered_items[i]
    let node_idx = all_nodes.length()
    all_nodes.push(STRNode::new(item.rect, [], item.id))
    current_level.push(node_idx)
  }

  let mut height = 1

  // Build upper levels recursively
  while current_level.length() > 1 {
    let next_level : Array[Int] = []
    let len = current_level.length()
    if len <= cap {
      // Final root node
      let mut union_rect = all_nodes[current_level[0]].rect
      let children : Array[Int] = []
      for i = 0; i < len; i = i + 1 {
        let idx = current_level[i]
        children.push(idx)
        union_rect = union_rect.union(all_nodes[idx].rect)
      }
      let root_idx = all_nodes.length()
      all_nodes.push(STRNode::new(union_rect, children, -1))
      return STRBuildResult::{
        nodes: all_nodes,
        root_index: root_idx,
        height,
        num_items,
      }
    }

    // Sort current_level nodes using STR
    sort_level_nodes(all_nodes, current_level, cap)

    // Group into chunks of capacity
    let mut chunk_start = 0
    while chunk_start < current_level.length() {
      let chunk_end = if chunk_start + cap < current_level.length() {
        chunk_start + cap
      } else {
        current_level.length()
      }
      let mut union_rect = all_nodes[current_level[chunk_start]].rect
      let children : Array[Int] = []
      for i = chunk_start; i < chunk_end; i = i + 1 {
        let idx = current_level[i]
        children.push(idx)
        union_rect = union_rect.union(all_nodes[idx].rect)
      }
      let parent_idx = all_nodes.length()
      all_nodes.push(STRNode::new(union_rect, children, -1))
      next_level.push(parent_idx)
      chunk_start = chunk_end
    }

    current_level = next_level
    height = height + 1
  }

  let root_index = if current_level.is_empty() { -1 } else { current_level[0] }
  STRBuildResult::{ nodes: all_nodes, root_index, height, num_items, }
}
