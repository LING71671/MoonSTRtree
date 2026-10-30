///|
/// Separate bounds audit, outside query timing. Internal bounds are encoded as
/// [minX, minY, maxX, maxY, depth, retained]. Rejected branches are not descended.
pub fn query_bounds(
  tree : @tree.StrTree,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> Array[Double] {
  let window = @geometry.Rect::new(x1, y1, x2, y2)
  let trace : Array[Double] = []
  if tree.num_items() == 0 {
    return trace
  }
  let stack : Array[(Int32, Int32)] = [(tree.root_index(), 0)]
  while stack.pop() is Some((node, depth)) {
    if tree.is_leaf_at(node) {
      continue
    }
    let bounds = tree.node_bounds_at(node)
    let retained = bounds.intersects(window)
    trace.push(bounds.min_x)
    trace.push(bounds.min_y)
    trace.push(bounds.max_x)
    trace.push(bounds.max_y)
    trace.push(depth.to_double())
    trace.push(if retained { 1.0 } else { 0.0 })
    if retained {
      for i = 0; i < tree.child_count_at(node); i = i + 1 {
        stack.push((tree.child_index_at(node, i), depth + 1))
      }
    }
  }
  trace
}
