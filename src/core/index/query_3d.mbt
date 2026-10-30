///|
/// Performs 3D range query using iterative stack DFS traversal.
pub fn StrTree3D::query(
  self : StrTree3D,
  search_box : @geometry.Box3D,
) -> Array[Int32] {
  if self.root_index < 0 || self.num_items == 0 {
    return []
  }

  let root = self.root_index
  if search_box.max_x < self.boxes_min_x[root] ||
    search_box.min_x > self.boxes_max_x[root] ||
    search_box.max_y < self.boxes_min_y[root] ||
    search_box.min_y > self.boxes_max_y[root] ||
    search_box.max_z < self.boxes_min_z[root] ||
    search_box.min_z > self.boxes_max_z[root] {
    return []
  }

  let results : Array[Int32] = []
  let stack : Array[Int32] = [root]

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
          search_box.min_z > self.boxes_max_z[child]) {
          stack.push(child)
        }
      }
    }
  }

  results
}

///|
/// Counts intersecting items without materializing result IDs; traversal uses a temporary stack.
pub fn StrTree3D::query_count(
  self : StrTree3D,
  search_box : @geometry.Box3D,
) -> Int32 {
  if self.root_index < 0 || self.num_items == 0 {
    return 0
  }

  let root = self.root_index
  if search_box.max_x < self.boxes_min_x[root] ||
    search_box.min_x > self.boxes_max_x[root] ||
    search_box.max_y < self.boxes_min_y[root] ||
    search_box.min_y > self.boxes_max_y[root] ||
    search_box.max_z < self.boxes_min_z[root] ||
    search_box.min_z > self.boxes_max_z[root] {
    return 0
  }

  let mut count = 0
  let stack : Array[Int32] = [root]

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
          search_box.min_z > self.boxes_max_z[child]) {
          stack.push(child)
        }
      }
    }
  }

  count
}

///|
/// Performs 3D range intersection query returning first matching item ID satisfying predicate.
pub fn StrTree3D::query_first(
  self : StrTree3D,
  search_box : @geometry.Box3D,
  predicate : (Int32) -> Bool,
) -> Int32? {
  if self.root_index < 0 || self.num_items == 0 {
    return None
  }

  let win_min_x = if search_box.min_x > search_box.max_x {
    search_box.max_x
  } else {
    search_box.min_x
  }
  let win_max_x = if search_box.min_x > search_box.max_x {
    search_box.min_x
  } else {
    search_box.max_x
  }
  let win_min_y = if search_box.min_y > search_box.max_y {
    search_box.max_y
  } else {
    search_box.min_y
  }
  let win_max_y = if search_box.min_y > search_box.max_y {
    search_box.min_y
  } else {
    search_box.max_y
  }
  let win_min_z = if search_box.min_z > search_box.max_z {
    search_box.max_z
  } else {
    search_box.min_z
  }
  let win_max_z = if search_box.min_z > search_box.max_z {
    search_box.min_z
  } else {
    search_box.max_z
  }

  let root = self.root_index
  if !(win_max_x >= self.boxes_min_x[root] &&
    win_min_x <= self.boxes_max_x[root] &&
    win_max_y >= self.boxes_min_y[root] &&
    win_min_y <= self.boxes_max_y[root] &&
    win_max_z >= self.boxes_min_z[root] &&
    win_min_z <= self.boxes_max_z[root]) {
    return None
  }

  let stack : Array[Int32] = [root]

  while !stack.is_empty() {
    let curr = match stack.pop() {
      Some(v) => v
      None => break
    }

    let count = self.child_count[curr]
    if count == 0 {
      let id = self.item_ids[curr]
      if id >= 0 && predicate(id) {
        return Some(id)
      }
    } else {
      let offset = self.child_offset[curr]
      for i = 0; i < count; i = i + 1 {
        let child = self.child_indices[offset + i]
        if win_max_x >= self.boxes_min_x[child] &&
          win_min_x <= self.boxes_max_x[child] &&
          win_max_y >= self.boxes_min_y[child] &&
          win_min_y <= self.boxes_max_y[child] &&
          win_max_z >= self.boxes_min_z[child] &&
          win_min_z <= self.boxes_max_z[child] {
          stack.push(child)
        }
      }
    }
  }

  None
}

///|
/// Performs 3D range intersection query with filter predicate.
pub fn StrTree3D::query_with_predicate(
  self : StrTree3D,
  search_box : @geometry.Box3D,
  predicate : (Int32) -> Bool,
) -> Array[Int32] {
  if self.root_index < 0 || self.num_items == 0 {
    return []
  }

  let win_min_x = if search_box.min_x > search_box.max_x {
    search_box.max_x
  } else {
    search_box.min_x
  }
  let win_max_x = if search_box.min_x > search_box.max_x {
    search_box.min_x
  } else {
    search_box.max_x
  }
  let win_min_y = if search_box.min_y > search_box.max_y {
    search_box.max_y
  } else {
    search_box.min_y
  }
  let win_max_y = if search_box.min_y > search_box.max_y {
    search_box.min_y
  } else {
    search_box.max_y
  }
  let win_min_z = if search_box.min_z > search_box.max_z {
    search_box.max_z
  } else {
    search_box.min_z
  }
  let win_max_z = if search_box.min_z > search_box.max_z {
    search_box.min_z
  } else {
    search_box.max_z
  }

  let root = self.root_index
  if !(win_max_x >= self.boxes_min_x[root] &&
    win_min_x <= self.boxes_max_x[root] &&
    win_max_y >= self.boxes_min_y[root] &&
    win_min_y <= self.boxes_max_y[root] &&
    win_max_z >= self.boxes_min_z[root] &&
    win_min_z <= self.boxes_max_z[root]) {
    return []
  }

  let results : Array[Int32] = []
  let stack : Array[Int32] = [root]

  while !stack.is_empty() {
    let curr = match stack.pop() {
      Some(v) => v
      None => break
    }

    let count = self.child_count[curr]
    if count == 0 {
      let id = self.item_ids[curr]
      if id >= 0 && predicate(id) {
        results.push(id)
      }
    } else {
      let offset = self.child_offset[curr]
      for i = 0; i < count; i = i + 1 {
        let child = self.child_indices[offset + i]
        if win_max_x >= self.boxes_min_x[child] &&
          win_min_x <= self.boxes_max_x[child] &&
          win_max_y >= self.boxes_min_y[child] &&
          win_min_y <= self.boxes_max_y[child] &&
          win_max_z >= self.boxes_min_z[child] &&
          win_min_z <= self.boxes_max_z[child] {
          stack.push(child)
        }
      }
    }
  }

  results
}

///|
/// Performs 3D point containment query.
pub fn StrTree3D::query_point(
  self : StrTree3D,
  x : Double,
  y : Double,
  z : Double,
) -> Array[Int32] {
  if self.root_index < 0 || self.num_items == 0 {
    return []
  }

  let root = self.root_index
  if x < self.boxes_min_x[root] ||
    x > self.boxes_max_x[root] ||
    y < self.boxes_min_y[root] ||
    y > self.boxes_max_y[root] ||
    z < self.boxes_min_z[root] ||
    z > self.boxes_max_z[root] {
    return []
  }

  let results : Array[Int32] = []
  let stack : Array[Int32] = [root]

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
        if x >= self.boxes_min_x[child] &&
          x <= self.boxes_max_x[child] &&
          y >= self.boxes_min_y[child] &&
          y <= self.boxes_max_y[child] &&
          z >= self.boxes_min_z[child] &&
          z <= self.boxes_max_z[child] {
          stack.push(child)
        }
      }
    }
  }

  results
}

///|
/// Performs 3D sphere range intersection query.
pub fn StrTree3D::query_sphere(
  self : StrTree3D,
  cx : Double,
  cy : Double,
  cz : Double,
  radius : Double,
) -> Array[Int32] {
  if self.root_index < 0 || self.num_items == 0 || radius < 0.0 {
    return []
  }

  let r_sq = radius * radius
  let root = self.root_index
  let r_dx = if cx < self.boxes_min_x[root] {
    self.boxes_min_x[root] - cx
  } else if cx > self.boxes_max_x[root] {
    cx - self.boxes_max_x[root]
  } else {
    0.0
  }
  let r_dy = if cy < self.boxes_min_y[root] {
    self.boxes_min_y[root] - cy
  } else if cy > self.boxes_max_y[root] {
    cy - self.boxes_max_y[root]
  } else {
    0.0
  }
  let r_dz = if cz < self.boxes_min_z[root] {
    self.boxes_min_z[root] - cz
  } else if cz > self.boxes_max_z[root] {
    cz - self.boxes_max_z[root]
  } else {
    0.0
  }
  if r_dx * r_dx + r_dy * r_dy + r_dz * r_dz > r_sq {
    return []
  }

  let results : Array[Int32] = []
  let stack : Array[Int32] = [root]

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
        let dx = if cx < self.boxes_min_x[child] {
          self.boxes_min_x[child] - cx
        } else if cx > self.boxes_max_x[child] {
          cx - self.boxes_max_x[child]
        } else {
          0.0
        }
        let dy = if cy < self.boxes_min_y[child] {
          self.boxes_min_y[child] - cy
        } else if cy > self.boxes_max_y[child] {
          cy - self.boxes_max_y[child]
        } else {
          0.0
        }
        let dz = if cz < self.boxes_min_z[child] {
          self.boxes_min_z[child] - cz
        } else if cz > self.boxes_max_z[child] {
          cz - self.boxes_max_z[child]
        } else {
          0.0
        }
        if dx * dx + dy * dy + dz * dz <= r_sq {
          stack.push(child)
        }
      }
    }
  }

  results
}

///|
/// Performs 3D line segment / ray intersection query using iterative stack DFS.
/// Returns item IDs of all indexed elements whose bounding boxes intersect the segment (x1, y1, z1) -> (x2, y2, z2).
pub fn StrTree3D::query_segment(
  self : StrTree3D,
  x1 : Double,
  y1 : Double,
  z1 : Double,
  x2 : Double,
  y2 : Double,
  z2 : Double,
) -> Array[Int32] {
  if self.root_index < 0 || self.num_items == 0 {
    return []
  }

  let root = self.root_index
  let root_box = @geometry.Box3D::new(
    self.boxes_min_x[root],
    self.boxes_min_y[root],
    self.boxes_min_z[root],
    self.boxes_max_x[root],
    self.boxes_max_y[root],
    self.boxes_max_z[root],
  )
  if !root_box.intersects_segment(x1, y1, z1, x2, y2, z2) {
    return []
  }

  let results : Array[Int32] = []
  let stack : Array[Int32] = [root]

  while !stack.is_empty() {
    let curr = match stack.pop() {
      Some(idx) => idx
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
        let child_box = @geometry.Box3D::new(
          self.boxes_min_x[child],
          self.boxes_min_y[child],
          self.boxes_min_z[child],
          self.boxes_max_x[child],
          self.boxes_max_y[child],
          self.boxes_max_z[child],
        )
        if child_box.intersects_segment(x1, y1, z1, x2, y2, z2) {
          stack.push(child)
        }
      }
    }
  }

  results
}

///|
/// Counts items containing a point without materializing result IDs; traversal uses a temporary stack.
pub fn StrTree3D::query_point_count(
  self : StrTree3D,
  x : Double,
  y : Double,
  z : Double,
) -> Int32 {
  if self.root_index < 0 || self.num_items == 0 {
    return 0
  }

  let root = self.root_index
  if x < self.boxes_min_x[root] ||
    x > self.boxes_max_x[root] ||
    y < self.boxes_min_y[root] ||
    y > self.boxes_max_y[root] ||
    z < self.boxes_min_z[root] ||
    z > self.boxes_max_z[root] {
    return 0
  }

  let mut count = 0
  let stack : Array[Int32] = [root]

  while !stack.is_empty() {
    let curr = stack.pop().unwrap()
    let c_count = self.child_count[curr]
    if c_count == 0 {
      if self.item_ids[curr] >= 0 {
        count = count + 1
      }
    } else {
      let offset = self.child_offset[curr]
      for i = 0; i < c_count; i = i + 1 {
        let child = self.child_indices[offset + i]
        if !(x < self.boxes_min_x[child] ||
          x > self.boxes_max_x[child] ||
          y < self.boxes_min_y[child] ||
          y > self.boxes_max_y[child] ||
          z < self.boxes_min_z[child] ||
          z > self.boxes_max_z[child]) {
          stack.push(child)
        }
      }
    }
  }

  count
}

///|
/// Counts sphere intersections without materializing result IDs; traversal uses a temporary stack.
pub fn StrTree3D::query_sphere_count(
  self : StrTree3D,
  cx : Double,
  cy : Double,
  cz : Double,
  radius : Double,
) -> Int32 {
  if radius < 0.0 || self.root_index < 0 || self.num_items == 0 {
    return 0
  }

  let r_sq = radius * radius
  let root = self.root_index

  let root_dist = dist_sq_to_box3d(
    self.boxes_min_x[root],
    self.boxes_min_y[root],
    self.boxes_min_z[root],
    self.boxes_max_x[root],
    self.boxes_max_y[root],
    self.boxes_max_z[root],
    cx,
    cy,
    cz,
  )
  if root_dist > r_sq {
    return 0
  }

  let mut count = 0
  let stack : Array[Int32] = [root]

  while !stack.is_empty() {
    let curr = stack.pop().unwrap()
    let c_count = self.child_count[curr]
    if c_count == 0 {
      if self.item_ids[curr] >= 0 {
        count = count + 1
      }
    } else {
      let offset = self.child_offset[curr]
      for i = 0; i < c_count; i = i + 1 {
        let child = self.child_indices[offset + i]
        let d_sq = dist_sq_to_box3d(
          self.boxes_min_x[child],
          self.boxes_min_y[child],
          self.boxes_min_z[child],
          self.boxes_max_x[child],
          self.boxes_max_y[child],
          self.boxes_max_z[child],
          cx,
          cy,
          cz,
        )
        if d_sq <= r_sq {
          stack.push(child)
        }
      }
    }
  }

  count
}
