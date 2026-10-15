///|
/// Retains the nearest k candidates in a maximum heap. The worst retained
/// distance is at slot zero; paired arrays always have the same length.
fn insert_knn_candidate(
  cand_dists : Array[Double],
  cand_ids : Array[Int],
  k : Int,
  dist : Double,
  id : Int,
) -> Unit {
  if k <= 0 {
    return
  }
  let len = cand_dists.length()
  if len < k {
    cand_dists.push(dist)
    cand_ids.push(id)
    let mut index = len
    while index > 0 {
      let parent = (index - 1) / 2
      let parent_dist = cand_dists.unsafe_get(parent)
      if dist <= parent_dist {
        break
      }
      cand_dists.unsafe_set(index, parent_dist)
      cand_ids.unsafe_set(index, cand_ids.unsafe_get(parent))
      index = parent
    }
    cand_dists.unsafe_set(index, dist)
    cand_ids.unsafe_set(index, id)
  } else if dist < cand_dists.unsafe_get(0) {
    sift_candidate_down(cand_dists, cand_ids, len, dist, id)
  }
}

///|
/// Restores a maximum heap after replacing its root. The caller proves a
/// nonempty prefix and equally sized distance/ID columns.
fn sift_candidate_down(
  distances : Array[Double],
  ids : Array[Int],
  length : Int,
  distance : Double,
  id : Int,
) -> Unit {
  let mut index = 0
  while true {
    let left = index * 2 + 1
    if left >= length {
      break
    }
    let right = left + 1
    let largest = if right < length &&
      distances.unsafe_get(right) > distances.unsafe_get(left) {
      right
    } else {
      left
    }
    let child_distance = distances.unsafe_get(largest)
    if child_distance <= distance {
      break
    }
    distances.unsafe_set(index, child_distance)
    ids.unsafe_set(index, ids.unsafe_get(largest))
    index = largest
  }
  distances.unsafe_set(index, distance)
  ids.unsafe_set(index, id)
}

///|
/// Sorts the retained maximum heap in place, preserving ID-distance pairing.
/// No per-result tuple array is needed. Equal-distance ordering is unspecified.
fn sort_knn_candidates(distances : Array[Double], ids : Array[Int]) -> Unit {
  let mut end = distances.length() - 1
  while end > 0 {
    let maximum_distance = distances.unsafe_get(0)
    let maximum_id = ids.unsafe_get(0)
    let replacement_distance = distances.unsafe_get(end)
    let replacement_id = ids.unsafe_get(end)
    distances.unsafe_set(end, maximum_distance)
    ids.unsafe_set(end, maximum_id)
    sift_candidate_down(
      distances, ids, end, replacement_distance, replacement_id,
    )
    end = end - 1
  }
}

///|
/// Pushes an entry onto the flat four-way frontier min-heap. A wider frontier
/// reduces levels moved per insertion; the bounded candidate heap stays binary.
fn knn_heap_push(
  heap_dist : Array[Double],
  heap_node : Array[Int],
  dist : Double,
  node : Int,
) -> Unit {
  heap_dist.push(dist)
  heap_node.push(node)
  let mut idx = heap_dist.length() - 1
  // Both arrays grow together. Parent/child positions are proven inside the heap.
  while idx > 0 {
    let parent = (idx - 1) / 4
    let parent_dist = heap_dist.unsafe_get(parent)
    if dist >= parent_dist {
      break
    }
    heap_dist.unsafe_set(idx, parent_dist)
    heap_node.unsafe_set(idx, heap_node.unsafe_get(parent))
    idx = parent
  }
  heap_dist.unsafe_set(idx, dist)
  heap_node.unsafe_set(idx, node)
}

///|
/// Removes the minimum node from a nonempty frontier. The caller reads its
/// distance before removal, so traversal does not allocate a pair per node.
fn knn_heap_pop(heap_dist : Array[Double], heap_node : Array[Int]) -> Int {
  let min_node = heap_node.unsafe_get(0)
  // Called only for a nonempty heap; unsafe_pop avoids boxed Option values.
  let last_dist = heap_dist.unsafe_pop()
  let last_node = heap_node.unsafe_pop()
  let len = heap_dist.length()
  if len > 0 {
    let mut idx = 0
    while true {
      let first = 4 * idx + 1
      if first >= len {
        break
      }
      let mut smallest = first
      let limit = Int::min(first + 4, len)
      for child = first + 1; child < limit; child = child + 1 {
        if heap_dist.unsafe_get(child) < heap_dist.unsafe_get(smallest) {
          smallest = child
        }
      }
      let child_dist = heap_dist.unsafe_get(smallest)
      if child_dist >= last_dist {
        break
      }
      heap_dist.unsafe_set(idx, child_dist)
      heap_node.unsafe_set(idx, heap_node.unsafe_get(smallest))
      idx = smallest
    }
    heap_dist.unsafe_set(idx, last_dist)
    heap_node.unsafe_set(idx, last_node)
  }
  min_node
}
