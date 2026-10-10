///|
/// Diagnostic statistics for a packed 3D StrTree.
pub struct TreeStats3D {
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
/// Packed 3D spatial index tree with contiguous flat array storage.
pub struct StrTree3D {
  boxes_min_x : Array[Double]
  boxes_min_y : Array[Double]
  boxes_min_z : Array[Double]
  boxes_max_x : Array[Double]
  boxes_max_y : Array[Double]
  boxes_max_z : Array[Double]
  child_offset : Array[Int]
  child_count : Array[Int]
  child_indices : Array[Int]
  item_ids : Array[Int]
  node_levels : Array[Int]
  num_items : Int
  num_nodes : Int
  height : Int
  node_capacity : Int
  root_index : Int
} derive(Eq, Debug, Default)

///|
/// Builds a packed 3D StrTree from an array of (Box3D, ID) pairs and optional node capacity.
pub fn StrTree3D::build(
  items : Array[(@geometry.Box3D, Int)],
  node_capacity? : Int = 16,
) -> StrTree3D {
  let cap = if node_capacity < 2 { 2 } else { node_capacity }
  let num_items = items.length()

  if num_items == 0 {
    return StrTree3D::{
      boxes_min_x: [],
      boxes_min_y: [],
      boxes_min_z: [],
      boxes_max_x: [],
      boxes_max_y: [],
      boxes_max_z: [],
      child_offset: [],
      child_count: [],
      child_indices: [],
      item_ids: [],
      node_levels: [],
      num_items: 0,
      num_nodes: 0,
      height: 0,
      node_capacity: cap,
      root_index: -1,
    }
  }

  let str_items : Array[@str.STRItem3D] = []
  for i = 0; i < num_items; i = i + 1 {
    let (box, id) = items[i]
    str_items.push(@str.STRItem3D::new(box, id))
  }

  let build_result = @str.pack_str3d(str_items, node_capacity=cap)
  let raw_nodes = build_result.nodes
  let total_nodes = raw_nodes.length()

  let boxes_min_x = Array::make(total_nodes, 0.0)
  let boxes_min_y = Array::make(total_nodes, 0.0)
  let boxes_min_z = Array::make(total_nodes, 0.0)
  let boxes_max_x = Array::make(total_nodes, 0.0)
  let boxes_max_y = Array::make(total_nodes, 0.0)
  let boxes_max_z = Array::make(total_nodes, 0.0)
  let child_offset = Array::make(total_nodes, 0)
  let child_count = Array::make(total_nodes, 0)
  let item_ids = Array::make(total_nodes, -1)
  let node_levels = Array::make(total_nodes, 0)

  let child_indices_list : Array[Int] = []

  // Assign levels using BFS queue
  let node_level_arr = Array::make(total_nodes, 0)
  let queue : Array[Int] = []
  if build_result.root_index >= 0 {
    queue.push(build_result.root_index)
    node_level_arr[build_result.root_index] = build_result.height
  }

  let mut head = 0
  while head < queue.length() {
    let curr = queue[head]
    head = head + 1
    let parent_level = node_level_arr[curr]
    let c_list = raw_nodes[curr].children
    for i = 0; i < c_list.length(); i = i + 1 {
      let child = c_list[i]
      node_level_arr[child] = parent_level - 1
      queue.push(child)
    }
  }

  for i = 0; i < total_nodes; i = i + 1 {
    let node = raw_nodes[i]
    boxes_min_x[i] = node.box.min_x
    boxes_min_y[i] = node.box.min_y
    boxes_min_z[i] = node.box.min_z
    boxes_max_x[i] = node.box.max_x
    boxes_max_y[i] = node.box.max_y
    boxes_max_z[i] = node.box.max_z
    item_ids[i] = node.item_id
    node_levels[i] = node_level_arr[i]

    let num_c = node.children.length()
    child_count[i] = num_c
    if num_c > 0 {
      child_offset[i] = child_indices_list.length()
      for c = 0; c < num_c; c = c + 1 {
        child_indices_list.push(node.children[c])
      }
    } else {
      child_offset[i] = 0
    }
  }

  let child_indices = Array::make(child_indices_list.length(), 0)
  for i = 0; i < child_indices_list.length(); i = i + 1 {
    child_indices[i] = child_indices_list[i]
  }

  StrTree3D::{
    boxes_min_x,
    boxes_min_y,
    boxes_min_z,
    boxes_max_x,
    boxes_max_y,
    boxes_max_z,
    child_offset,
    child_count,
    child_indices,
    item_ids,
    node_levels,
    num_items,
    num_nodes: total_nodes,
    height: build_result.height,
    node_capacity: cap,
    root_index: build_result.root_index,
  }
}

///|
/// Performs 3D range query using iterative stack DFS traversal.
pub fn StrTree3D::query(
  self : StrTree3D,
  search_box : @geometry.Box3D,
) -> Array[Int] {
  if self.root_index < 0 || self.num_items == 0 {
    return []
  }

  let root = self.root_index
  if search_box.max_x < self.boxes_min_x[root] ||
    search_box.min_x > self.boxes_max_x[root] ||
    search_box.max_y < self.boxes_min_y[root] ||
    search_box.min_y > self.boxes_max_y[root] ||
    search_box.max_z < self.boxes_min_z[root] ||
    search_box.min_z > self.boxes_max_z[root] {
    return []
  }

  let results : Array[Int] = []
  let stack : Array[Int] = [root]

  while !stack.is_empty() {
    let curr = stack.pop().unwrap()
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
        if !(search_box.max_x < self.boxes_min_x[child] ||
          search_box.min_x > self.boxes_max_x[child] ||
          search_box.max_y < self.boxes_min_y[child] ||
          search_box.min_y > self.boxes_max_y[child] ||
          search_box.max_z < self.boxes_min_z[child] ||
          search_box.min_z > self.boxes_max_z[child]) {
          stack.push(child)
        }
      }
    }
  }

  results
}

///|
/// Performs zero-allocation count of items intersecting a 3D search box.
pub fn StrTree3D::query_count(
  self : StrTree3D,
  search_box : @geometry.Box3D,
) -> Int {
  if self.root_index < 0 || self.num_items == 0 {
    return 0
  }

  let root = self.root_index
  if search_box.max_x < self.boxes_min_x[root] ||
    search_box.min_x > self.boxes_max_x[root] ||
    search_box.max_y < self.boxes_min_y[root] ||
    search_box.min_y > self.boxes_max_y[root] ||
    search_box.max_z < self.boxes_min_z[root] ||
    search_box.min_z > self.boxes_max_z[root] {
    return 0
  }

  let mut count = 0
  let stack : Array[Int] = [root]

  while !stack.is_empty() {
    let curr = stack.pop().unwrap()
    let c_count = self.child_count[curr]
    if c_count == 0 {
      let id = self.item_ids[curr]
      if id >= 0 {
        count = count + 1
      }
    } else {
      let offset = self.child_offset[curr]
      for i = 0; i < c_count; i = i + 1 {
        let child = self.child_indices[offset + i]
        if !(search_box.max_x < self.boxes_min_x[child] ||
          search_box.min_x > self.boxes_max_x[child] ||
          search_box.max_y < self.boxes_min_y[child] ||
          search_box.min_y > self.boxes_max_y[child] ||
          search_box.max_z < self.boxes_min_z[child] ||
          search_box.min_z > self.boxes_max_z[child]) {
          stack.push(child)
        }
      }
    }
  }

  count
}

///|
/// Performs 3D point containment query.
pub fn StrTree3D::query_point(
  self : StrTree3D,
  x : Double,
  y : Double,
  z : Double,
) -> Array[Int] {
  if self.root_index < 0 || self.num_items == 0 {
    return []
  }

  let root = self.root_index
  if x < self.boxes_min_x[root] ||
    x > self.boxes_max_x[root] ||
    y < self.boxes_min_y[root] ||
    y > self.boxes_max_y[root] ||
    z < self.boxes_min_z[root] ||
    z > self.boxes_max_z[root] {
    return []
  }

  let results : Array[Int] = []
  let stack : Array[Int] = [root]

  while !stack.is_empty() {
    let curr = stack.pop().unwrap()
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
        if x >= self.boxes_min_x[child] &&
          x <= self.boxes_max_x[child] &&
          y >= self.boxes_min_y[child] &&
          y <= self.boxes_max_y[child] &&
          z >= self.boxes_min_z[child] &&
          z <= self.boxes_max_z[child] {
          stack.push(child)
        }
      }
    }
  }

  results
}

///|
/// Performs 3D sphere range intersection query.
pub fn StrTree3D::query_sphere(
  self : StrTree3D,
  cx : Double,
  cy : Double,
  cz : Double,
  radius : Double,
) -> Array[Int] {
  if self.root_index < 0 || self.num_items == 0 || radius < 0.0 {
    return []
  }

  let r_sq = radius * radius
  let root = self.root_index
  let r_dx = if cx < self.boxes_min_x[root] {
    self.boxes_min_x[root] - cx
  } else if cx > self.boxes_max_x[root] {
    cx - self.boxes_max_x[root]
  } else {
    0.0
  }
  let r_dy = if cy < self.boxes_min_y[root] {
    self.boxes_min_y[root] - cy
  } else if cy > self.boxes_max_y[root] {
    cy - self.boxes_max_y[root]
  } else {
    0.0
  }
  let r_dz = if cz < self.boxes_min_z[root] {
    self.boxes_min_z[root] - cz
  } else if cz > self.boxes_max_z[root] {
    cz - self.boxes_max_z[root]
  } else {
    0.0
  }
  if r_dx * r_dx + r_dy * r_dy + r_dz * r_dz > r_sq {
    return []
  }

  let results : Array[Int] = []
  let stack : Array[Int] = [root]

  while !stack.is_empty() {
    let curr = stack.pop().unwrap()
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
        let dx = if cx < self.boxes_min_x[child] {
          self.boxes_min_x[child] - cx
        } else if cx > self.boxes_max_x[child] {
          cx - self.boxes_max_x[child]
        } else {
          0.0
        }
        let dy = if cy < self.boxes_min_y[child] {
          self.boxes_min_y[child] - cy
        } else if cy > self.boxes_max_y[child] {
          cy - self.boxes_max_y[child]
        } else {
          0.0
        }
        let dz = if cz < self.boxes_min_z[child] {
          self.boxes_min_z[child] - cz
        } else if cz > self.boxes_max_z[child] {
          cz - self.boxes_max_z[child]
        } else {
          0.0
        }
        if dx * dx + dy * dy + dz * dz <= r_sq {
          stack.push(child)
        }
      }
    }
  }

  results
}

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
  if k <= 0 || self.root_index < 0 || self.num_items == 0 {
    return []
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
    let (node_dist, curr) = knn_heap_pop(heap_dist, heap_node)

    // Branch-and-bound pruning:
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
        if cand_dists.length() < k ||
          child_dist < cand_dists[cand_dists.length() - 1] {
          knn_heap_push(heap_dist, heap_node, child_dist, child)
        }
      }
    }
  }

  cand_ids
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
  if k <= 0 || self.root_index < 0 || self.num_items == 0 {
    return []
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
    let (node_dist, curr) = knn_heap_pop(heap_dist, heap_node)

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
        if cand_dists.length() < k ||
          child_dist < cand_dists[cand_dists.length() - 1] {
          knn_heap_push(heap_dist, heap_node, child_dist, child)
        }
      }
    }
  }

  let res : Array[(Int, Double)] = []
  for i = 0; i < cand_ids.length(); i = i + 1 {
    res.push((cand_ids[i], cand_dists[i]))
  }
  res
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
  if k <= 0 || self.root_index < 0 || self.num_items == 0 {
    return []
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
    let (node_dist, curr) = knn_heap_pop(heap_dist, heap_node)

    if cand_dists.length() >= k && node_dist >= cand_dists[k - 1] {
      break
    }

    let count = self.child_count[curr]
    if count == 0 {
      let id = self.item_ids[curr]
      if id >= 0 && predicate(id) {
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
        if cand_dists.length() < k ||
          child_dist < cand_dists[cand_dists.length() - 1] {
          knn_heap_push(heap_dist, heap_node, child_dist, child)
        }
      }
    }
  }

  cand_ids
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
  if k <= 0 || self.root_index < 0 || self.num_items == 0 {
    return []
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
    let (node_dist, curr) = knn_heap_pop(heap_dist, heap_node)

    if cand_dists.length() >= k && node_dist >= cand_dists[k - 1] {
      break
    }

    let count = self.child_count[curr]
    if count == 0 {
      let id = self.item_ids[curr]
      if id >= 0 && predicate(id) {
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
        if cand_dists.length() < k ||
          child_dist < cand_dists[cand_dists.length() - 1] {
          knn_heap_push(heap_dist, heap_node, child_dist, child)
        }
      }
    }
  }

  let res : Array[(Int, Double)] = []
  for i = 0; i < cand_ids.length(); i = i + 1 {
    res.push((cand_ids[i], cand_dists[i]))
  }
  res
}

///|
/// Performs 3D line segment / ray intersection query using iterative stack DFS.
/// Returns item IDs of all indexed elements whose bounding boxes intersect the segment (x1, y1, z1) -> (x2, y2, z2).
pub fn StrTree3D::query_segment(
  self : StrTree3D,
  x1 : Double,
  y1 : Double,
  z1 : Double,
  x2 : Double,
  y2 : Double,
  z2 : Double,
) -> Array[Int] {
  if self.root_index < 0 || self.num_items == 0 {
    return []
  }

  let root = self.root_index
  let root_box = @geometry.Box3D::new(
    self.boxes_min_x[root],
    self.boxes_min_y[root],
    self.boxes_min_z[root],
    self.boxes_max_x[root],
    self.boxes_max_y[root],
    self.boxes_max_z[root],
  )
  if !root_box.intersects_segment(x1, y1, z1, x2, y2, z2) {
    return []
  }

  let results : Array[Int] = []
  let stack : Array[Int] = [root]

  while !stack.is_empty() {
    let curr = match stack.pop() {
      Some(idx) => idx
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
        let child_box = @geometry.Box3D::new(
          self.boxes_min_x[child],
          self.boxes_min_y[child],
          self.boxes_min_z[child],
          self.boxes_max_x[child],
          self.boxes_max_y[child],
          self.boxes_max_z[child],
        )
        if child_box.intersects_segment(x1, y1, z1, x2, y2, z2) {
          stack.push(child)
        }
      }
    }
  }

  results
}

///|
/// Performs zero-allocation count of items containing point (x, y, z).
pub fn StrTree3D::query_point_count(
  self : StrTree3D,
  x : Double,
  y : Double,
  z : Double,
) -> Int {
  if self.root_index < 0 || self.num_items == 0 {
    return 0
  }

  let root = self.root_index
  if x < self.boxes_min_x[root] ||
    x > self.boxes_max_x[root] ||
    y < self.boxes_min_y[root] ||
    y > self.boxes_max_y[root] ||
    z < self.boxes_min_z[root] ||
    z > self.boxes_max_z[root] {
    return 0
  }

  let mut count = 0
  let stack : Array[Int] = [root]

  while !stack.is_empty() {
    let curr = stack.pop().unwrap()
    let c_count = self.child_count[curr]
    if c_count == 0 {
      if self.item_ids[curr] >= 0 {
        count = count + 1
      }
    } else {
      let offset = self.child_offset[curr]
      for i = 0; i < c_count; i = i + 1 {
        let child = self.child_indices[offset + i]
        if !(x < self.boxes_min_x[child] ||
          x > self.boxes_max_x[child] ||
          y < self.boxes_min_y[child] ||
          y > self.boxes_max_y[child] ||
          z < self.boxes_min_z[child] ||
          z > self.boxes_max_z[child]) {
          stack.push(child)
        }
      }
    }
  }

  count
}

///|
/// Performs zero-allocation count of items intersecting a sphere.
pub fn StrTree3D::query_sphere_count(
  self : StrTree3D,
  cx : Double,
  cy : Double,
  cz : Double,
  radius : Double,
) -> Int {
  if radius < 0.0 || self.root_index < 0 || self.num_items == 0 {
    return 0
  }

  let r_sq = radius * radius
  let root = self.root_index

  let root_dist = dist_sq_to_box3d(
    self.boxes_min_x[root],
    self.boxes_min_y[root],
    self.boxes_min_z[root],
    self.boxes_max_x[root],
    self.boxes_max_y[root],
    self.boxes_max_z[root],
    cx,
    cy,
    cz,
  )
  if root_dist > r_sq {
    return 0
  }

  let mut count = 0
  let stack : Array[Int] = [root]

  while !stack.is_empty() {
    let curr = stack.pop().unwrap()
    let c_count = self.child_count[curr]
    if c_count == 0 {
      if self.item_ids[curr] >= 0 {
        count = count + 1
      }
    } else {
      let offset = self.child_offset[curr]
      for i = 0; i < c_count; i = i + 1 {
        let child = self.child_indices[offset + i]
        let d_sq = dist_sq_to_box3d(
          self.boxes_min_x[child],
          self.boxes_min_y[child],
          self.boxes_min_z[child],
          self.boxes_max_x[child],
          self.boxes_max_y[child],
          self.boxes_max_z[child],
          cx,
          cy,
          cz,
        )
        if d_sq <= r_sq {
          stack.push(child)
        }
      }
    }
  }

  count
}

///|
/// Checks if node u in tree t1 intersects node v in tree t2 in 3D Euclidean space.
fn nodes_intersect3d(t1 : StrTree3D, u : Int, t2 : StrTree3D, v : Int) -> Bool {
  !(t1.boxes_max_x[u] < t2.boxes_min_x[v] ||
  t1.boxes_min_x[u] > t2.boxes_max_x[v] ||
  t1.boxes_max_y[u] < t2.boxes_min_y[v] ||
  t1.boxes_min_y[u] > t2.boxes_max_y[v] ||
  t1.boxes_max_z[u] < t2.boxes_min_z[v] ||
  t1.boxes_min_z[u] > t2.boxes_max_z[v])
}

///|
/// Performs dual-tree hierarchical spatial join between two StrTree3D indexes.
/// Returns all pairs of item IDs (id_a, id_b) whose leaf bounding boxes intersect.
pub fn StrTree3D::spatial_join(
  self : StrTree3D,
  other : StrTree3D,
) -> Array[(Int, Int)] {
  if self.root_index < 0 ||
    other.root_index < 0 ||
    self.num_items == 0 ||
    other.num_items == 0 {
    return []
  }

  let root_a = self.root_index
  let root_b = other.root_index

  if !nodes_intersect3d(self, root_a, other, root_b) {
    return []
  }

  let results : Array[(Int, Int)] = []
  let stack_a : Array[Int] = [root_a]
  let stack_b : Array[Int] = [root_b]

  while !stack_a.is_empty() {
    let curr_a = match stack_a.pop() {
      Some(idx) => idx
      None => break
    }
    let curr_b = match stack_b.pop() {
      Some(idx) => idx
      None => break
    }

    let count_a = self.child_count[curr_a]
    let count_b = other.child_count[curr_b]

    if count_a == 0 && count_b == 0 {
      let id_a = self.item_ids[curr_a]
      let id_b = other.item_ids[curr_b]
      if id_a >= 0 && id_b >= 0 {
        results.push((id_a, id_b))
      }
    } else if count_a == 0 {
      let offset_b = other.child_offset[curr_b]
      for j = 0; j < count_b; j = j + 1 {
        let child_b = other.child_indices[offset_b + j]
        if nodes_intersect3d(self, curr_a, other, child_b) {
          stack_a.push(curr_a)
          stack_b.push(child_b)
        }
      }
    } else if count_b == 0 {
      let offset_a = self.child_offset[curr_a]
      for i = 0; i < count_a; i = i + 1 {
        let child_a = self.child_indices[offset_a + i]
        if nodes_intersect3d(self, child_a, other, curr_b) {
          stack_a.push(child_a)
          stack_b.push(curr_b)
        }
      }
    } else {
      let offset_a = self.child_offset[curr_a]
      let offset_b = other.child_offset[curr_b]
      for i = 0; i < count_a; i = i + 1 {
        let child_a = self.child_indices[offset_a + i]
        for j = 0; j < count_b; j = j + 1 {
          let child_b = other.child_indices[offset_b + j]
          if nodes_intersect3d(self, child_a, other, child_b) {
            stack_a.push(child_a)
            stack_b.push(child_b)
          }
        }
      }
    }
  }

  results
}

///|
/// Computes structural diagnostic metrics for 3D StrTree.
pub fn StrTree3D::stats(self : StrTree3D) -> TreeStats3D {
  let mut leaf_nodes = 0
  let mut branch_nodes = 0
  for i = 0; i < self.num_nodes; i = i + 1 {
    if self.child_count[i] == 0 {
      leaf_nodes = leaf_nodes + 1
    } else {
      branch_nodes = branch_nodes + 1
    }
  }

  let fill_factor = if leaf_nodes == 0 {
    0.0
  } else {
    self.num_items.to_double() / (leaf_nodes * self.node_capacity).to_double()
  }

  let estimated_memory_bytes = self.num_nodes * (8 * 6 + 4 * 4) +
    self.child_indices.length() * 4

  TreeStats3D::{
    num_items: self.num_items,
    num_nodes: self.num_nodes,
    height: self.height,
    node_capacity: self.node_capacity,
    fill_factor,
    leaf_nodes,
    branch_nodes,
    total_edges: self.child_indices.length(),
    estimated_memory_bytes,
  }
}
