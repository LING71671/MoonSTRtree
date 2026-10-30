///|
/// Checks if node u in tree t1 intersects node v in tree t2 in 3D Euclidean space.
fn nodes_intersect3d(
  t1 : StrTree3D,
  u : Int32,
  t2 : StrTree3D,
  v : Int32,
) -> Bool {
  !(t1.boxes_max_x[u] < t2.boxes_min_x[v] ||
  t1.boxes_min_x[u] > t2.boxes_max_x[v] ||
  t1.boxes_max_y[u] < t2.boxes_min_y[v] ||
  t1.boxes_min_y[u] > t2.boxes_max_y[v] ||
  t1.boxes_max_z[u] < t2.boxes_min_z[v] ||
  t1.boxes_min_z[u] > t2.boxes_max_z[v])
}

///|
/// Performs dual-tree hierarchical spatial join between two StrTree3D indexes.
/// Returns all pairs of item IDs (id_a, id_b) whose leaf bounding boxes intersect.
pub fn StrTree3D::spatial_join(
  self : StrTree3D,
  other : StrTree3D,
) -> Array[(Int32, Int32)] {
  if self.root_index < 0 ||
    other.root_index < 0 ||
    self.num_items == 0 ||
    other.num_items == 0 {
    return []
  }

  let root_a = self.root_index
  let root_b = other.root_index

  if !nodes_intersect3d(self, root_a, other, root_b) {
    return []
  }

  let results : Array[(Int32, Int32)] = []
  let stack_a : Array[Int32] = [root_a]
  let stack_b : Array[Int32] = [root_b]

  while !stack_a.is_empty() {
    let curr_a = match stack_a.pop() {
      Some(idx) => idx
      None => break
    }
    let curr_b = match stack_b.pop() {
      Some(idx) => idx
      None => break
    }

    let count_a = self.child_count[curr_a]
    let count_b = other.child_count[curr_b]

    if count_a == 0 && count_b == 0 {
      let id_a = self.item_ids[curr_a]
      let id_b = other.item_ids[curr_b]
      if id_a >= 0 && id_b >= 0 {
        results.push((id_a, id_b))
      }
    } else if count_a == 0 {
      let offset_b = other.child_offset[curr_b]
      for j = 0; j < count_b; j = j + 1 {
        let child_b = other.child_indices[offset_b + j]
        if nodes_intersect3d(self, curr_a, other, child_b) {
          stack_a.push(curr_a)
          stack_b.push(child_b)
        }
      }
    } else if count_b == 0 {
      let offset_a = self.child_offset[curr_a]
      for i = 0; i < count_a; i = i + 1 {
        let child_a = self.child_indices[offset_a + i]
        if nodes_intersect3d(self, child_a, other, curr_b) {
          stack_a.push(child_a)
          stack_b.push(curr_b)
        }
      }
    } else {
      let offset_a = self.child_offset[curr_a]
      let offset_b = other.child_offset[curr_b]
      for i = 0; i < count_a; i = i + 1 {
        let child_a = self.child_indices[offset_a + i]
        for j = 0; j < count_b; j = j + 1 {
          let child_b = other.child_indices[offset_b + j]
          if nodes_intersect3d(self, child_a, other, child_b) {
            stack_a.push(child_a)
            stack_b.push(child_b)
          }
        }
      }
    }
  }

  results
}
