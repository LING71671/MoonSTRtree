///|
/// Checks if node u in tree t1 intersects node v in tree t2.
fn nodes_intersect(t1 : StrTree, u : Int, t2 : StrTree, v : Int) -> Bool {
  !(t1.boxes_max_x[u] < t2.boxes_min_x[v] ||
  t1.boxes_min_x[u] > t2.boxes_max_x[v] ||
  t1.boxes_max_y[u] < t2.boxes_min_y[v] ||
  t1.boxes_min_y[u] > t2.boxes_max_y[v])
}

///|
/// Performs dual-tree hierarchical spatial join between two StrTree indexes.
/// Returns all pairs of item IDs (id_a, id_b) whose leaf bounding boxes intersect.
pub fn StrTree::spatial_join(
  self : StrTree,
  other : StrTree,
) -> Array[(Int, Int)] {
  if self.root_index < 0 ||
    other.root_index < 0 ||
    self.num_items == 0 ||
    other.num_items == 0 {
    return []
  }

  let root_a = self.root_index
  let root_b = other.root_index

  if !nodes_intersect(self, root_a, other, root_b) {
    return []
  }

  let results : Array[(Int, Int)] = []
  let stack_a : Array[Int] = [root_a]
  let stack_b : Array[Int] = [root_b]

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
        if nodes_intersect(self, curr_a, other, child_b) {
          stack_a.push(curr_a)
          stack_b.push(child_b)
        }
      }
    } else if count_b == 0 {
      let offset_a = self.child_offset[curr_a]
      for i = 0; i < count_a; i = i + 1 {
        let child_a = self.child_indices[offset_a + i]
        if nodes_intersect(self, child_a, other, curr_b) {
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
          if nodes_intersect(self, child_a, other, child_b) {
            stack_a.push(child_a)
            stack_b.push(child_b)
          }
        }
      }
    }
  }

  results
}

///|
/// Queries the spatial index using a named DE-9IM topological predicate.
pub fn StrTree::query_spatial_predicate(
  self : StrTree,
  rect : @geometry.Rect,
  predicate : @geometry.SpatialPredicate,
) -> Array[Int] {
  if self.root_index < 0 || self.num_items == 0 {
    return []
  }

  if predicate == @geometry.SpatialPredicate::Disjoint {
    let results : Array[Int] = []
    let stack : Array[Int] = [self.root_index]
    while !stack.is_empty() {
      let curr = match stack.pop() {
        Some(v) => v
        None => break
      }
      let count = self.child_count[curr]
      if count == 0 {
        let id = self.item_ids[curr]
        if id >= 0 {
          let leaf_rect = @geometry.Rect::new(
            self.boxes_min_x[curr],
            self.boxes_min_y[curr],
            self.boxes_max_x[curr],
            self.boxes_max_y[curr],
          )
          if rect.evaluate_predicate(leaf_rect, predicate) {
            results.push(id)
          }
        }
      } else {
        let offset = self.child_offset[curr]
        for i = 0; i < count; i = i + 1 {
          let child = self.child_indices[offset + i]
          stack.push(child)
        }
      }
    }
    return results
  }

  let win_min_x = if rect.min_x > rect.max_x { rect.max_x } else { rect.min_x }
  let win_max_x = if rect.min_x > rect.max_x { rect.min_x } else { rect.max_x }
  let win_min_y = if rect.min_y > rect.max_y { rect.max_y } else { rect.min_y }
  let win_max_y = if rect.min_y > rect.max_y { rect.min_y } else { rect.max_y }

  let root = self.root_index
  if !(win_max_x >= self.boxes_min_x[root] &&
    win_min_x <= self.boxes_max_x[root] &&
    win_max_y >= self.boxes_min_y[root] &&
    win_min_y <= self.boxes_max_y[root]) {
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
        let leaf_rect = @geometry.Rect::new(
          self.boxes_min_x[curr],
          self.boxes_min_y[curr],
          self.boxes_max_x[curr],
          self.boxes_max_y[curr],
        )
        if rect.evaluate_predicate(leaf_rect, predicate) {
          results.push(id)
        }
      }
    } else {
      let offset = self.child_offset[curr]
      for i = 0; i < count; i = i + 1 {
        let child = self.child_indices[offset + i]
        if win_max_x >= self.boxes_min_x[child] &&
          win_min_x <= self.boxes_max_x[child] &&
          win_max_y >= self.boxes_min_y[child] &&
          win_min_y <= self.boxes_max_y[child] {
          stack.push(child)
        }
      }
    }
  }

  results
}

///|
/// Performs hierarchical spatial join between two trees filtering by a named topological predicate.
pub fn StrTree::spatial_join_predicate(
  self : StrTree,
  other : StrTree,
  predicate : @geometry.SpatialPredicate,
) -> Array[(Int, Int)] {
  if self.root_index < 0 ||
    self.num_items == 0 ||
    other.root_index < 0 ||
    other.num_items == 0 {
    return []
  }

  let results : Array[(Int, Int)] = []
  let stack_a : Array[Int] = [self.root_index]
  let stack_b : Array[Int] = [other.root_index]

  while !stack_a.is_empty() {
    let curr_a = match stack_a.pop() {
      Some(v) => v
      None => break
    }
    let curr_b = match stack_b.pop() {
      Some(v) => v
      None => break
    }

    let disjoint_nodes = self.boxes_max_x[curr_a] < other.boxes_min_x[curr_b] ||
      self.boxes_min_x[curr_a] > other.boxes_max_x[curr_b] ||
      self.boxes_max_y[curr_a] < other.boxes_min_y[curr_b] ||
      self.boxes_min_y[curr_a] > other.boxes_max_y[curr_b]
    if disjoint_nodes {
      continue
    }

    let count_a = self.child_count[curr_a]
    let count_b = other.child_count[curr_b]

    if count_a == 0 && count_b == 0 {
      let id_a = self.item_ids[curr_a]
      let id_b = other.item_ids[curr_b]
      if id_a >= 0 && id_b >= 0 {
        let rect_a = @geometry.Rect::new(
          self.boxes_min_x[curr_a],
          self.boxes_min_y[curr_a],
          self.boxes_max_x[curr_a],
          self.boxes_max_y[curr_a],
        )
        let rect_b = @geometry.Rect::new(
          other.boxes_min_x[curr_b],
          other.boxes_min_y[curr_b],
          other.boxes_max_x[curr_b],
          other.boxes_max_y[curr_b],
        )
        if rect_a.evaluate_predicate(rect_b, predicate) {
          results.push((id_a, id_b))
        }
      }
    } else if count_a == 0 {
      let offset_b = other.child_offset[curr_b]
      for i = 0; i < count_b; i = i + 1 {
        let child_b = other.child_indices[offset_b + i]
        stack_a.push(curr_a)
        stack_b.push(child_b)
      }
    } else if count_b == 0 {
      let offset_a = self.child_offset[curr_a]
      for i = 0; i < count_a; i = i + 1 {
        let child_a = self.child_indices[offset_a + i]
        stack_a.push(child_a)
        stack_b.push(curr_b)
      }
    } else {
      let area_a = (self.boxes_max_x[curr_a] - self.boxes_min_x[curr_a]) *
        (self.boxes_max_y[curr_a] - self.boxes_min_y[curr_a])
      let area_b = (other.boxes_max_x[curr_b] - other.boxes_min_x[curr_b]) *
        (other.boxes_max_y[curr_b] - other.boxes_min_y[curr_b])
      if area_a >= area_b {
        let offset_a = self.child_offset[curr_a]
        for i = 0; i < count_a; i = i + 1 {
          let child_a = self.child_indices[offset_a + i]
          stack_a.push(child_a)
          stack_b.push(curr_b)
        }
      } else {
        let offset_b = other.child_offset[curr_b]
        for i = 0; i < count_b; i = i + 1 {
          let child_b = other.child_indices[offset_b + i]
          stack_a.push(curr_a)
          stack_b.push(child_b)
        }
      }
    }
  }

  results
}
