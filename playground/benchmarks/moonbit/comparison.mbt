///|
/// Both implementations ingest the same flat input and use node capacity 16.
pub fn build_moon(coordinates : FixedArray[Double]) -> @spatial.StrTree {
  @spatial.StrTree::build_coordinates(
    Array::from_fixed_array(coordinates),
    node_capacity=16,
  )
}

///|
pub fn build_geo(coordinates : FixedArray[Double]) -> @geo.RTree[Int32] {
  let entries = Array::makei(coordinates.length() / 4, fn(id) {
    let offset = id * 4
    @geo.Entry::Entry(
      @geo_type.Rect::Rect(
        @geo_type.Coord(coordinates[offset], coordinates[offset + 1]),
        @geo_type.Coord(coordinates[offset + 2], coordinates[offset + 3]),
      ),
      id,
    )
  })
  @geo.RTree::bulk_load(entries)
}

///|
pub fn range_moon(
  tree : @spatial.StrTree,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> FixedArray[Int32] {
  host_array(tree.query(@spatial.Rect::new(x1, y1, x2, y2)))
}

///|
pub fn range_geo(
  tree : @geo.RTree[Int32],
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> FixedArray[Int32] {
  host_array(
    tree.query_rect_intersection(
      @geo_type.Rect::Rect(@geo_type.Coord(x1, y1), @geo_type.Coord(x2, y2)),
    ),
  )
}

///|
pub fn point_moon(
  tree : @spatial.StrTree,
  x : Double,
  y : Double,
) -> FixedArray[Int32] {
  host_array(tree.query_point(x, y))
}

///|
pub fn point_geo(
  tree : @geo.RTree[Int32],
  x : Double,
  y : Double,
) -> FixedArray[Int32] {
  host_array(tree.locate_at_point(@geo_type.Coord(x, y)))
}

///|
pub fn knn_moon(
  tree : @spatial.StrTree,
  x : Double,
  y : Double,
  k : Int32,
) -> FixedArray[Int32] {
  host_array(tree.query_knn(x, y, k))
}

///|
pub fn knn_geo(
  tree : @geo.RTree[Int32],
  x : Double,
  y : Double,
  k : Int32,
) -> FixedArray[Int32] {
  if k == 1 {
    // Use the specialized single-nearest API instead of sorting every entry.
    match tree.query_nearest(@geo_type.Coord(x, y)) {
      Some(id) => [id]
      None => []
    }
  } else {
    host_array(tree.nearest_neighbors(@geo_type.Coord(x, y), Some(k)))
  }
}

///|
pub fn circle_moon(
  tree : @spatial.StrTree,
  x : Double,
  y : Double,
  radius : Double,
) -> FixedArray[Int32] {
  host_array(tree.query_circle(x, y, radius))
}

///|
pub fn circle_geo(
  tree : @geo.RTree[Int32],
  x : Double,
  y : Double,
  radius : Double,
) -> FixedArray[Int32] {
  host_array(tree.locate_within_distance(@geo_type.Coord(x, y), radius))
}

///|
pub fn segment_moon(
  tree : @spatial.StrTree,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> FixedArray[Int32] {
  host_array(tree.query_segment(x1, y1, x2, y2))
}
