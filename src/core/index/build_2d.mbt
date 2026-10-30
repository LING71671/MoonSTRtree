///|
/// Constructs directly in SoA storage, avoiding temporary leaf/parent objects.
fn pack_arrays_2d(
  min_x : Array[Double],
  min_y : Array[Double],
  max_x : Array[Double],
  max_y : Array[Double],
  ids : Array[Int32],
  capacity : Int32,
) -> StrTree {
  let items = ids.length()
  let mut contiguous_leaves = items > 0
  for id in ids {
    if id < 0 {
      contiguous_leaves = false
    }
  }
  let nodes = packed_node_count(items, capacity)
  let offsets = Array::make(nodes, 0)
  let counts = Array::make(nodes, 0)
  let edges = Array::make((nodes - 1).max(0), 0)
  let mut edge_cursor = 0
  let mut node_cursor = items
  let centers_x = Array::makei(items, fn(i) {
    min_x.unsafe_get(i) * 0.5 + max_x.unsafe_get(i) * 0.5
  })
  let centers_y = Array::makei(items, fn(i) {
    min_y.unsafe_get(i) * 0.5 + max_y.unsafe_get(i) * 0.5
  })
  let mut level = Array::makei(items, fn(i) { i })
  @str.partition_str_2d(level, centers_x, centers_y, capacity)
  // Every output slot is sized once. The only callers create equally sized
  // coordinate/ID columns, and level values are verified permutations or
  // indices of already initialized parent slots.
  min_x.resize(nodes, 0.0)
  min_y.resize(nodes, 0.0)
  max_x.resize(nodes, 0.0)
  max_y.resize(nodes, 0.0)
  ids.resize(nodes, -1)
  centers_x.resize(nodes, 0.0)
  centers_y.resize(nodes, 0.0)
  let mut height = 0
  let mut root = -1
  while !level.is_empty() {
    if height > 0 {
      @str.partition_str_2d(level, centers_x, centers_y, capacity)
    }
    let next = Array::make(@str.ceil_div(level.length(), capacity), 0)
    let mut page = 0
    let mut start = 0
    while start < level.length() {
      let end = (start + capacity).min(level.length())
      let first = level.unsafe_get(start)
      let mut x1 = min_x.unsafe_get(first)
      let mut y1 = min_y.unsafe_get(first)
      let mut x2 = max_x.unsafe_get(first)
      let mut y2 = max_y.unsafe_get(first)
      let offset = edge_cursor
      for i = start; i < end; i = i + 1 {
        let child = level.unsafe_get(i)
        x1 = x1.min(min_x.unsafe_get(child))
        y1 = y1.min(min_y.unsafe_get(child))
        x2 = x2.max(max_x.unsafe_get(child))
        y2 = y2.max(max_y.unsafe_get(child))
        edges.unsafe_set(edge_cursor, child)
        edge_cursor = edge_cursor + 1
      }
      let parent = node_cursor
      min_x.unsafe_set(parent, x1)
      min_y.unsafe_set(parent, y1)
      max_x.unsafe_set(parent, x2)
      max_y.unsafe_set(parent, y2)
      ids.unsafe_set(parent, -1)
      offsets.unsafe_set(parent, offset)
      counts.unsafe_set(parent, end - start)
      centers_x.unsafe_set(parent, x1 * 0.5 + x2 * 0.5)
      centers_y.unsafe_set(parent, y1 * 0.5 + y2 * 0.5)
      next.unsafe_set(page, parent)
      page = page + 1
      node_cursor = node_cursor + 1
      start = end
    }
    height = height + 1
    if next.length() == 1 {
      root = next[0]
      break
    }
    level = next
  }
  let tree = StrTree::{
    boxes_min_x: min_x,
    boxes_min_y: min_y,
    boxes_max_x: max_x,
    boxes_max_y: max_y,
    child_offset: offsets,
    child_count: counts,
    child_indices: edges,
    item_ids: ids,
    root_index: root,
    node_capacity: capacity,
    num_items: items,
    height,
    contiguous_leaves,
  }
  tree.order_leaves_depth_first()
  tree
}

///|
/// Builds from host coordinates with sequential IDs without per-item geometry objects.
pub fn StrTree::build_coordinates(
  coordinates : Array[Double],
  node_capacity~ : Int32 = 16,
) -> StrTree {
  guard coordinates.length() % 4 == 0 else {
    abort("Expected four coordinates per rectangle")
  }
  let count = coordinates.length() / 4
  pack_arrays_2d(
    Array::makei(count, fn(i) {
      coordinates.unsafe_get(i * 4).min(coordinates.unsafe_get(i * 4 + 2))
    }),
    Array::makei(count, fn(i) {
      coordinates.unsafe_get(i * 4 + 1).min(coordinates.unsafe_get(i * 4 + 3))
    }),
    Array::makei(count, fn(i) {
      coordinates.unsafe_get(i * 4).max(coordinates.unsafe_get(i * 4 + 2))
    }),
    Array::makei(count, fn(i) {
      coordinates.unsafe_get(i * 4 + 1).max(coordinates.unsafe_get(i * 4 + 3))
    }),
    Array::makei(count, fn(i) { i }),
    node_capacity.max(2),
  )
}

///|
fn packed_node_count(items : Int32, capacity : Int32) -> Int32 {
  let mut total = items
  let mut level = items
  while level > 0 {
    level = @str.ceil_div(level, capacity)
    guard level <= 2147483647 - total else {
      abort("Index exceeds supported node count")
    }
    total = total + level
    if level == 1 {
      break
    }
  }
  total
}

///|
/// Arrange leaves in depth-first order so every subtree occupies an ID interval.
/// Called only while constructing an otherwise complete, privately owned tree.
fn StrTree::order_leaves_depth_first(self : StrTree) -> Unit {
  if self.num_items == 0 {
    return
  }
  let order = Array::make(self.num_items, 0)
  let stack : Array[Int32] = [self.root_index]
  let mut leaf = 0
  while !stack.is_empty() {
    let node = stack.unsafe_pop()
    let offset = self.child_offset.unsafe_get(node)
    let count = self.child_count.unsafe_get(node)
    let first = self.child_indices.unsafe_get(offset)
    if first < self.num_items {
      for i = offset; i < offset + count; i = i + 1 {
        order.unsafe_set(leaf, self.child_indices.unsafe_get(i))
        self.child_indices.unsafe_set(i, leaf)
        leaf = leaf + 1
      }
    } else {
      let mut i = offset + count
      while i > offset {
        i = i - 1
        stack.push(self.child_indices.unsafe_get(i))
      }
    }
  }
  let old_x1 = self.boxes_min_x.copy()
  let old_y1 = self.boxes_min_y.copy()
  let old_x2 = self.boxes_max_x.copy()
  let old_y2 = self.boxes_max_y.copy()
  let old_ids = self.item_ids.copy()
  for i = 0; i < self.num_items; i = i + 1 {
    let source = order.unsafe_get(i)
    self.boxes_min_x.unsafe_set(i, old_x1.unsafe_get(source))
    self.boxes_min_y.unsafe_set(i, old_y1.unsafe_get(source))
    self.boxes_max_x.unsafe_set(i, old_x2.unsafe_get(source))
    self.boxes_max_y.unsafe_set(i, old_y2.unsafe_get(source))
    self.item_ids.unsafe_set(i, old_ids.unsafe_get(source))
  }
}
