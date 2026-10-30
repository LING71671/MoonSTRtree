///|
/// Homogeneous packed pages test and append leaves directly. Only branch nodes
/// enter the traversal stack; the derived layout flag proves every array access.
fn StrTree::query_packed_circle(
  self : StrTree,
  cx : Double,
  cy : Double,
  radius_squared : Double,
) -> Array[Int32] {
  let root = self.root_index
  if !(dist_sq_to_box(
      self.boxes_min_x.unsafe_get(root),
      self.boxes_min_y.unsafe_get(root),
      self.boxes_max_x.unsafe_get(root),
      self.boxes_max_y.unsafe_get(root),
      cx,
      cy,
    ) <=
    radius_squared) {
    return []
  }
  let results : Array[Int32] = []
  let stack : Array[Int32] = [root]
  let mut hits = 0
  while !stack.is_empty() {
    let node = stack.unsafe_pop()
    let offset = self.child_offset.unsafe_get(node)
    let count = self.child_count.unsafe_get(node)
    let first = self.child_indices.unsafe_get(offset)
    if first < self.num_items {
      for child = first; child < first + count; child = child + 1 {
        if dist_sq_to_box(
            self.boxes_min_x.unsafe_get(child),
            self.boxes_min_y.unsafe_get(child),
            self.boxes_max_x.unsafe_get(child),
            self.boxes_max_y.unsafe_get(child),
            cx,
            cy,
          ) <=
          radius_squared {
          write_range_result(results, hits, self.item_ids.unsafe_get(child))
          hits = hits + 1
        }
      }
    } else {
      for edge = offset; edge < offset + count; edge = edge + 1 {
        let child = self.child_indices.unsafe_get(edge)
        if dist_sq_to_box(
            self.boxes_min_x.unsafe_get(child),
            self.boxes_min_y.unsafe_get(child),
            self.boxes_max_x.unsafe_get(child),
            self.boxes_max_y.unsafe_get(child),
            cx,
            cy,
          ) <=
          radius_squared {
          stack.push(child)
        }
      }
    }
  }
  results.truncate(hits)
  results
}
