///|
/// Legacy DBSCAN result. labels is indexed by non-negative item ID.
pub struct ClusterResult {
  labels : Array[Int]
  num_clusters : Int
  num_noise : Int
  cluster_sizes : Array[Int]
} derive(Eq, Debug, Default)

///|
/// DBSCAN result with one label per stored item, including duplicate or sparse IDs.
pub struct CompactClusterResult {
  item_ids : Array[Int]
  labels : Array[Int]
  num_clusters : Int
  num_noise : Int
  cluster_sizes : Array[Int]
} derive(Eq, Debug, Default)

///|
/// Expands each point at most once and keeps the pending queue bounded by item count.
fn cluster_neighbors(
  ids : Array[Int],
  min_pts : Int,
  neighbors : (Int) -> Array[Int],
) -> CompactClusterResult {
  let n = ids.length()
  let minimum = if min_pts < 1 { 1 } else { min_pts }
  let labels = Array::make(n, -2)
  let queued = Array::make(n, false)
  let mut num_clusters = 0
  for i = 0; i < n; i = i + 1 {
    if labels[i] != -2 {
      continue
    }
    let nearby = neighbors(i)
    if nearby.length() < minimum {
      labels[i] = -1
      continue
    }
    labels[i] = num_clusters
    let queue : Array[Int] = []
    let enqueue = fn(candidates : Array[Int]) {
      for candidate in candidates {
        if labels[candidate] < 0 && !queued[candidate] {
          queued[candidate] = true
          queue.push(candidate)
        }
      }
    }
    enqueue(nearby)
    let mut head = 0
    while head < queue.length() {
      let next = queue[head]
      head = head + 1
      if labels[next] == -1 {
        labels[next] = num_clusters
      } else if labels[next] == -2 {
        labels[next] = num_clusters
        let adjacent = neighbors(next)
        if adjacent.length() >= minimum {
          enqueue(adjacent)
        }
      }
    }
    num_clusters = num_clusters + 1
  }
  let sizes = Array::make(num_clusters, 0)
  let mut noise = 0
  for label in labels {
    if label < 0 {
      noise = noise + 1
    } else {
      sizes[label] = sizes[label] + 1
    }
  }
  CompactClusterResult::{
    item_ids: ids,
    labels,
    num_clusters,
    num_noise: noise,
    cluster_sizes: sizes,
  }
}

///|
/// Converts to the legacy ID-addressed representation; sparse IDs require a large array.
fn CompactClusterResult::to_legacy(
  self : CompactClusterResult,
) -> ClusterResult {
  let mut maximum = -1
  for id in self.item_ids {
    if id > maximum {
      maximum = id
    }
  }
  let labels = Array::make(maximum + 1, -1)
  for i = 0; i < self.item_ids.length(); i = i + 1 {
    labels[self.item_ids[i]] = self.labels[i]
  }
  ClusterResult::{
    labels,
    num_clusters: self.num_clusters,
    num_noise: self.num_noise,
    cluster_sizes: self.cluster_sizes,
  }
}

///|
/// Clusters item centers using stable internal positions; storage is O(number of items).
pub fn StrTree::dbscan_compact(
  self : StrTree,
  eps : Double,
  min_pts : Int,
) -> CompactClusterResult {
  let ids : Array[Int] = []
  let centers_x : Array[Double] = []
  let centers_y : Array[Double] = []
  for node = 0; node < self.boxes_min_x.length(); node = node + 1 {
    if self.child_count[node] == 0 && self.item_ids[node] >= 0 {
      ids.push(self.item_ids[node])
      centers_x.push(
        self.boxes_min_x[node] * 0.5 + self.boxes_max_x[node] * 0.5,
      )
      centers_y.push(
        self.boxes_min_y[node] * 0.5 + self.boxes_max_y[node] * 0.5,
      )
    }
  }
  let points = Array::makei(ids.length(), fn(i) {
    (@geometry.Rect::from_point(centers_x[i], centers_y[i]), i)
  })
  let centers = StrTree::build(points, node_capacity=self.node_capacity)
  cluster_neighbors(ids, min_pts, fn(i) {
    centers.query_circle(centers_x[i], centers_y[i], eps)
  })
}

///|
/// Legacy ID-addressed DBSCAN; prefer dbscan_compact for sparse or duplicate IDs.
pub fn StrTree::dbscan(
  self : StrTree,
  eps : Double,
  min_pts : Int,
) -> ClusterResult {
  self.dbscan_compact(eps, min_pts).to_legacy()
}

///|
/// Clusters item centers using stable internal positions; storage is O(number of items).
pub fn StrTree3D::dbscan_compact(
  self : StrTree3D,
  eps : Double,
  min_pts : Int,
) -> CompactClusterResult {
  let ids : Array[Int] = []
  let centers_x : Array[Double] = []
  let centers_y : Array[Double] = []
  let centers_z : Array[Double] = []
  for node = 0; node < self.boxes_min_x.length(); node = node + 1 {
    if self.child_count[node] == 0 && self.item_ids[node] >= 0 {
      ids.push(self.item_ids[node])
      centers_x.push(
        self.boxes_min_x[node] * 0.5 + self.boxes_max_x[node] * 0.5,
      )
      centers_y.push(
        self.boxes_min_y[node] * 0.5 + self.boxes_max_y[node] * 0.5,
      )
      centers_z.push(
        self.boxes_min_z[node] * 0.5 + self.boxes_max_z[node] * 0.5,
      )
    }
  }
  let points = Array::makei(ids.length(), fn(i) {
    (@geometry.Box3D::from_point(centers_x[i], centers_y[i], centers_z[i]), i)
  })
  let centers = StrTree3D::build(points, node_capacity=self.node_capacity)
  cluster_neighbors(ids, min_pts, fn(i) {
    centers.query_sphere(centers_x[i], centers_y[i], centers_z[i], eps)
  })
}

///|
/// Legacy ID-addressed DBSCAN; prefer dbscan_compact for sparse or duplicate IDs.
pub fn StrTree3D::dbscan(
  self : StrTree3D,
  eps : Double,
  min_pts : Int,
) -> ClusterResult {
  self.dbscan_compact(eps, min_pts).to_legacy()
}
