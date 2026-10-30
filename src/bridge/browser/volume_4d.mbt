///|
pub fn build_index_4d(
  coordinates : Array[Double],
  capacity : Int32,
) -> @tree.StrTree4D {
  guard coordinates.length() % 8 == 0 else {
    abort("Expected eight coordinates per box")
  }
  let items = Array::makei(coordinates.length() / 8, fn(i) {
    let p = i * 8
    (
      @geometry.Box4D::new(
        coordinates[p],
        coordinates[p + 1],
        coordinates[p + 2],
        coordinates[p + 3],
        coordinates[p + 4],
        coordinates[p + 5],
        coordinates[p + 6],
        coordinates[p + 7],
      ),
      i,
    )
  })
  @tree.StrTree4D::build(items, node_capacity=capacity)
}

///|
pub fn query_range_4d(
  tree : @tree.StrTree4D,
  x1 : Double,
  y1 : Double,
  z1 : Double,
  t1 : Double,
  x2 : Double,
  y2 : Double,
  z2 : Double,
  t2 : Double,
) -> Array[Int32] {
  tree.query(@geometry.Box4D::new(x1, y1, z1, t1, x2, y2, z2, t2))
}

///|
pub fn query_point_4d(
  tree : @tree.StrTree4D,
  x : Double,
  y : Double,
  z : Double,
  t : Double,
) -> Array[Int32] {
  tree.query_point(x, y, z, t)
}

///|
pub fn query_time_slice(
  tree : @tree.StrTree4D,
  t : Double,
  x1 : Double,
  y1 : Double,
  z1 : Double,
  x2 : Double,
  y2 : Double,
  z2 : Double,
) -> Array[Int32] {
  tree.query_time_slice(t, @geometry.Box3D::new(x1, y1, z1, x2, y2, z2))
}

///|
pub fn index_stats_4d(tree : @tree.StrTree4D) -> Array[Double] {
  let stats = tree.stats()
  [
    stats.num_items.to_double(),
    stats.num_nodes.to_double(),
    stats.height.to_double(),
    stats.fill_factor,
    stats.estimated_memory_bytes.to_double(),
  ]
}

///|
/// Internal bounds are [minX,minY,minZ,minT,maxX,maxY,maxZ,maxT,depth].
pub fn index_boxes_4d(tree : @tree.StrTree4D) -> Array[Double] {
  let boxes : Array[Double] = []
  if tree.num_items() == 0 {
    return boxes
  }
  let stack : Array[(Int32, Int32)] = [(tree.root_index(), 0)]
  while stack.pop() is Some((node, depth)) {
    if tree.is_leaf_at(node) {
      continue
    }
    let box = tree.node_bounds_at(node)
    boxes.push(box.min_x)
    boxes.push(box.min_y)
    boxes.push(box.min_z)
    boxes.push(box.min_t)
    boxes.push(box.max_x)
    boxes.push(box.max_y)
    boxes.push(box.max_z)
    boxes.push(box.max_t)
    boxes.push(depth.to_double())
    for i = 0; i < tree.child_count_at(node); i = i + 1 {
      stack.push((tree.child_index_at(node, i), depth + 1))
    }
  }
  boxes
}
