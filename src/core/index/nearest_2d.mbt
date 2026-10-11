///|
/// Computes squared distance from a point (x, y) to an axis-aligned box.
fn dist_sq_to_box(
  box_min_x : Double,
  box_min_y : Double,
  box_max_x : Double,
  box_max_y : Double,
  x : Double,
  y : Double,
) -> Double {
  let dx = if x < box_min_x {
    box_min_x - x
  } else if x > box_max_x {
    x - box_max_x
  } else {
    0.0
  }
  let dy = if y < box_min_y {
    box_min_y - y
  } else if y > box_max_y {
    y - box_max_y
  } else {
    0.0
  }
  dx * dx + dy * dy
}

///|
/// Performs branch-and-bound k-Nearest Neighbor (k-NN) search.
/// Returns at most k item IDs sorted by ascending Euclidean distance to (x, y).
pub fn StrTree::query_knn(
  self : StrTree,
  x : Double,
  y : Double,
  k : Int,
) -> Array[Int] {
  let (ids, _) = self.knn_candidates(x, y, k, None)
  ids
}

///|
/// Performs branch-and-bound k-Nearest Neighbor (k-NN) search.
/// Returns at most k pairs (item_id, squared_distance) sorted by ascending Euclidean distance to (x, y).
pub fn StrTree::query_knn_with_distance(
  self : StrTree,
  x : Double,
  y : Double,
  k : Int,
) -> Array[(Int, Double)] {
  let (ids, distances) = self.knn_candidates(x, y, k, None)
  Array::makei(ids.length(), fn(i) { (ids[i], distances[i]) })
}

///|
/// Performs branch-and-bound k-Nearest Neighbor (k-NN) search filtered by user predicate.
/// Returns at most k item IDs satisfying predicate(id), sorted by ascending Euclidean distance to (x, y).
pub fn StrTree::query_knn_with_predicate(
  self : StrTree,
  x : Double,
  y : Double,
  k : Int,
  predicate : (Int) -> Bool,
) -> Array[Int] {
  let (ids, _) = self.knn_candidates(x, y, k, Some(predicate))
  ids
}

///|
/// Performs branch-and-bound k-Nearest Neighbor (k-NN) search filtered by user predicate.
/// Returns at most k pairs (item_id, squared_distance) satisfying predicate(id), sorted by ascending Euclidean distance to (x, y).
pub fn StrTree::query_knn_with_predicate_and_distance(
  self : StrTree,
  x : Double,
  y : Double,
  k : Int,
  predicate : (Int) -> Bool,
) -> Array[(Int, Double)] {
  let (ids, distances) = self.knn_candidates(x, y, k, Some(predicate))
  Array::makei(ids.length(), fn(i) { (ids[i], distances[i]) })
}

///|
/// Performs branch-and-bound k-Nearest Neighbor (k-NN) search.
/// Returns at most k item IDs sorted by ascending Euclidean distance to (x, y).
fn StrTree::knn_candidates(
  self : StrTree,
  x : Double,
  y : Double,
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
  let root_dist = dist_sq_to_box(
    self.boxes_min_x[root],
    self.boxes_min_y[root],
    self.boxes_max_x[root],
    self.boxes_max_y[root],
    x,
    y,
  )
  knn_heap_push(heap_dist, heap_node, root_dist, root)

  while !heap_dist.is_empty() {
    let (node_dist, curr) = knn_heap_pop(heap_dist, heap_node)

    // Branch-and-bound pruning:
    // If we have k candidates and the nearest remaining node in heap is further than
    // our worst candidate, no unvisited item in the tree can be closer.
    if cand_dists.length() >= k && node_dist >= cand_dists[k - 1] {
      break
    }

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
        let child_dist = dist_sq_to_box(
          self.boxes_min_x[child],
          self.boxes_min_y[child],
          self.boxes_max_x[child],
          self.boxes_max_y[child],
          x,
          y,
        )
        if cand_dists.length() < k ||
          child_dist < cand_dists[cand_dists.length() - 1] {
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

  (cand_ids, cand_dists)
}
