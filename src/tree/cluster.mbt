///|
/// Result of spatial density-based clustering (DBSCAN).
pub struct ClusterResult {
  labels : Array[Int]
  num_clusters : Int
  num_noise : Int
  cluster_sizes : Array[Int]
} derive(Eq, Debug, Default)

///|
/// Helper for ID to index mapping.
fn binary_search_id(sorted_ids : Array[(Int, Int)], target : Int) -> Int {
  let mut low = 0
  let mut high = sorted_ids.length() - 1
  while low <= high {
    let mid = (low + high) / 2
    let (id, idx) = sorted_ids[mid]
    if id == target {
      return idx
    } else if id < target {
      low = mid + 1
    } else {
      high = mid - 1
    }
  }
  -1
}

///|
/// Performs spatial index-accelerated Density-Based Spatial Clustering of Applications with Noise (DBSCAN).
/// eps: maximum neighborhood radius.
/// min_pts: minimum number of points required to form a dense region (core point).
pub fn StrTree::dbscan(
  self : StrTree,
  eps : Double,
  min_pts : Int,
) -> ClusterResult {
  if self.root_index < 0 || self.num_items == 0 {
    return ClusterResult::{
      labels: [],
      num_clusters: 0,
      num_noise: 0,
      cluster_sizes: [],
    }
  }

  let min_pts_clamped = if min_pts < 1 { 1 } else { min_pts }
  let eps_sq = eps * eps

  // Collect leaf item centers and IDs
  let leaf_ids : Array[Int] = []
  let centers_x : Array[Double] = []
  let centers_y : Array[Double] = []

  let mut max_id = 0
  for i = 0; i < self.boxes_min_x.length(); i = i + 1 {
    if self.child_count[i] == 0 {
      let id = self.item_ids[i]
      if id >= 0 {
        leaf_ids.push(id)
        centers_x.push((self.boxes_min_x[i] + self.boxes_max_x[i]) * 0.5)
        centers_y.push((self.boxes_min_y[i] + self.boxes_max_y[i]) * 0.5)
        if id > max_id {
          max_id = id
        }
      }
    }
  }

  let n = leaf_ids.length()
  if n == 0 {
    return ClusterResult::{
      labels: [],
      num_clusters: 0,
      num_noise: 0,
      cluster_sizes: [],
    }
  }

  // Build fast ID lookup
  let use_flat_lookup = max_id < n * 4 + 1024
  let flat_lookup = if use_flat_lookup {
    let arr = Array::make(max_id + 1, -1)
    for i = 0; i < n; i = i + 1 {
      arr[leaf_ids[i]] = i
    }
    arr
  } else {
    []
  }

  let sorted_id_pairs : Array[(Int, Int)] = if use_flat_lookup {
    []
  } else {
    let pairs : Array[(Int, Int)] = []
    for i = 0; i < n; i = i + 1 {
      pairs.push((leaf_ids[i], i))
    }
    pairs.sort_by(fn(a, b) { a.0 - b.0 })
    pairs
  }

  let lookup_idx = fn(target_id : Int) -> Int {
    if target_id < 0 {
      -1
    } else if use_flat_lookup {
      if target_id < flat_lookup.length() {
        flat_lookup[target_id]
      } else {
        -1
      }
    } else {
      binary_search_id(sorted_id_pairs, target_id)
    }
  }

  let labels : Array[Int] = Array::make(n, -2) // -2: unvisited, -1: noise, >= 0: cluster ID
  let mut current_cluster = 0

  for i = 0; i < n; i = i + 1 {
    if labels[i] != -2 {
      continue
    }

    let cx = centers_x[i]
    let cy = centers_y[i]
    let cand_ids = self.query_circle(cx, cy, eps)
    let core_neighbors : Array[Int] = []

    for k = 0; k < cand_ids.length(); k = k + 1 {
      let idx = lookup_idx(cand_ids[k])
      if idx >= 0 {
        let dx = cx - centers_x[idx]
        let dy = cy - centers_y[idx]
        if dx * dx + dy * dy <= eps_sq {
          core_neighbors.push(idx)
        }
      }
    }

    if core_neighbors.length() < min_pts_clamped {
      labels[i] = -1
    } else {
      labels[i] = current_cluster
      let queue : Array[Int] = []
      for k = 0; k < core_neighbors.length(); k = k + 1 {
        let nb_idx = core_neighbors[k]
        if nb_idx != i {
          queue.push(nb_idx)
        }
      }

      let mut head = 0
      while head < queue.length() {
        let q_idx = queue[head]
        head = head + 1

        if labels[q_idx] == -1 {
          labels[q_idx] = current_cluster
        }
        if labels[q_idx] != -2 {
          continue
        }

        labels[q_idx] = current_cluster

        let q_cx = centers_x[q_idx]
        let q_cy = centers_y[q_idx]
        let q_cand_ids = self.query_circle(q_cx, q_cy, eps)
        let q_core_neighbors : Array[Int] = []

        for k = 0; k < q_cand_ids.length(); k = k + 1 {
          let idx = lookup_idx(q_cand_ids[k])
          if idx >= 0 {
            let dx = q_cx - centers_x[idx]
            let dy = q_cy - centers_y[idx]
            if dx * dx + dy * dy <= eps_sq {
              q_core_neighbors.push(idx)
            }
          }
        }

        if q_core_neighbors.length() >= min_pts_clamped {
          for k = 0; k < q_core_neighbors.length(); k = k + 1 {
            let n_idx = q_core_neighbors[k]
            if labels[n_idx] == -2 || labels[n_idx] == -1 {
              queue.push(n_idx)
            }
          }
        }
      }

      current_cluster = current_cluster + 1
    }
  }

  let num_clusters = current_cluster
  let mut num_noise = 0
  let cluster_sizes = Array::make(num_clusters, 0)
  let labels_by_id = Array::make(max_id + 1, -1)
  for i = 0; i < n; i = i + 1 {
    let lbl = labels[i]
    let id = leaf_ids[i]
    labels_by_id[id] = lbl
    if lbl < 0 {
      num_noise = num_noise + 1
    } else {
      cluster_sizes[lbl] = cluster_sizes[lbl] + 1
    }
  }

  ClusterResult::{
    labels: labels_by_id,
    num_clusters,
    num_noise,
    cluster_sizes,
  }
}

///|
/// Performs spatial index-accelerated 3D DBSCAN clustering.
pub fn StrTree3D::dbscan(
  self : StrTree3D,
  eps : Double,
  min_pts : Int,
) -> ClusterResult {
  if self.root_index < 0 || self.num_items == 0 {
    return ClusterResult::{
      labels: [],
      num_clusters: 0,
      num_noise: 0,
      cluster_sizes: [],
    }
  }

  let min_pts_clamped = if min_pts < 1 { 1 } else { min_pts }
  let eps_sq = eps * eps

  let leaf_ids : Array[Int] = []
  let centers_x : Array[Double] = []
  let centers_y : Array[Double] = []
  let centers_z : Array[Double] = []

  let mut max_id = 0
  for i = 0; i < self.boxes_min_x.length(); i = i + 1 {
    if self.child_count[i] == 0 {
      let id = self.item_ids[i]
      if id >= 0 {
        leaf_ids.push(id)
        centers_x.push((self.boxes_min_x[i] + self.boxes_max_x[i]) * 0.5)
        centers_y.push((self.boxes_min_y[i] + self.boxes_max_y[i]) * 0.5)
        centers_z.push((self.boxes_min_z[i] + self.boxes_max_z[i]) * 0.5)
        if id > max_id {
          max_id = id
        }
      }
    }
  }

  let n = leaf_ids.length()
  if n == 0 {
    return ClusterResult::{
      labels: [],
      num_clusters: 0,
      num_noise: 0,
      cluster_sizes: [],
    }
  }

  let use_flat_lookup = max_id < n * 4 + 1024
  let flat_lookup = if use_flat_lookup {
    let arr = Array::make(max_id + 1, -1)
    for i = 0; i < n; i = i + 1 {
      arr[leaf_ids[i]] = i
    }
    arr
  } else {
    []
  }

  let sorted_id_pairs : Array[(Int, Int)] = if use_flat_lookup {
    []
  } else {
    let pairs : Array[(Int, Int)] = []
    for i = 0; i < n; i = i + 1 {
      pairs.push((leaf_ids[i], i))
    }
    pairs.sort_by(fn(a, b) { a.0 - b.0 })
    pairs
  }

  let lookup_idx = fn(target_id : Int) -> Int {
    if target_id < 0 {
      -1
    } else if use_flat_lookup {
      if target_id < flat_lookup.length() {
        flat_lookup[target_id]
      } else {
        -1
      }
    } else {
      binary_search_id(sorted_id_pairs, target_id)
    }
  }

  let labels : Array[Int] = Array::make(n, -2)
  let mut current_cluster = 0

  for i = 0; i < n; i = i + 1 {
    if labels[i] != -2 {
      continue
    }

    let cx = centers_x[i]
    let cy = centers_y[i]
    let cz = centers_z[i]
    let cand_ids = self.query_sphere(cx, cy, cz, eps)
    let core_neighbors : Array[Int] = []

    for k = 0; k < cand_ids.length(); k = k + 1 {
      let idx = lookup_idx(cand_ids[k])
      if idx >= 0 {
        let dx = cx - centers_x[idx]
        let dy = cy - centers_y[idx]
        let dz = cz - centers_z[idx]
        if dx * dx + dy * dy + dz * dz <= eps_sq {
          core_neighbors.push(idx)
        }
      }
    }

    if core_neighbors.length() < min_pts_clamped {
      labels[i] = -1
    } else {
      labels[i] = current_cluster
      let queue : Array[Int] = []
      for k = 0; k < core_neighbors.length(); k = k + 1 {
        let nb_idx = core_neighbors[k]
        if nb_idx != i {
          queue.push(nb_idx)
        }
      }

      let mut head = 0
      while head < queue.length() {
        let q_idx = queue[head]
        head = head + 1

        if labels[q_idx] == -1 {
          labels[q_idx] = current_cluster
        }
        if labels[q_idx] != -2 {
          continue
        }

        labels[q_idx] = current_cluster

        let q_cx = centers_x[q_idx]
        let q_cy = centers_y[q_idx]
        let q_cz = centers_z[q_idx]
        let q_cand_ids = self.query_sphere(q_cx, q_cy, q_cz, eps)
        let q_core_neighbors : Array[Int] = []

        for k = 0; k < q_cand_ids.length(); k = k + 1 {
          let idx = lookup_idx(q_cand_ids[k])
          if idx >= 0 {
            let dx = q_cx - centers_x[idx]
            let dy = q_cy - centers_y[idx]
            let dz = q_cz - centers_z[idx]
            if dx * dx + dy * dy + dz * dz <= eps_sq {
              q_core_neighbors.push(idx)
            }
          }
        }

        if q_core_neighbors.length() >= min_pts_clamped {
          for k = 0; k < q_core_neighbors.length(); k = k + 1 {
            let n_idx = q_core_neighbors[k]
            if labels[n_idx] == -2 || labels[n_idx] == -1 {
              queue.push(n_idx)
            }
          }
        }
      }

      current_cluster = current_cluster + 1
    }
  }

  let num_clusters = current_cluster
  let mut num_noise = 0
  let cluster_sizes = Array::make(num_clusters, 0)
  let labels_by_id = Array::make(max_id + 1, -1)
  for i = 0; i < n; i = i + 1 {
    let lbl = labels[i]
    let id = leaf_ids[i]
    labels_by_id[id] = lbl
    if lbl < 0 {
      num_noise = num_noise + 1
    } else {
      cluster_sizes[lbl] = cluster_sizes[lbl] + 1
    }
  }

  ClusterResult::{
    labels: labels_by_id,
    num_clusters,
    num_noise,
    cluster_sizes,
  }
}
