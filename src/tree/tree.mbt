///|
/// Packed 2D spatial index tree with contiguous flat array storage.
pub struct StrTree {
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
/// Builds a packed StrTree from an array of (Rect, ID) pairs and node capacity.
pub fn StrTree::build(
  items : Array[(@geometry.Rect, Int)],
  node_capacity? : Int = 16,
) -> StrTree {
  let cap = if node_capacity < 2 { 2 } else { node_capacity }
  let str_items : Array[@str.STRItem] = []
  for i = 0; i < items.length(); i = i + 1 {
    let (rect, id) = items[i]
    str_items.push(@str.STRItem::new(rect, id))
  }

  let res = @str.pack_str(str_items, node_capacity=cap)
  let num_nodes = res.nodes.length()

  let boxes_min_x = Array::make(num_nodes, 0.0)
  let boxes_min_y = Array::make(num_nodes, 0.0)
  let boxes_max_x = Array::make(num_nodes, 0.0)
  let boxes_max_y = Array::make(num_nodes, 0.0)
  let child_offset = Array::make(num_nodes, 0)
  let child_count = Array::make(num_nodes, 0)
  let item_ids = Array::make(num_nodes, -1)
  let child_indices : Array[Int] = []

  for i = 0; i < num_nodes; i = i + 1 {
    let node = res.nodes[i]
    boxes_min_x[i] = node.rect.min_x
    boxes_min_y[i] = node.rect.min_y
    boxes_max_x[i] = node.rect.max_x
    boxes_max_y[i] = node.rect.max_y
    item_ids[i] = node.item_id

    child_offset[i] = child_indices.length()
    child_count[i] = node.children.length()
    for c = 0; c < node.children.length(); c = c + 1 {
      child_indices.push(node.children[c])
    }
  }

  StrTree::{
    boxes_min_x,
    boxes_min_y,
    boxes_max_x,
    boxes_max_y,
    child_offset,
    child_count,
    child_indices,
    item_ids,
    root_index: res.root_index,
    node_capacity: cap,
    num_items: res.num_items,
    height: res.height,
  }
}

///|
/// Returns total number of indexed items.
pub fn StrTree::num_items(self : StrTree) -> Int {
  self.num_items
}

///|
/// Returns total number of nodes in the packed tree.
pub fn StrTree::num_nodes(self : StrTree) -> Int {
  self.boxes_min_x.length()
}

///|
/// Returns the height of the tree.
pub fn StrTree::height(self : StrTree) -> Int {
  self.height
}

///|
/// Returns the node capacity.
pub fn StrTree::node_capacity(self : StrTree) -> Int {
  self.node_capacity
}

///|
/// Returns the root node index.
pub fn StrTree::root_index(self : StrTree) -> Int {
  self.root_index
}

///|
/// Returns the bounding box of the entire tree, or None if empty.
pub fn StrTree::root_bounds(self : StrTree) -> @geometry.Rect? {
  if self.root_index < 0 || self.num_items == 0 {
    None
  } else {
    let r = self.root_index
    Some(
      @geometry.Rect::new(
        self.boxes_min_x[r],
        self.boxes_min_y[r],
        self.boxes_max_x[r],
        self.boxes_max_y[r],
      ),
    )
  }
}

///|
/// Performs axis-aligned bounding box range intersection query using iterative stack DFS.
pub fn StrTree::query(
  self : StrTree,
  search_window : @geometry.Rect,
) -> Array[Int] {
  if self.root_index < 0 || self.num_items == 0 {
    return []
  }

  let root = self.root_index
  if !(search_window.max_x >= self.boxes_min_x[root] &&
    search_window.min_x <= self.boxes_max_x[root] &&
    search_window.max_y >= self.boxes_min_y[root] &&
    search_window.min_y <= self.boxes_max_y[root]) {
    return []
  }

  let results : Array[Int] = []
  let stack : Array[Int] = [root]

  while !stack.is_empty() {
    let curr = match stack.pop() {
      Some(v) => v
      None => break
    }

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
        if search_window.max_x >= self.boxes_min_x[child] &&
          search_window.min_x <= self.boxes_max_x[child] &&
          search_window.max_y >= self.boxes_min_y[child] &&
          search_window.min_y <= self.boxes_max_y[child] {
          stack.push(child)
        }
      }
    }
  }

  results
}

///|
/// Performs point inclusion query using iterative stack DFS.
pub fn StrTree::query_point(
  self : StrTree,
  x : Double,
  y : Double,
) -> Array[Int] {
  if self.root_index < 0 || self.num_items == 0 {
    return []
  }

  let root = self.root_index
  if !(self.boxes_min_x[root] <= x &&
    x <= self.boxes_max_x[root] &&
    self.boxes_min_y[root] <= y &&
    y <= self.boxes_max_y[root]) {
    return []
  }

  let results : Array[Int] = []
  let stack : Array[Int] = [root]

  while !stack.is_empty() {
    let curr = match stack.pop() {
      Some(v) => v
      None => break
    }

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
        if self.boxes_min_x[child] <= x &&
          x <= self.boxes_max_x[child] &&
          self.boxes_min_y[child] <= y &&
          y <= self.boxes_max_y[child] {
          stack.push(child)
        }
      }
    }
  }

  results
}
