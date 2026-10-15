///|
/// Euclidean distance squared between point (x, y, z) and a 3D box.
fn dist_sq_to_box3d(
  min_x : Double,
  min_y : Double,
  min_z : Double,
  max_x : Double,
  max_y : Double,
  max_z : Double,
  x : Double,
  y : Double,
  z : Double,
) -> Double {
  let dx = if x < min_x {
    min_x - x
  } else if x > max_x {
    x - max_x
  } else {
    0.0
  }
  let dy = if y < min_y {
    min_y - y
  } else if y > max_y {
    y - max_y
  } else {
    0.0
  }
  let dz = if z < min_z {
    min_z - z
  } else if z > max_z {
    z - max_z
  } else {
    0.0
  }
  dx * dx + dy * dy + dz * dz
}

///|
/// Performs branch-and-bound k-Nearest Neighbor (k-NN) search in 3D Euclidean space.
/// Returns at most k item IDs sorted by ascending Euclidean distance to (x, y, z).
pub fn StrTree3D::query_knn(
  self : StrTree3D,
  x : Double,
  y : Double,
  z : Double,
  k : Int,
) -> Array[Int] {
  let (ids, _) = self.knn_candidates(x, y, z, k, None)
  ids
}

///|
/// Performs branch-and-bound 3D k-NN search returning pairs of (item_id, squared_distance).
pub fn StrTree3D::query_knn_with_distance(
  self : StrTree3D,
  x : Double,
  y : Double,
  z : Double,
  k : Int,
) -> Array[(Int, Double)] {
  let (ids, distances) = self.knn_candidates(x, y, z, k, None)
  Array::makei(ids.length(), fn(i) { (ids[i], distances[i]) })
}

///|
/// Performs branch-and-bound 3D k-NN search filtered by a user predicate closure.
pub fn StrTree3D::query_knn_with_predicate(
  self : StrTree3D,
  x : Double,
  y : Double,
  z : Double,
  k : Int,
  predicate : (Int) -> Bool,
) -> Array[Int] {
  let (ids, _) = self.knn_candidates(x, y, z, k, Some(predicate))
  ids
}

///|
/// Performs branch-and-bound 3D k-NN search with predicate and distance pairs.
pub fn StrTree3D::query_knn_with_predicate_and_distance(
  self : StrTree3D,
  x : Double,
  y : Double,
  z : Double,
  k : Int,
  predicate : (Int) -> Bool,
) -> Array[(Int, Double)] {
  let (ids, distances) = self.knn_candidates(x, y, z, k, Some(predicate))
  Array::makei(ids.length(), fn(i) { (ids[i], distances[i]) })
}

///|
/// Performs branch-and-bound k-Nearest Neighbor (k-NN) search in 3D Euclidean space.
/// Returns at most k item IDs sorted by ascending Euclidean distance to (x, y, z).
fn StrTree3D::knn_candidates(
  self : StrTree3D,
  x : Double,
  y : Double,
  z : Double,
  k : Int,
  predicate : ((Int) -> Bool)?,
) -> (Array[Int], Array[Double]) {
  if k <= 0 || self.root_index < 0 || self.num_items == 0 {
    return ([], [])
  }

  let cand_dists : Array[Double] = []
  let cand_ids : Array[Int] = []

  let heap_dist : Array[Double] = []
  let heap_node : Array[Int] = []

  let root = self.root_index
  let root_dist = dist_sq_to_box3d(
    self.boxes_min_x[root],
    self.boxes_min_y[root],
    self.boxes_min_z[root],
    self.boxes_max_x[root],
    self.boxes_max_y[root],
    self.boxes_max_z[root],
    x,
    y,
    z,
  )
  knn_heap_push(heap_dist, heap_node, root_dist, root)

  while !heap_dist.is_empty() {
    let node_dist = heap_dist.unsafe_get(0)

    // Branch-and-bound pruning:
    if cand_dists.length() >= k && node_dist >= cand_dists.unsafe_get(0) {
      break
    }
    let curr = knn_heap_pop(heap_dist, heap_node)

    let count = self.child_count[curr]
    if count == 0 {
      let id = self.item_ids[curr]
      if id >= 0 &&
        (match predicate {
          None => true
          Some(filter) => filter(id)
        }) {
        insert_knn_candidate(cand_dists, cand_ids, k, node_dist, id)
      }
    } else {
      let offset = self.child_offset[curr]
      for i = 0; i < count; i = i + 1 {
        let child = self.child_indices[offset + i]
        let child_dist = dist_sq_to_box3d(
          self.boxes_min_x[child],
          self.boxes_min_y[child],
          self.boxes_min_z[child],
          self.boxes_max_x[child],
          self.boxes_max_y[child],
          self.boxes_max_z[child],
          x,
          y,
          z,
        )
        if cand_dists.length() < k || child_dist < cand_dists.unsafe_get(0) {
          if self.child_count[child] == 0 {
            let id = self.item_ids[child]
            if id >= 0 &&
              (match predicate {
                None => true
                Some(filter) => filter(id)
              }) {
              insert_knn_candidate(cand_dists, cand_ids, k, child_dist, id)
            }
          } else {
            knn_heap_push(heap_dist, heap_node, child_dist, child)
          }
        }
      }
    }
  }

  sort_knn_candidates(cand_dists, cand_ids)
  (cand_ids, cand_dists)
}
