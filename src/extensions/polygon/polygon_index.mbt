// Copyright 2026 Antigravity Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// A packed spatial index managing collections of 2D polygonal planar shapes.
/// Wraps an underlying @tree.StrTree index over polygon bounding envelopes,
/// supporting rapid spatial window queries and Sutherland-Hodgman tile clipping.
pub struct StrPolygonIndex {
  tree : @tree.StrTree
  polygons : Array[Polygon2D]
} derive(Eq, Debug, Default)

///|
/// Builds a packed StrPolygonIndex from an array of 2D polygons and optional node capacity.
pub fn StrPolygonIndex::build(
  polygons : Array[Polygon2D],
  node_capacity? : Int = 16,
) -> StrPolygonIndex {
  let items : Array[(@geometry.Rect, Int)] = []
  for i = 0; i < polygons.length(); i = i + 1 {
    items.push((polygons[i].envelope(), i))
  }
  let tree = @tree.StrTree::build(items, node_capacity~)
  StrPolygonIndex::{ tree, polygons, }
}

///|
/// Returns total count of indexed polygons.
pub fn StrPolygonIndex::total_polygons(self : StrPolygonIndex) -> Int {
  self.polygons.length()
}

///|
/// Returns the global bounding envelope encompassing all indexed polygons.
pub fn StrPolygonIndex::envelope(self : StrPolygonIndex) -> @geometry.Rect {
  self.tree.envelope()
}

///|
/// Queries polygon indices whose bounding envelopes intersect the query window.
pub fn StrPolygonIndex::query_window(
  self : StrPolygonIndex,
  window : @geometry.Rect,
) -> Array[Int] {
  self.tree.query(window)
}

///|
/// Returns the count of candidate polygons intersecting the query window without allocating a result array.
pub fn StrPolygonIndex::query_count(
  self : StrPolygonIndex,
  window : @geometry.Rect,
) -> Int {
  self.tree.query_count(window)
}

///|
/// Retrieves all full Polygon2D instances intersecting the query window.
pub fn StrPolygonIndex::query_polygons(
  self : StrPolygonIndex,
  window : @geometry.Rect,
) -> Array[Polygon2D] {
  let ids = self.tree.query(window)
  let res : Array[Polygon2D] = []
  for i = 0; i < ids.length(); i = i + 1 {
    let id = ids[i]
    if id >= 0 && id < self.polygons.length() {
      res.push(self.polygons[id])
    }
  }
  res
}

///|
/// Hierarchically queries polygons intersecting the window and clips each with Sutherland-Hodgman,
/// returning only valid planar fragments strictly contained inside the window.
pub fn StrPolygonIndex::query_clipped_polygons(
  self : StrPolygonIndex,
  window : @geometry.Rect,
) -> Array[Polygon2D] {
  let ids = self.tree.query(window)
  let res : Array[Polygon2D] = []
  for i = 0; i < ids.length(); i = i + 1 {
    let id = ids[i]
    if id >= 0 && id < self.polygons.length() {
      let clipped = self.polygons[id].clip_rect(window)
      if clipped.vertices.length() >= 3 && clipped.area() > 1.0e-12 {
        res.push(clipped)
      }
    }
  }
  res
}
