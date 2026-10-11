///|
/// A 2D point coordinate representing a polygon vertex.
pub struct Point2D {
  x : Double
  y : Double
} derive(Eq, Debug, Default)

///|
/// Creates a new 2D point coordinate.
pub fn Point2D::new(x : Double, y : Double) -> Point2D {
  Point2D::{ x, y, }
}

///|
/// Computes Euclidean distance to another 2D point.
pub fn Point2D::distance_to(self : Point2D, other : Point2D) -> Double {
  let dx = self.x - other.x
  let dy = self.y - other.y
  (dx * dx + dy * dy).sqrt()
}

///|
/// A 2D polygonal planar curve or ring defined by sequential vertices.
pub struct Polygon2D {
  vertices : Array[Point2D]
} derive(Eq, Debug, Default)

///|
/// Creates a new Polygon2D from an ordered array of 2D vertices.
pub fn Polygon2D::new(vertices : Array[Point2D]) -> Polygon2D {
  Polygon2D::{ vertices, }
}

///|
fn Polygon2D::to_tree(self : Polygon2D) -> @polygon.Polygon2D {
  let vs : Array[@polygon.Point2D] = []
  for i = 0; i < self.vertices.length(); i = i + 1 {
    let p = self.vertices[i]
    vs.push(@polygon.Point2D::new(p.x, p.y))
  }
  @polygon.Polygon2D::new(vs)
}

///|
fn Polygon2D::from_tree(poly : @polygon.Polygon2D) -> Polygon2D {
  let vs : Array[Point2D] = []
  for i = 0; i < poly.vertices.length(); i = i + 1 {
    let p = poly.vertices[i]
    vs.push(Point2D::new(p.x, p.y))
  }
  Polygon2D::new(vs)
}

///|
/// Computes the planar signed/unsigned area using Green's theorem / Shoelace formula.
pub fn Polygon2D::area(self : Polygon2D) -> Double {
  self.to_tree().area()
}

///|
/// Computes total boundary perimeter length of the closed polygon.
pub fn Polygon2D::perimeter(self : Polygon2D) -> Double {
  self.to_tree().perimeter()
}

///|
/// Returns the minimum axis-aligned bounding box (AABB) enveloping all vertices.
pub fn Polygon2D::envelope(self : Polygon2D) -> Rect {
  let r = self.to_tree().envelope()
  Rect::new(r.min_x, r.min_y, r.max_x, r.max_y)
}

///|
/// Tests whether a point (px, py) is contained within the polygon boundary.
pub fn Polygon2D::contains_point(
  self : Polygon2D,
  px : Double,
  py : Double,
) -> Bool {
  self.to_tree().contains_point(px, py)
}

///|
/// Computes the planar geometric centroid of the polygon.
pub fn Polygon2D::centroid(self : Polygon2D) -> Point2D {
  let c = self.to_tree().centroid()
  Point2D::new(c.x, c.y)
}

///|
/// Sutherland-Hodgman polygon clipping against an axis-aligned rectangular bounding box.
pub fn Polygon2D::clip_rect(self : Polygon2D, clip_box : Rect) -> Polygon2D {
  let res = self.to_tree().clip_rect(clip_box)
  Polygon2D::from_tree(res)
}

///|
/// Sutherland-Hodgman polygon clipping against an arbitrary convex polygon.
pub fn Polygon2D::clip_convex(
  self : Polygon2D,
  clip_poly : Polygon2D,
) -> Polygon2D {
  let res = self.to_tree().clip_convex(clip_poly.to_tree())
  Polygon2D::from_tree(res)
}

///|
/// A packed spatial index managing collections of 2D polygonal planar shapes.
pub struct StrPolygonIndex {
  priv inner : @polygon.StrPolygonIndex
} derive(Eq, Debug, Default)

///|
/// Builds a packed StrPolygonIndex from an array of 2D polygons and optional node capacity.
pub fn StrPolygonIndex::build(
  polygons : Array[Polygon2D],
  node_capacity? : Int = 16,
) -> StrPolygonIndex {
  let t_polys : Array[@polygon.Polygon2D] = []
  for i = 0; i < polygons.length(); i = i + 1 {
    t_polys.push(polygons[i].to_tree())
  }
  let inner = @polygon.StrPolygonIndex::build(t_polys, node_capacity~)
  StrPolygonIndex::{ inner, }
}

///|
/// Returns total count of indexed polygons.
pub fn StrPolygonIndex::total_polygons(self : StrPolygonIndex) -> Int {
  self.inner.total_polygons()
}

///|
/// Returns the global bounding envelope encompassing all indexed polygons.
pub fn StrPolygonIndex::envelope(self : StrPolygonIndex) -> Rect {
  let r = self.inner.envelope()
  Rect::new(r.min_x, r.min_y, r.max_x, r.max_y)
}

///|
/// Queries polygon indices whose bounding envelopes intersect the query window.
pub fn StrPolygonIndex::query_window(
  self : StrPolygonIndex,
  window : Rect,
) -> Array[Int] {
  self.inner.query_window(window)
}

///|
/// Returns the count of candidate polygons intersecting the query window without allocating a result array.
pub fn StrPolygonIndex::query_count(
  self : StrPolygonIndex,
  window : Rect,
) -> Int {
  self.inner.query_count(window)
}

///|
/// Retrieves all full Polygon2D instances intersecting the query window.
pub fn StrPolygonIndex::query_polygons(
  self : StrPolygonIndex,
  window : Rect,
) -> Array[Polygon2D] {
  let polys = self.inner.query_polygons(window)
  let res : Array[Polygon2D] = []
  for i = 0; i < polys.length(); i = i + 1 {
    res.push(Polygon2D::from_tree(polys[i]))
  }
  res
}

///|
/// Hierarchically queries polygons intersecting the window and clips each with Sutherland-Hodgman,
/// returning only valid planar fragments strictly contained inside the window.
pub fn StrPolygonIndex::query_clipped_polygons(
  self : StrPolygonIndex,
  window : Rect,
) -> Array[Polygon2D] {
  let polys = self.inner.query_clipped_polygons(window)
  let res : Array[Polygon2D] = []
  for i = 0; i < polys.length(); i = i + 1 {
    res.push(Polygon2D::from_tree(polys[i]))
  }
  res
}
