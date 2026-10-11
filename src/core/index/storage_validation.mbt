///|
/// Validates a single-rooted tree before any untrusted offsets are dereferenced.
fn validate_topology(
  offsets : Array[Int],
  counts : Array[Int],
  edges : Array[Int],
  ids : Array[Int],
  root : Int,
  capacity : Int,
  items : Int,
  height : Int,
) -> Bool {
  let n = ids.length()
  if offsets.length() != n || counts.length() != n || capacity < 2 {
    return false
  }
  if n == 0 {
    return root == -1 && items == 0 && height == 0 && edges.is_empty()
  }
  if root < 0 ||
    root >= n ||
    items <= 0 ||
    height <= 0 ||
    edges.length() != n - 1 {
    return false
  }
  let seen = Array::make(n, false)
  let stack : Array[(Int, Int)] = [(root, 0)]
  let mut visited = 0
  let mut leaves = 0
  let mut depth = 0
  while stack.pop() is Some((node, level)) {
    if seen[node] {
      return false
    }
    seen[node] = true
    visited = visited + 1
    if level > depth {
      depth = level
    }
    let count = counts[node]
    let offset = offsets[node]
    if count < 0 ||
      count > capacity ||
      offset < 0 ||
      offset > edges.length() ||
      count > edges.length() - offset {
      return false
    }
    if count == 0 {
      if ids[node] < 0 {
        return false
      }
      leaves = leaves + 1
    } else {
      for i = 0; i < count; i = i + 1 {
        let child = edges[offset + i]
        if child < 0 || child >= n {
          return false
        }
        stack.push((child, level + 1))
      }
    }
  }
  visited == n && leaves == items && depth == height
}

///|
/// Validates one coordinate axis, including the enclosure of each child.
fn validate_axis(
  minimum : Array[Double],
  maximum : Array[Double],
  offsets : Array[Int],
  counts : Array[Int],
  edges : Array[Int],
) -> Bool {
  let n = counts.length()
  if minimum.length() != n || maximum.length() != n {
    return false
  }
  for node = 0; node < n; node = node + 1 {
    let lo = minimum[node]
    let hi = maximum[node]
    if lo - lo != 0.0 || hi - hi != 0.0 || lo > hi {
      return false
    }
    for i = 0; i < counts[node]; i = i + 1 {
      let child = edges[offsets[node] + i]
      if lo > minimum[child] || hi < maximum[child] {
        return false
      }
    }
  }
  true
}

///|
/// Returns None for malformed buffers instead of accepting cycles or invalid offsets.
pub fn StrTree::from_flat_buffers_checked(buffers : FlatBuffers) -> StrTree? {
  if !validate_topology(
      buffers.child_offset,
      buffers.child_count,
      buffers.child_indices,
      buffers.item_ids,
      buffers.root_index,
      buffers.node_capacity,
      buffers.num_items,
      buffers.height,
    ) ||
    !validate_axis(
      buffers.boxes_min_x,
      buffers.boxes_max_x,
      buffers.child_offset,
      buffers.child_count,
      buffers.child_indices,
    ) ||
    !validate_axis(
      buffers.boxes_min_y,
      buffers.boxes_max_y,
      buffers.child_offset,
      buffers.child_count,
      buffers.child_indices,
    ) {
    return None
  }
  Some(StrTree::from_flat_buffers(buffers))
}

///|
/// Validates topology, dimensional lengths and enclosures before copying 3D buffers.
pub fn StrTree3D::from_flat_buffers_checked(
  buffers : FlatBuffers3D,
) -> StrTree3D? {
  if buffers.num_nodes != buffers.item_ids.length() ||
    buffers.node_levels.length() != buffers.num_nodes ||
    !validate_topology(
      buffers.child_offset,
      buffers.child_count,
      buffers.child_indices,
      buffers.item_ids,
      buffers.root_index,
      buffers.node_capacity,
      buffers.num_items,
      buffers.height,
    ) ||
    !validate_axis(
      buffers.boxes_min_x,
      buffers.boxes_max_x,
      buffers.child_offset,
      buffers.child_count,
      buffers.child_indices,
    ) ||
    !validate_axis(
      buffers.boxes_min_y,
      buffers.boxes_max_y,
      buffers.child_offset,
      buffers.child_count,
      buffers.child_indices,
    ) ||
    !validate_axis(
      buffers.boxes_min_z,
      buffers.boxes_max_z,
      buffers.child_offset,
      buffers.child_count,
      buffers.child_indices,
    ) {
    return None
  }
  Some(StrTree3D::from_flat_buffers(buffers))
}

///|
/// Validates raw storage without normalizing damaged bounds or copying buffers.
pub fn StrTree::validate_integrity(self : StrTree) -> Bool {
  validate_topology(
    self.child_offset,
    self.child_count,
    self.child_indices,
    self.item_ids,
    self.root_index,
    self.node_capacity,
    self.num_items,
    self.height,
  ) &&
  validate_axis(
    self.boxes_min_x,
    self.boxes_max_x,
    self.child_offset,
    self.child_count,
    self.child_indices,
  ) &&
  validate_axis(
    self.boxes_min_y,
    self.boxes_max_y,
    self.child_offset,
    self.child_count,
    self.child_indices,
  )
}
