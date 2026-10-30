///|
/// Performs an inclusive range query using the shared iterative traversal.
pub fn StrTree::query(
  self : StrTree,
  search_window : @geometry.Rect,
) -> Array[Int32] {
  // Built trees store item IDs in a prefix. Native buffer copies and JS slice
  // avoid per-hit host calls when the entire index lies inside the query.
  let root = self.root_index
  if self.contiguous_leaves &&
    root >= 0 &&
    search_window.min_x.min(search_window.max_x) <= self.boxes_min_x[root] &&
    search_window.min_y.min(search_window.max_y) <= self.boxes_min_y[root] &&
    search_window.min_x.max(search_window.max_x) >= self.boxes_max_x[root] &&
    search_window.min_y.max(search_window.max_y) >= self.boxes_max_y[root] {
    let ids = self.item_ids.copy()
    ids.truncate(self.num_items)
    return ids
  }
  let results : Array[Int32] = []
  let stack : Array[Int32] = []
  self.query_into(search_window, results, stack)
  results
}

///|
/// Clears and reuses caller-owned result and traversal buffers. Buffers must be distinct.
pub fn StrTree::query_into(
  self : StrTree,
  search_window : @geometry.Rect,
  results : Array[Int32],
  stack : Array[Int32],
) -> Unit {
  results.clear()
  stack.clear()
  if self.root_index < 0 || self.num_items == 0 {
    return
  }

  if self.contiguous_leaves {
    self.query_packed_range(search_window, results, stack)
    return
  }

  let win_min_x = if search_window.min_x > search_window.max_x {
    search_window.max_x
  } else {
    search_window.min_x
  }
  let win_max_x = if search_window.min_x > search_window.max_x {
    search_window.min_x
  } else {
    search_window.max_x
  }
  let win_min_y = if search_window.min_y > search_window.max_y {
    search_window.max_y
  } else {
    search_window.min_y
  }
  let win_max_y = if search_window.min_y > search_window.max_y {
    search_window.min_y
  } else {
    search_window.max_y
  }

  // Validate lengths once and each child index once before reading SoA columns.
  // Malformed trusted restores still fail before any unchecked read.
  let nodes = self.boxes_min_x.length()
  guard self.boxes_min_y.length() == nodes &&
    self.boxes_max_x.length() == nodes &&
    self.boxes_max_y.length() == nodes &&
    self.child_count.length() == nodes &&
    self.child_offset.length() == nodes &&
    self.item_ids.length() == nodes else {
    abort("Inconsistent index columns")
  }
  let root = self.root_index
  guard root < nodes else { abort("Invalid root index") }
  if !(win_max_x >= self.boxes_min_x.unsafe_get(root) &&
    win_min_x <= self.boxes_max_x.unsafe_get(root) &&
    win_max_y >= self.boxes_min_y.unsafe_get(root) &&
    win_min_y <= self.boxes_max_y.unsafe_get(root)) {
    return
  }

  // A covering query needs no tree traversal. Restored buffers may use any
  // node order, so recognize leaves by topology instead of a positional assumption.
  if win_min_x <= self.boxes_min_x.unsafe_get(root) &&
    win_min_y <= self.boxes_min_y.unsafe_get(root) &&
    win_max_x >= self.boxes_max_x.unsafe_get(root) &&
    win_max_y >= self.boxes_max_y.unsafe_get(root) {
    self.collect_all_leaves(results)
    return
  }

  stack.push(root)
  let mut hits = 0

  while !stack.is_empty() {
    let entry = match stack.pop() {
      Some(v) => v
      None => break
    }
    // Complemented node indices denote a wholly contained subtree.
    let contained = entry < 0
    let curr = if contained { entry.lnot() } else { entry }

    let count = self.child_count.unsafe_get(curr)
    if count == 0 {
      let id = self.item_ids.unsafe_get(curr)
      if id >= 0 {
        write_range_result(results, hits, id)
        hits = hits + 1
      }
    } else {
      let offset = self.child_offset.unsafe_get(curr)
      for i = 0; i < count; i = i + 1 {
        let child = self.child_indices[offset + i]
        guard child >= 0 && child < nodes else { abort("Invalid child index") }
        if contained ||
          (
            win_max_x >= self.boxes_min_x.unsafe_get(child) &&
            win_min_x <= self.boxes_max_x.unsafe_get(child) &&
            win_max_y >= self.boxes_min_y.unsafe_get(child) &&
            win_min_y <= self.boxes_max_y.unsafe_get(child)
          ) {
          if self.child_count.unsafe_get(child) == 0 {
            let id = self.item_ids.unsafe_get(child)
            if id >= 0 {
              write_range_result(results, hits, id)
              hits = hits + 1
            }
          } else {
            let covers_child = contained ||
              (
                win_min_x <= self.boxes_min_x.unsafe_get(child) &&
                win_min_y <= self.boxes_min_y.unsafe_get(child) &&
                win_max_x >= self.boxes_max_x.unsafe_get(child) &&
                win_max_y >= self.boxes_max_y.unsafe_get(child)
              )
            stack.push(if covers_child { child.lnot() } else { child })
          }
        }
      }
    }
  }
  results.truncate(hits)
}

///|
/// Performs point inclusion query using iterative stack DFS.
pub fn StrTree::query_point(
  self : StrTree,
  x : Double,
  y : Double,
) -> Array[Int32] {
  if self.root_index < 0 || self.num_items == 0 {
    return []
  }
  if self.contiguous_leaves {
    return self.query_packed_point(x, y)
  }
  self.query(@geometry.Rect::from_point(x, y))
}

///|
/// Performs axis-aligned bounding box range intersection counting with zero result allocation.
pub fn StrTree::query_count(
  self : StrTree,
  search_window : @geometry.Rect,
) -> Int32 {
  if self.root_index < 0 || self.num_items == 0 {
    return 0
  }

  let win_min_x = if search_window.min_x > search_window.max_x {
    search_window.max_x
  } else {
    search_window.min_x
  }
  let win_max_x = if search_window.min_x > search_window.max_x {
    search_window.min_x
  } else {
    search_window.max_x
  }
  let win_min_y = if search_window.min_y > search_window.max_y {
    search_window.max_y
  } else {
    search_window.min_y
  }
  let win_max_y = if search_window.min_y > search_window.max_y {
    search_window.min_y
  } else {
    search_window.max_y
  }

  let root = self.root_index
  if !(win_max_x >= self.boxes_min_x[root] &&
    win_min_x <= self.boxes_max_x[root] &&
    win_max_y >= self.boxes_min_y[root] &&
    win_min_y <= self.boxes_max_y[root]) {
    return 0
  }

  let mut count = 0
  let stack : Array[Int32] = [root]

  while !stack.is_empty() {
    let curr = match stack.pop() {
      Some(v) => v
      None => break
    }

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
        if win_max_x >= self.boxes_min_x[child] &&
          win_min_x <= self.boxes_max_x[child] &&
          win_max_y >= self.boxes_min_y[child] &&
          win_min_y <= self.boxes_max_y[child] {
          stack.push(child)
        }
      }
    }
  }

  count
}

///|
/// Performs point inclusion counting without allocating a result array.
pub fn StrTree::query_point_count(
  self : StrTree,
  x : Double,
  y : Double,
) -> Int32 {
  if self.root_index < 0 || self.num_items == 0 {
    return 0
  }

  let root = self.root_index
  if !(self.boxes_min_x[root] <= x &&
    x <= self.boxes_max_x[root] &&
    self.boxes_min_y[root] <= y &&
    y <= self.boxes_max_y[root]) {
    return 0
  }

  let mut count = 0
  let stack : Array[Int32] = [root]

  while !stack.is_empty() {
    let curr = match stack.pop() {
      Some(v) => v
      None => break
    }

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
        if self.boxes_min_x[child] <= x &&
          x <= self.boxes_max_x[child] &&
          self.boxes_min_y[child] <= y &&
          y <= self.boxes_max_y[child] {
          stack.push(child)
        }
      }
    }
  }

  count
}

///|
/// Returns the first item ID intersecting search_window that satisfies the predicate, or None.
pub fn StrTree::query_first(
  self : StrTree,
  search_window : @geometry.Rect,
  predicate : (Int32) -> Bool,
) -> Int32? {
  if self.root_index < 0 || self.num_items == 0 {
    return None
  }

  let win_min_x = if search_window.min_x > search_window.max_x {
    search_window.max_x
  } else {
    search_window.min_x
  }
  let win_max_x = if search_window.min_x > search_window.max_x {
    search_window.min_x
  } else {
    search_window.max_x
  }
  let win_min_y = if search_window.min_y > search_window.max_y {
    search_window.max_y
  } else {
    search_window.min_y
  }
  let win_max_y = if search_window.min_y > search_window.max_y {
    search_window.min_y
  } else {
    search_window.max_y
  }

  let root = self.root_index
  if !(win_max_x >= self.boxes_min_x[root] &&
    win_min_x <= self.boxes_max_x[root] &&
    win_max_y >= self.boxes_min_y[root] &&
    win_min_y <= self.boxes_max_y[root]) {
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
          win_min_y <= self.boxes_max_y[child] {
          stack.push(child)
        }
      }
    }
  }

  None
}

///|
/// Performs axis-aligned bounding box range intersection query with filter predicate.
pub fn StrTree::query_with_predicate(
  self : StrTree,
  search_window : @geometry.Rect,
  predicate : (Int32) -> Bool,
) -> Array[Int32] {
  if self.root_index < 0 || self.num_items == 0 {
    return []
  }

  let win_min_x = if search_window.min_x > search_window.max_x {
    search_window.max_x
  } else {
    search_window.min_x
  }
  let win_max_x = if search_window.min_x > search_window.max_x {
    search_window.min_x
  } else {
    search_window.max_x
  }
  let win_min_y = if search_window.min_y > search_window.max_y {
    search_window.max_y
  } else {
    search_window.min_y
  }
  let win_max_y = if search_window.min_y > search_window.max_y {
    search_window.min_y
  } else {
    search_window.max_y
  }

  let root = self.root_index
  if !(win_max_x >= self.boxes_min_x[root] &&
    win_min_x <= self.boxes_max_x[root] &&
    win_max_y >= self.boxes_min_y[root] &&
    win_min_y <= self.boxes_max_y[root]) {
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
          win_min_y <= self.boxes_max_y[child] {
          stack.push(child)
        }
      }
    }
  }

  results
}

///|
/// Performs circular / radius range query using iterative stack DFS.
/// Returns item IDs of all indexed elements whose bounding boxes intersect the circle.
pub fn StrTree::query_circle(
  self : StrTree,
  cx : Double,
  cy : Double,
  radius : Double,
) -> Array[Int32] {
  if self.root_index < 0 || self.num_items == 0 || radius < 0.0 {
    return []
  }

  if self.contiguous_leaves {
    return self.query_packed_circle(cx, cy, radius * radius)
  }

  let root = self.root_index
  let r_sq = radius * radius

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
  if r_dx * r_dx + r_dy * r_dy > r_sq {
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
      if id >= 0 {
        results.push(id)
      }
    } else {
      let offset = self.child_offset[curr]
      for i = 0; i < count; i = i + 1 {
        let child = self.child_indices[offset + i]
        let c_min_x = self.boxes_min_x[child]
        let c_max_x = self.boxes_max_x[child]
        let c_min_y = self.boxes_min_y[child]
        let c_max_y = self.boxes_max_y[child]

        let dx = if cx < c_min_x {
          c_min_x - cx
        } else if cx > c_max_x {
          cx - c_max_x
        } else {
          0.0
        }
        let dy = if cy < c_min_y {
          c_min_y - cy
        } else if cy > c_max_y {
          cy - c_max_y
        } else {
          0.0
        }

        if dx * dx + dy * dy <= r_sq {
          stack.push(child)
        }
      }
    }
  }

  results
}

///|
/// Performs circular / radius range counting with zero result allocation.
pub fn StrTree::query_circle_count(
  self : StrTree,
  cx : Double,
  cy : Double,
  radius : Double,
) -> Int32 {
  if self.root_index < 0 || self.num_items == 0 || radius < 0.0 {
    return 0
  }

  let root = self.root_index
  let r_sq = radius * radius

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
  if r_dx * r_dx + r_dy * r_dy > r_sq {
    return 0
  }

  let mut count = 0
  let stack : Array[Int32] = [root]

  while !stack.is_empty() {
    let curr = match stack.pop() {
      Some(v) => v
      None => break
    }

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
        let c_min_x = self.boxes_min_x[child]
        let c_max_x = self.boxes_max_x[child]
        let c_min_y = self.boxes_min_y[child]
        let c_max_y = self.boxes_max_y[child]

        let dx = if cx < c_min_x {
          c_min_x - cx
        } else if cx > c_max_x {
          cx - c_max_x
        } else {
          0.0
        }
        let dy = if cy < c_min_y {
          c_min_y - cy
        } else if cy > c_max_y {
          cy - c_max_y
        } else {
          0.0
        }

        if dx * dx + dy * dy <= r_sq {
          stack.push(child)
        }
      }
    }
  }

  count
}

///|
/// Performs line segment / ray intersection query using iterative stack DFS.
/// Returns item IDs of all indexed elements whose bounding boxes intersect the segment (x1, y1) -> (x2, y2).
pub fn StrTree::query_segment(
  self : StrTree,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> Array[Int32] {
  if self.root_index < 0 || self.num_items == 0 {
    return []
  }

  let root = self.root_index
  let root_rect = @geometry.Rect::new(
    self.boxes_min_x[root],
    self.boxes_min_y[root],
    self.boxes_max_x[root],
    self.boxes_max_y[root],
  )
  if !root_rect.intersects_segment(x1, y1, x2, y2) {
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
        let child_rect = @geometry.Rect::new(
          self.boxes_min_x[child],
          self.boxes_min_y[child],
          self.boxes_max_x[child],
          self.boxes_max_y[child],
        )
        if child_rect.intersects_segment(x1, y1, x2, y2) {
          stack.push(child)
        }
      }
    }
  }

  results
}

///|
/// Column lengths have already been validated by query_into.
fn StrTree::collect_all_leaves(self : StrTree, results : Array[Int32]) -> Unit {
  let ids = self.item_ids
  let counts = self.child_count
  results.resize(ids.length(), 0)
  let mut hits = 0
  for i = 0; i < ids.length(); i = i + 1 {
    if counts.unsafe_get(i) == 0 && ids.unsafe_get(i) >= 0 {
      results.unsafe_set(hits, ids.unsafe_get(i))
      hits = hits + 1
    }
  }
  results.truncate(hits)
}

///|
/// The derived layout hint guarantees validated, consecutive leaf pages.
/// These page offsets and leaf indices are therefore in bounds; trusted restores
/// without that proof use the checked general traversal instead.
fn StrTree::query_leaf_page(
  self : StrTree,
  offset : Int32,
  count : Int32,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  contained : Bool,
  results : Array[Int32],
  position : Int32,
) -> Int32 {
  let mut hits = position
  let first = self.child_indices.unsafe_get(offset)
  if contained {
    append_leaf_span(self.item_ids, results, first, first + count, position)
    return position + count
  }
  for child = first; child < first + count; child = child + 1 {
    if contained ||
      (
        x2 >= self.boxes_min_x.unsafe_get(child) &&
        x1 <= self.boxes_max_x.unsafe_get(child) &&
        y2 >= self.boxes_min_y.unsafe_get(child) &&
        y1 <= self.boxes_max_y.unsafe_get(child)
      ) {
      write_range_result(results, hits, self.item_ids.unsafe_get(child))
      hits = hits + 1
    }
  }
  hits
}
