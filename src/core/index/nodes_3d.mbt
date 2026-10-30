///|
/// Read-only structural access for visualizers; storage buffers remain private.
pub fn StrTree3D::num_items(self : StrTree3D) -> Int32 {
  self.num_items
}

///|
pub fn StrTree3D::num_nodes(self : StrTree3D) -> Int32 {
  self.num_nodes
}

///|
pub fn StrTree3D::height(self : StrTree3D) -> Int32 {
  self.height
}

///|
pub fn StrTree3D::root_index(self : StrTree3D) -> Int32 {
  self.root_index
}

///|
pub fn StrTree3D::is_leaf_at(self : StrTree3D, index : Int32) -> Bool {
  index >= 0 && index < self.num_nodes && self.child_count[index] == 0
}

///|
pub fn StrTree3D::child_count_at(self : StrTree3D, index : Int32) -> Int32 {
  if index < 0 || index >= self.num_nodes {
    0
  } else {
    self.child_count[index]
  }
}

///|
pub fn StrTree3D::child_index_at(
  self : StrTree3D,
  parent : Int32,
  position : Int32,
) -> Int32 {
  if parent < 0 ||
    parent >= self.num_nodes ||
    position < 0 ||
    position >= self.child_count[parent] {
    -1
  } else {
    self.child_indices[self.child_offset[parent] + position]
  }
}

///|
pub fn StrTree3D::node_bounds_at(
  self : StrTree3D,
  index : Int32,
) -> @geometry.Box3D {
  if index < 0 || index >= self.num_nodes {
    @geometry.Box3D::from_point(0.0, 0.0, 0.0)
  } else {
    @geometry.Box3D::new(
      self.boxes_min_x[index],
      self.boxes_min_y[index],
      self.boxes_min_z[index],
      self.boxes_max_x[index],
      self.boxes_max_y[index],
      self.boxes_max_z[index],
    )
  }
}
