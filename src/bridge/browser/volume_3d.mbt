///|
pub fn build_index_3d(
  coordinates : Array[Double],
  capacity : Int32,
) -> @tree.StrTree3D {
  guard coordinates.length() % 6 == 0 else {
    abort("Expected six coordinates per box")
  }
  let items = Array::makei(coordinates.length() / 6, fn(i) {
    let p = i * 6
    (
      @geometry.Box3D::new(
        coordinates[p],
        coordinates[p + 1],
        coordinates[p + 2],
        coordinates[p + 3],
        coordinates[p + 4],
        coordinates[p + 5],
      ),
      i,
    )
  })
  @tree.StrTree3D::build(items, node_capacity=capacity)
}

///|
pub fn query_range_3d(
  tree : @tree.StrTree3D,
  x1 : Double,
  y1 : Double,
  z1 : Double,
  x2 : Double,
  y2 : Double,
  z2 : Double,
) -> Array[Int32] {
  tree.query(@geometry.Box3D::new(x1, y1, z1, x2, y2, z2))
}

///|
pub fn query_point_3d(
  tree : @tree.StrTree3D,
  x : Double,
  y : Double,
  z : Double,
) -> Array[Int32] {
  tree.query_point(x, y, z)
}

///|
pub fn query_knn_3d(
  tree : @tree.StrTree3D,
  x : Double,
  y : Double,
  z : Double,
  k : Int32,
) -> Array[Int32] {
  tree.query_knn(x, y, z, k)
}

///|
pub fn query_sphere(
  tree : @tree.StrTree3D,
  x : Double,
  y : Double,
  z : Double,
  radius : Double,
) -> Array[Int32] {
  tree.query_sphere(x, y, z, radius)
}

///|
pub fn query_segment_3d(
  tree : @tree.StrTree3D,
  x1 : Double,
  y1 : Double,
  z1 : Double,
  x2 : Double,
  y2 : Double,
  z2 : Double,
) -> Array[Int32] {
  tree.query_segment(x1, y1, z1, x2, y2, z2)
}

///|
pub fn index_stats_3d(tree : @tree.StrTree3D) -> Array[Double] {
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
/// Internal volumes are [minX,minY,minZ,maxX,maxY,maxZ,depth].
pub fn index_boxes_3d(tree : @tree.StrTree3D) -> Array[Double] {
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
    boxes.push(box.max_x)
    boxes.push(box.max_y)
    boxes.push(box.max_z)
    boxes.push(depth.to_double())
    for i = 0; i < tree.child_count_at(node); i = i + 1 {
      stack.push((tree.child_index_at(node, i), depth + 1))
    }
  }
  boxes
}
