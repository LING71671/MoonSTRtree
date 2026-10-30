///|
/// Packed 2D spatial index tree with contiguous flat array storage.
pub struct StrTree {
  priv boxes_min_x : Array[Double]
  priv boxes_min_y : Array[Double]
  priv boxes_max_x : Array[Double]
  priv boxes_max_y : Array[Double]
  priv child_offset : Array[Int32]
  priv child_count : Array[Int32]
  priv child_indices : Array[Int32]
  priv item_ids : Array[Int32]
  priv root_index : Int32
  priv node_capacity : Int32
  priv num_items : Int32
  priv height : Int32
  priv contiguous_leaves : Bool
} derive(Eq, Debug, Default)

///|
/// Builds a packed StrTree from an array of (Rect, ID) pairs and node capacity.
pub fn StrTree::build(
  items : Array[(@geometry.Rect, Int32)],
  node_capacity~ : Int32 = 16,
) -> StrTree {
  pack_arrays_2d(
    Array::makei(items.length(), fn(i) { items[i].0.min_x }),
    Array::makei(items.length(), fn(i) { items[i].0.min_y }),
    Array::makei(items.length(), fn(i) { items[i].0.max_x }),
    Array::makei(items.length(), fn(i) { items[i].0.max_y }),
    Array::makei(items.length(), fn(i) { items[i].1 }),
    node_capacity.max(2),
  )
}

///|
/// Returns total number of indexed items.
pub fn StrTree::num_items(self : StrTree) -> Int32 {
  self.num_items
}

///|
/// Returns total number of nodes in the packed tree.
pub fn StrTree::num_nodes(self : StrTree) -> Int32 {
  self.boxes_min_x.length()
}

///|
/// Returns the bounding envelope enclosing the root node of the tree.
pub fn StrTree::envelope(self : StrTree) -> @geometry.Rect {
  if self.num_items == 0 || self.root_index < 0 {
    @geometry.Rect::new(0.0, 0.0, 0.0, 0.0)
  } else {
    let r = self.root_index
    @geometry.Rect::new(
      self.boxes_min_x[r],
      self.boxes_min_y[r],
      self.boxes_max_x[r],
      self.boxes_max_y[r],
    )
  }
}

///|
/// Returns the height of the tree.
pub fn StrTree::height(self : StrTree) -> Int32 {
  self.height
}

///|
/// Returns the node capacity.
pub fn StrTree::node_capacity(self : StrTree) -> Int32 {
  self.node_capacity
}

///|
/// Returns the root node index.
pub fn StrTree::root_index(self : StrTree) -> Int32 {
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
/// Returns true if node at index is a leaf item.
pub fn StrTree::is_leaf_at(self : StrTree, index : Int32) -> Bool {
  if index < 0 || index >= self.boxes_min_x.length() {
    false
  } else {
    self.child_count[index] == 0
  }
}

///|
/// Returns the number of children for node at index.
pub fn StrTree::child_count_at(self : StrTree, index : Int32) -> Int32 {
  if index < 0 || index >= self.boxes_min_x.length() {
    0
  } else {
    self.child_count[index]
  }
}

///|
/// Returns the child index at given child position for parent at index.
pub fn StrTree::child_index_at(
  self : StrTree,
  parent_index : Int32,
  child_pos : Int32,
) -> Int32 {
  if parent_index < 0 || parent_index >= self.boxes_min_x.length() {
    -1
  } else {
    let count = self.child_count[parent_index]
    if child_pos < 0 || child_pos >= count {
      -1
    } else {
      let offset = self.child_offset[parent_index]
      self.child_indices[offset + child_pos]
    }
  }
}

///|
/// Returns the bounding box of the node at index.
pub fn StrTree::node_bounds_at(self : StrTree, index : Int32) -> @geometry.Rect {
  if index < 0 || index >= self.boxes_min_x.length() {
    @geometry.Rect::default()
  } else {
    @geometry.Rect::new(
      self.boxes_min_x[index],
      self.boxes_min_y[index],
      self.boxes_max_x[index],
      self.boxes_max_y[index],
    )
  }
}

///|
/// Returns the item ID for leaf node at index.
pub fn StrTree::item_id_at(self : StrTree, index : Int32) -> Int32 {
  if index < 0 || index >= self.item_ids.length() {
    -1
  } else {
    self.item_ids[index]
  }
}

///|
/// Returns total number of topological child edges across the tree.
pub fn StrTree::total_edges(self : StrTree) -> Int32 {
  self.child_indices.length()
}
