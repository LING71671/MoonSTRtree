///|
/// Packed 2D spatial index tree with contiguous flat array storage.
pub struct StrTree {
  boxes_min_x : Array[Double]
  boxes_min_y : Array[Double]
  boxes_max_x : Array[Double]
  boxes_max_y : Array[Double]
  child_offset : Array[Int]
  child_count : Array[Int]
  child_indices : Array[Int]
  item_ids : Array[Int]
  root_index : Int
  node_capacity : Int
  num_items : Int
  height : Int
} derive(Eq, Debug, Default)

///|
/// Builds a packed StrTree from an array of (Rect, ID) pairs and node capacity.
pub fn StrTree::build(
  items : Array[(@geometry.Rect, Int)],
  node_capacity? : Int = 16,
) -> StrTree {
  let cap = if node_capacity < 2 { 2 } else { node_capacity }
  let str_items : Array[@str.STRItem] = []
  for i = 0; i < items.length(); i = i + 1 {
    let (rect, id) = items[i]
    str_items.push(@str.STRItem::new(rect, id))
  }

  let res = @str.pack_str(str_items, node_capacity=cap)
  let num_nodes = res.nodes.length()

  let boxes_min_x = Array::make(num_nodes, 0.0)
  let boxes_min_y = Array::make(num_nodes, 0.0)
  let boxes_max_x = Array::make(num_nodes, 0.0)
  let boxes_max_y = Array::make(num_nodes, 0.0)
  let child_offset = Array::make(num_nodes, 0)
  let child_count = Array::make(num_nodes, 0)
  let item_ids = Array::make(num_nodes, -1)
  let child_indices : Array[Int] = []

  for i = 0; i < num_nodes; i = i + 1 {
    let node = res.nodes[i]
    boxes_min_x[i] = node.rect.min_x
    boxes_min_y[i] = node.rect.min_y
    boxes_max_x[i] = node.rect.max_x
    boxes_max_y[i] = node.rect.max_y
    item_ids[i] = node.item_id

    child_offset[i] = child_indices.length()
    child_count[i] = node.children.length()
    for c = 0; c < node.children.length(); c = c + 1 {
      child_indices.push(node.children[c])
    }
  }

  StrTree::{
    boxes_min_x,
    boxes_min_y,
    boxes_max_x,
    boxes_max_y,
    child_offset,
    child_count,
    child_indices,
    item_ids,
    root_index: res.root_index,
    node_capacity: cap,
    num_items: res.num_items,
    height: res.height,
  }
}

///|
/// Returns total number of indexed items.
pub fn StrTree::num_items(self : StrTree) -> Int {
  self.num_items
}

///|
/// Returns total number of nodes in the packed tree.
pub fn StrTree::num_nodes(self : StrTree) -> Int {
  self.boxes_min_x.length()
}

///|
/// Returns the height of the tree.
pub fn StrTree::height(self : StrTree) -> Int {
  self.height
}

///|
/// Returns the node capacity.
pub fn StrTree::node_capacity(self : StrTree) -> Int {
  self.node_capacity
}

///|
/// Returns the root node index.
pub fn StrTree::root_index(self : StrTree) -> Int {
  self.root_index
}

///|
/// Returns the bounding box of the entire tree, or None if empty.
pub fn StrTree::root_bounds(self : StrTree) -> @geometry.Rect? {
  if self.root_index < 0 || self.num_items == 0 {
    None
  } else {
    let r = self.root_index
    Some(
      @geometry.Rect::new(
        self.boxes_min_x[r],
        self.boxes_min_y[r],
        self.boxes_max_x[r],
        self.boxes_max_y[r],
      ),
    )
  }
}

///|
/// Performs axis-aligned bounding box range intersection query using iterative stack DFS.
pub fn StrTree::query(
  self : StrTree,
  search_window : @geometry.Rect,
) -> Array[Int] {
  if self.root_index < 0 || self.num_items == 0 {
    return []
  }

  let win_min_x = if search_window.min_x > search_window.max_x {
    search_window.max_x
  } else {
    search_window.min_x
  }
  let win_max_x = if search_window.min_x > search_window.max_x {
    search_window.min_x
  } else {
    search_window.max_x
  }
  let win_min_y = if search_window.min_y > search_window.max_y {
    search_window.max_y
  } else {
    search_window.min_y
  }
  let win_max_y = if search_window.min_y > search_window.max_y {
    search_window.min_y
  } else {
    search_window.max_y
  }

  let root = self.root_index
  if !(win_max_x >= self.boxes_min_x[root] &&
    win_min_x <= self.boxes_max_x[root] &&
    win_max_y >= self.boxes_min_y[root] &&
    win_min_y <= self.boxes_max_y[root]) {
    return []
  }

  let results : Array[Int] = []
  let stack : Array[Int] = [root]

  while !stack.is_empty() {
    let curr = match stack.pop() {
      Some(v) => v
      None => break
    }

    let count = self.child_count[curr]
    if count == 0 {
      let id = self.item_ids[curr]
      if id >= 0 {
        results.push(id)
      }
    } else {
      let offset = self.child_offset[curr]
      for i = 0; i < count; i = i + 1 {
        let child = self.child_indices[offset + i]
        if win_max_x >= self.boxes_min_x[child] &&
          win_min_x <= self.boxes_max_x[child] &&
          win_max_y >= self.boxes_min_y[child] &&
          win_min_y <= self.boxes_max_y[child] {
          stack.push(child)
        }
      }
    }
  }

  results
}

///|
/// Performs point inclusion query using iterative stack DFS.
pub fn StrTree::query_point(
  self : StrTree,
  x : Double,
  y : Double,
) -> Array[Int] {
  if self.root_index < 0 || self.num_items == 0 {
    return []
  }

  let root = self.root_index
  if !(self.boxes_min_x[root] <= x &&
    x <= self.boxes_max_x[root] &&
    self.boxes_min_y[root] <= y &&
    y <= self.boxes_max_y[root]) {
    return []
  }

  let results : Array[Int] = []
  let stack : Array[Int] = [root]

  while !stack.is_empty() {
    let curr = match stack.pop() {
      Some(v) => v
      None => break
    }

    let count = self.child_count[curr]
    if count == 0 {
      let id = self.item_ids[curr]
      if id >= 0 {
        results.push(id)
      }
    } else {
      let offset = self.child_offset[curr]
      for i = 0; i < count; i = i + 1 {
        let child = self.child_indices[offset + i]
        if self.boxes_min_x[child] <= x &&
          x <= self.boxes_max_x[child] &&
          self.boxes_min_y[child] <= y &&
          y <= self.boxes_max_y[child] {
          stack.push(child)
        }
      }
    }
  }

  results
}

///|
/// Returns true if node at index is a leaf item.
pub fn StrTree::is_leaf_at(self : StrTree, index : Int) -> Bool {
  if index < 0 || index >= self.boxes_min_x.length() {
    false
  } else {
    self.child_count[index] == 0
  }
}

///|
/// Returns the number of children for node at index.
pub fn StrTree::child_count_at(self : StrTree, index : Int) -> Int {
  if index < 0 || index >= self.boxes_min_x.length() {
    0
  } else {
    self.child_count[index]
  }
}

///|
/// Returns the child index at given child position for parent at index.
pub fn StrTree::child_index_at(
  self : StrTree,
  parent_index : Int,
  child_pos : Int,
) -> Int {
  if parent_index < 0 || parent_index >= self.boxes_min_x.length() {
    -1
  } else {
    let count = self.child_count[parent_index]
    if child_pos < 0 || child_pos >= count {
      -1
    } else {
      let offset = self.child_offset[parent_index]
      self.child_indices[offset + child_pos]
    }
  }
}

///|
/// Returns the bounding box of the node at index.
pub fn StrTree::node_bounds_at(self : StrTree, index : Int) -> @geometry.Rect {
  if index < 0 || index >= self.boxes_min_x.length() {
    @geometry.Rect::default()
  } else {
    @geometry.Rect::new(
      self.boxes_min_x[index],
      self.boxes_min_y[index],
      self.boxes_max_x[index],
      self.boxes_max_y[index],
    )
  }
}

///|
/// Returns the item ID for leaf node at index.
pub fn StrTree::item_id_at(self : StrTree, index : Int) -> Int {
  if index < 0 || index >= self.item_ids.length() {
    -1
  } else {
    self.item_ids[index]
  }
}

///|
/// Returns total number of topological child edges across the tree.
pub fn StrTree::total_edges(self : StrTree) -> Int {
  self.child_indices.length()
}

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
/// Inserts a candidate into sorted top-k candidates array.
fn insert_knn_candidate(
  cand_dists : Array[Double],
  cand_ids : Array[Int],
  k : Int,
  dist : Double,
  id : Int,
) -> Unit {
  let len = cand_dists.length()
  let mut pos = len
  for i = 0; i < len; i = i + 1 {
    if dist < cand_dists[i] {
      pos = i
      break
    }
  }
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
  while idx > 0 {
    let parent = (idx - 1) / 2
    if heap_dist[idx] < heap_dist[parent] {
      let d_tmp = heap_dist[idx]
      heap_dist[idx] = heap_dist[parent]
      heap_dist[parent] = d_tmp

      let n_tmp = heap_node[idx]
      heap_node[idx] = heap_node[parent]
      heap_node[parent] = n_tmp

      idx = parent
    } else {
      break
    }
  }
}

///|
/// Pops the minimum entry from the flat binary min-heap.
fn knn_heap_pop(
  heap_dist : Array[Double],
  heap_node : Array[Int],
) -> (Double, Int) {
  let min_dist = heap_dist[0]
  let min_node = heap_node[0]

  let last_idx = heap_dist.length() - 1
  heap_dist[0] = heap_dist[last_idx]
  heap_node[0] = heap_node[last_idx]
  let _ = heap_dist.pop()
  let _ = heap_node.pop()

  let len = heap_dist.length()
  let mut idx = 0
  while true {
    let left = 2 * idx + 1
    let right = 2 * idx + 2
    if left >= len {
      break
    }
    let smallest = if right < len && heap_dist[right] < heap_dist[left] {
      right
    } else {
      left
    }
    if heap_dist[smallest] < heap_dist[idx] {
      let d_tmp = heap_dist[idx]
      heap_dist[idx] = heap_dist[smallest]
      heap_dist[smallest] = d_tmp

      let n_tmp = heap_node[idx]
      heap_node[idx] = heap_node[smallest]
      heap_node[smallest] = n_tmp

      idx = smallest
    } else {
      break
    }
  }

  (min_dist, min_node)
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
  if k <= 0 || self.root_index < 0 || self.num_items == 0 {
    return []
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
      if id >= 0 {
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
          knn_heap_push(heap_dist, heap_node, child_dist, child)
        }
      }
    }
  }

  cand_ids
}
