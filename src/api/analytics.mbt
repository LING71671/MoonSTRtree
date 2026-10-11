///|
/// Result of spatial density-based clustering (DBSCAN).
pub struct ClusterResult {
  labels : Array[Int]
  num_clusters : Int
  num_noise : Int
  cluster_sizes : Array[Int]
} derive(Eq, Debug, Default)

///|
/// A discrete 2D spatial grid cell with item density count and bounding rectangle.
pub struct GridCell {
  col : Int
  row : Int
  count : Int
  bounds : Rect
} derive(Eq, Debug, Default)

///|
/// Aggregated spatial grid density summary and hotspot metrics.
pub struct GridDensitySummary {
  cells : Array[GridCell]
  total_cells : Int
  max_density : Int
  avg_density : Double
  hotspot_cells : Array[GridCell]
} derive(Eq, Debug, Default)

///|
/// Performs spatial index-accelerated Density-Based Spatial Clustering of Applications with Noise (DBSCAN).
pub fn StrTree::dbscan(
  self : StrTree,
  eps : Double,
  min_pts : Int,
) -> ClusterResult {
  let res = self.inner.dbscan(eps, min_pts)
  ClusterResult::{
    labels: res.labels,
    num_clusters: res.num_clusters,
    num_noise: res.num_noise,
    cluster_sizes: res.cluster_sizes,
  }
}

///|
/// Partitions spatial items into uniform rectangular grid cells and computes density distribution.
pub fn StrTree::aggregate_grid(
  self : StrTree,
  cell_width : Double,
  cell_height : Double,
  hotspot_threshold? : Int = 1,
) -> GridDensitySummary {
  let s = self.inner.aggregate_grid(cell_width, cell_height, hotspot_threshold~)
  let cells : Array[GridCell] = []
  for i = 0; i < s.cells.length(); i = i + 1 {
    let c = s.cells[i]
    cells.push(GridCell::{
      col: c.col,
      row: c.row,
      count: c.count,
      bounds: c.bounds,
    })
  }
  let hotspots : Array[GridCell] = []
  for i = 0; i < s.hotspot_cells.length(); i = i + 1 {
    let c = s.hotspot_cells[i]
    hotspots.push(GridCell::{
      col: c.col,
      row: c.row,
      count: c.count,
      bounds: c.bounds,
    })
  }
  GridDensitySummary::{
    cells,
    total_cells: s.total_cells,
    max_density: s.max_density,
    avg_density: s.avg_density,
    hotspot_cells: hotspots,
  }
}

///|
/// Performs spatial index-accelerated 3D DBSCAN clustering.
pub fn StrTree3D::dbscan(
  self : StrTree3D,
  eps : Double,
  min_pts : Int,
) -> ClusterResult {
  let res = self.inner.dbscan(eps, min_pts)
  ClusterResult::{
    labels: res.labels,
    num_clusters: res.num_clusters,
    num_noise: res.num_noise,
    cluster_sizes: res.cluster_sizes,
  }
}

///|
/// DBSCAN result aligned with item_ids instead of allocating up to the largest user ID.
pub struct CompactClusterResult {
  item_ids : Array[Int]
  labels : Array[Int]
  num_clusters : Int
  num_noise : Int
  cluster_sizes : Array[Int]
} derive(Eq, Debug, Default)

///|
fn map_compact_cluster(
  result : @tree.CompactClusterResult,
) -> CompactClusterResult {
  CompactClusterResult::{
    item_ids: result.item_ids,
    labels: result.labels,
    num_clusters: result.num_clusters,
    num_noise: result.num_noise,
    cluster_sizes: result.cluster_sizes,
  }
}

///|
pub fn StrTree::dbscan_compact(
  self : StrTree,
  eps : Double,
  min_pts : Int,
) -> CompactClusterResult {
  map_compact_cluster(self.inner.dbscan_compact(eps, min_pts))
}

///|
pub fn StrTree3D::dbscan_compact(
  self : StrTree3D,
  eps : Double,
  min_pts : Int,
) -> CompactClusterResult {
  map_compact_cluster(self.inner.dbscan_compact(eps, min_pts))
}
