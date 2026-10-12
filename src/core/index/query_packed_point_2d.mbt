///|
/// Point inclusion on validated homogeneous pages avoids a temporary rectangle,
/// range normalization and general subtree-cover tests. No extra index storage.
fn StrTree::query_packed_point(
  self : StrTree,
  x : Double,
  y : Double,
) -> Array[Int] {
  let root = self.root_index
  let rx1 = self.boxes_min_x.unsafe_get(root)
  let ry1 = self.boxes_min_y.unsafe_get(root)
  let rx2 = self.boxes_max_x.unsafe_get(root)
  let ry2 = self.boxes_max_y.unsafe_get(root)
  // Positive comparisons also reject NaN query coordinates or root bounds.
  if !(x >= rx1 && x <= rx2 && y >= ry1 && y <= ry2) {
    return []
  }
  if rx1 == rx2 && ry1 == ry2 {
    let ids = self.item_ids.copy()
    ids.truncate(self.num_items)
    return ids
  }
  let results : Array[Int] = []
  let stack : Array[Int] = [root]
  let mut hits = 0
  while !stack.is_empty() {
    let node = stack.unsafe_pop()
    let offset = self.child_offset.unsafe_get(node)
    let count = self.child_count.unsafe_get(node)
    // The derived layout flag proves in-bounds adjacency, homogeneous child
    // pages and depth-first consecutive leaves. Unproven restores never enter.
    let first = self.child_indices.unsafe_get(offset)
    if first < self.num_items {
      for child = first; child < first + count; child = child + 1 {
        if x >= self.boxes_min_x.unsafe_get(child) &&
          x <= self.boxes_max_x.unsafe_get(child) &&
          y >= self.boxes_min_y.unsafe_get(child) &&
          y <= self.boxes_max_y.unsafe_get(child) {
          write_range_result(results, hits, self.item_ids.unsafe_get(child))
          hits = hits + 1
        }
      }
    } else {
      for edge = offset; edge < offset + count; edge = edge + 1 {
        let child = self.child_indices.unsafe_get(edge)
        if x >= self.boxes_min_x.unsafe_get(child) &&
          x <= self.boxes_max_x.unsafe_get(child) &&
          y >= self.boxes_min_y.unsafe_get(child) &&
          y <= self.boxes_max_y.unsafe_get(child) {
          stack.push(child)
        }
      }
    }
  }
  results.truncate(hits)
  results
}
