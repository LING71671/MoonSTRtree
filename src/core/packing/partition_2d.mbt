///|
/// Partition only at page boundaries; items within a page need no total ordering.
fn select_boundary(
  order : Array[Int32],
  centers : Array[Double],
  start : Int32,
  end : Int32,
  boundary : Int32,
) -> Unit {
  let mut left = start
  let mut right = end - 1
  while left < right {
    let a = centers.unsafe_get(order.unsafe_get(left))
    let b = centers.unsafe_get(order.unsafe_get(left + (right - left) / 2))
    let c = centers.unsafe_get(order.unsafe_get(right))
    let pivot = if a < b {
      if b < c {
        b
      } else if a < c {
        c
      } else {
        a
      }
    } else if a < c {
      a
    } else if b < c {
      c
    } else {
      b
    }
    let mut i = left
    let mut j = right
    while i <= j {
      while i <= right && centers.unsafe_get(order.unsafe_get(i)) < pivot {
        i = i + 1
      }
      while j >= left && centers.unsafe_get(order.unsafe_get(j)) > pivot {
        j = j - 1
      }
      if i <= j {
        let value = order.unsafe_get(i)
        order.unsafe_set(i, order.unsafe_get(j))
        order.unsafe_set(j, value)
        i = i + 1
        j = j - 1
      }
    }
    if boundary <= j {
      right = j
    } else if boundary >= i {
      left = i
    } else {
      break
    }
  }
}

///|
fn partition_groups(
  order : Array[Int32],
  centers : Array[Double],
  start : Int32,
  end : Int32,
  group_size : Int32,
) -> Unit {
  let stack : Array[(Int32, Int32)] = [(start, end)]
  while stack.pop() is Some((left, right)) {
    if right - left <= group_size {
      continue
    }
    let groups = ceil_div(right - left, group_size)
    let middle = left + groups / 2 * group_size
    select_boundary(order, centers, left, right, middle)
    stack.push((left, middle))
    stack.push((middle, right))
  }
}

///|
/// STR page membership without sorting individual entries inside each page.
/// Input bounds must have finite centers; order is permuted in place.
pub fn partition_str_2d(
  order : Array[Int32],
  centers_x : Array[Double],
  centers_y : Array[Double],
  capacity : Int32,
) -> Unit {
  guard capacity >= 2 else { abort("STR capacity must be at least two") }
  for index in order {
    guard index >= 0 && index < centers_x.length() && index < centers_y.length() else {
      abort("Invalid STR center index")
    }
  }
  let count = order.length()
  if count <= capacity {
    return
  }
  let pages = ceil_div(count, capacity)
  let slices = ceil_sqrt(pages)
  let slice_size = ceil_div(pages, slices) * capacity
  partition_groups(order, centers_x, 0, count, slice_size)
  let mut start = 0
  while start < count {
    let end = (start + slice_size).min(count)
    partition_groups(order, centers_y, start, end, capacity)
    start = end
  }
}
