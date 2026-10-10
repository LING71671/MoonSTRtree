///|
/// Axis-Aligned Bounding Box (AABB) in continuous 2D space.
pub struct Rect {
  min_x : Double
  min_y : Double
  max_x : Double
  max_y : Double
} derive(Eq, Debug, Default)

///|
/// Converts to internal geometry primitive.
fn Rect::to_geometry(self : Rect) -> @geometry.Rect {
  @geometry.Rect::new(self.min_x, self.min_y, self.max_x, self.max_y)
}

///|
/// Constructs a new normalized Rect where min_x <= max_x and min_y <= max_y.
pub fn Rect::new(
  min_x : Double,
  min_y : Double,
  max_x : Double,
  max_y : Double,
) -> Rect {
  let g = @geometry.Rect::new(min_x, min_y, max_x, max_y)
  Rect::{ min_x: g.min_x, min_y: g.min_y, max_x: g.max_x, max_y: g.max_y, }
}

///|
/// Constructs a degenerate zero-area rectangle centered at (x, y).
pub fn Rect::from_point(x : Double, y : Double) -> Rect {
  let g = @geometry.Rect::from_point(x, y)
  Rect::{ min_x: g.min_x, min_y: g.min_y, max_x: g.max_x, max_y: g.max_y, }
}

///|
/// Returns true if this rectangle intersects or touches another rectangle.
pub fn Rect::intersects(self : Rect, other : Rect) -> Bool {
  self.to_geometry().intersects(other.to_geometry())
}

///|
/// Returns true if point (x, y) is contained within this rectangle.
pub fn Rect::contains_point(self : Rect, x : Double, y : Double) -> Bool {
  self.to_geometry().contains_point(x, y)
}

///|
/// Returns true if this rectangle completely contains another rectangle.
pub fn Rect::contains_rect(self : Rect, other : Rect) -> Bool {
  self.to_geometry().contains_rect(other.to_geometry())
}

///|
/// Returns the Minimum Bounding Rectangle (MBR) enclosing both rectangles.
pub fn Rect::union(self : Rect, other : Rect) -> Rect {
  let u = self.to_geometry().union(other.to_geometry())
  Rect::{ min_x: u.min_x, min_y: u.min_y, max_x: u.max_x, max_y: u.max_y, }
}

///|
/// Comprehensive structural and memory diagnostics for a packed StrTree.
pub struct TreeStats {
  num_items : Int
  num_nodes : Int
  height : Int
  node_capacity : Int
  fill_factor : Double
  leaf_nodes : Int
  branch_nodes : Int
  total_edges : Int
  estimated_memory_bytes : Int
} derive(Eq, Debug, Default)

///|
/// Packed 2D spatial index tree with contiguous flat array storage.
pub struct StrTree {
  inner : @tree.StrTree
} derive(Eq, Debug, Default)

///|
/// Builds a packed StrTree from an array of (Rect, ID) pairs and optional node capacity.
pub fn StrTree::build(
  items : Array[(Rect, Int)],
  node_capacity? : Int = 16,
) -> StrTree {
  let g_items : Array[(@geometry.Rect, Int)] = []
  for i = 0; i < items.length(); i = i + 1 {
    let (r, id) = items[i]
    g_items.push((r.to_geometry(), id))
  }
  let inner = @tree.StrTree::build(g_items, node_capacity~)
  StrTree::{ inner, }
}

///|
/// Performs axis-aligned bounding box range intersection query using iterative stack DFS.
pub fn StrTree::query(self : StrTree, search_window : Rect) -> Array[Int] {
  self.inner.query(search_window.to_geometry())
}

///|
/// Performs point inclusion query using iterative stack DFS.
pub fn StrTree::query_point(
  self : StrTree,
  x : Double,
  y : Double,
) -> Array[Int] {
  self.inner.query_point(x, y)
}

///|
/// Computes structural diagnostic metrics from a StrTree.
pub fn StrTree::stats(self : StrTree) -> TreeStats {
  let s = @stats.TreeStats::compute(self.inner)
  TreeStats::{
    num_items: s.num_items,
    num_nodes: s.num_nodes,
    height: s.height,
    node_capacity: s.node_capacity,
    fill_factor: s.fill_factor,
    leaf_nodes: s.leaf_nodes,
    branch_nodes: s.branch_nodes,
    total_edges: s.total_edges,
    estimated_memory_bytes: s.estimated_memory_bytes,
  }
}
