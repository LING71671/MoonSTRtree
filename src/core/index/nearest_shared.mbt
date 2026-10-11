///|
/// Inserts a candidate into sorted top-k candidates array.
fn insert_knn_candidate(
  cand_dists : Array[Double],
  cand_ids : Array[Int],
  k : Int,
  dist : Double,
  id : Int,
) -> Unit {
  let len = cand_dists.length()
  let mut lo = 0
  let mut hi = len
  while lo < hi {
    let mid = lo + (hi - lo) / 2
    if dist < cand_dists[mid] {
      hi = mid
    } else {
      lo = mid + 1
    }
  }
  let pos = lo
  if pos < k {
    if len < k {
      cand_dists.push(dist)
      cand_ids.push(id)
      let mut j = len
      while j > pos {
        cand_dists[j] = cand_dists[j - 1]
        cand_ids[j] = cand_ids[j - 1]
        j = j - 1
      }
      cand_dists[pos] = dist
      cand_ids[pos] = id
    } else {
      let mut j = k - 1
      while j > pos {
        cand_dists[j] = cand_dists[j - 1]
        cand_ids[j] = cand_ids[j - 1]
        j = j - 1
      }
      cand_dists[pos] = dist
      cand_ids[pos] = id
    }
  }
}

///|
/// Pushes an entry onto the flat binary min-heap.
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
    let parent = (idx - 1) / 2
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
/// Pops the minimum entry from the flat binary min-heap.
fn knn_heap_pop(
  heap_dist : Array[Double],
  heap_node : Array[Int],
) -> (Double, Int) {
  let min_dist = heap_dist[0]
  let min_node = heap_node[0]
  // Called only for a nonempty heap; unsafe_pop avoids boxed Option values.
  let last_dist = heap_dist.unsafe_pop()
  let last_node = heap_node.unsafe_pop()
  let len = heap_dist.length()
  if len > 0 {
    let mut idx = 0
    while true {
      let left = 2 * idx + 1
      if left >= len {
        break
      }
      let right = left + 1
      let smallest = if right < len &&
        heap_dist.unsafe_get(right) < heap_dist.unsafe_get(left) {
        right
      } else {
        left
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
  (min_dist, min_node)
}
