///|
/// Fast traversal for immutable, validated trees with consecutive leaf pages.
/// Only query_into calls this after checking the derived layout flag.
fn StrTree::query_packed_range(
  self : StrTree,
  window : @geometry.Rect,
  results : Array[Int32],
  stack : Array[Int32],
) -> Unit {
  let x1 = window.min_x.min(window.max_x)
  let y1 = window.min_y.min(window.max_y)
  let x2 = window.min_x.max(window.max_x)
  let y2 = window.min_y.max(window.max_y)
  let root = self.root_index
  if !(x2 >= self.boxes_min_x.unsafe_get(root) &&
    y2 >= self.boxes_min_y.unsafe_get(root) &&
    x1 <= self.boxes_max_x.unsafe_get(root) &&
    y1 <= self.boxes_max_y.unsafe_get(root)) {
    return
  }
  if x1 <= self.boxes_min_x.unsafe_get(root) &&
    y1 <= self.boxes_min_y.unsafe_get(root) &&
    x2 >= self.boxes_max_x.unsafe_get(root) &&
    y2 >= self.boxes_max_y.unsafe_get(root) {
    append_leaf_span(self.item_ids, results, 0, self.num_items, 0)
    return
  }
  stack.push(root)
  let mut hits = 0
  while !stack.is_empty() {
    let entry = stack.unsafe_pop()
    let contained = entry < 0
    let node = if contained { entry.lnot() } else { entry }
    if contained {
      hits = self.copy_subtree_leaves(node, results, hits)
      continue
    }
    let offset = self.child_offset.unsafe_get(node)
    let count = self.child_count.unsafe_get(node)
    let first = self.child_indices.unsafe_get(offset)
    if first < self.num_items {
      hits = self.query_leaf_page(
        offset, count, x1, y1, x2, y2, contained, results, hits,
      )
      continue
    }
    for i = offset; i < offset + count; i = i + 1 {
      let child = self.child_indices.unsafe_get(i)
      let cx1 = self.boxes_min_x.unsafe_get(child)
      let cy1 = self.boxes_min_y.unsafe_get(child)
      let cx2 = self.boxes_max_x.unsafe_get(child)
      let cy2 = self.boxes_max_y.unsafe_get(child)
      if contained || (x2 >= cx1 && y2 >= cy1 && x1 <= cx2 && y1 <= cy2) {
        let covers = contained ||
          (x1 <= cx1 && y1 <= cy1 && x2 >= cx2 && y2 >= cy2)
        stack.push(if covers { child.lnot() } else { child })
      }
    }
  }
  results.truncate(hits)
}

///|
/// A depth-first packed subtree has consecutive leaves even across branch pages.
fn StrTree::copy_subtree_leaves(
  self : StrTree,
  node : Int32,
  results : Array[Int32],
  position : Int32,
) -> Int32 {
  let mut first = node
  let mut last = node
  while first >= self.num_items {
    first = self.child_indices.unsafe_get(self.child_offset.unsafe_get(first))
  }
  while last >= self.num_items {
    let offset = self.child_offset.unsafe_get(last)
    let count = self.child_count.unsafe_get(last)
    last = self.child_indices.unsafe_get(offset + count - 1)
  }
  append_leaf_span(self.item_ids, results, first, last + 1, position)
  position + last - first + 1
}
