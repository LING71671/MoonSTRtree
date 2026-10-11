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
/// Counts intersecting items without materializing result IDs; traversal uses a temporary stack.
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
