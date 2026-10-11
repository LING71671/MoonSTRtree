///|
/// Browser host boundary. JavaScript passes coordinates; MoonBit owns the index.
pub fn build_index(
  coordinates : Array[Double],
  capacity : Int,
) -> @tree.StrTree {
  @tree.StrTree::build_coordinates(coordinates, node_capacity=capacity)
}

///|
pub fn query_range(
  tree : @tree.StrTree,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> Array[Int] {
  tree.query(@geometry.Rect::new(x1, y1, x2, y2))
}

///|
pub fn query_point(tree : @tree.StrTree, x : Double, y : Double) -> Array[Int] {
  tree.query_point(x, y)
}

///|
pub fn query_knn(
  tree : @tree.StrTree,
  x : Double,
  y : Double,
  k : Int,
) -> Array[Int] {
  tree.query_knn(x, y, k)
}

///|
pub fn query_segment(
  tree : @tree.StrTree,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> Array[Int] {
  tree.query_segment(x1, y1, x2, y2)
}

///|
pub fn query_circle(
  tree : @tree.StrTree,
  x : Double,
  y : Double,
  radius : Double,
) -> Array[Int] {
  tree.query_circle(x, y, radius)
}

///|
/// Numeric payload estimates exclude runtime overhead and temporary allocations.
pub fn index_stats(tree : @tree.StrTree) -> Array[Double] {
  let nodes = tree.num_nodes()
  let mut branches = 0
  for i = 0; i < nodes; i = i + 1 {
    if !tree.is_leaf_at(i) {
      branches = branches + 1
    }
  }
  let edges = tree.total_edges()
  let fill = if branches == 0 {
    1.0
  } else {
    edges.to_double() /
    (branches.to_double() * tree.node_capacity().to_double())
  }
  [
    tree.num_items().to_double(),
    nodes.to_double(),
    tree.height().to_double(),
    fill,
    (nodes * 44 + edges * 4).to_double(),
  ]
}

///|
/// Each internal MBR is encoded as [minX, minY, maxX, maxY, depth].
pub fn index_boxes(tree : @tree.StrTree) -> Array[Double] {
  let boxes : Array[Double] = []
  if tree.num_items() == 0 {
    return boxes
  }
  let stack : Array[(Int, Int)] = [(tree.root_index(), 0)]
  while stack.pop() is Some((node, depth)) {
    if tree.is_leaf_at(node) {
      continue
    }
    let rect = tree.node_bounds_at(node)
    boxes.push(rect.min_x)
    boxes.push(rect.min_y)
    boxes.push(rect.max_x)
    boxes.push(rect.max_y)
    boxes.push(depth.to_double())
    for i = 0; i < tree.child_count_at(node); i = i + 1 {
      stack.push((tree.child_index_at(node, i), depth + 1))
    }
  }
  boxes
}
