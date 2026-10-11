///|
test "4D coincident branch bounds preserve every child identity" {
  let bounds = @geometry.Box4D::new(0.0, 0.0, 0.0, 0.0, 10.0, 10.0, 10.0, 10.0)
  let items = Array::makei(64, fn(i) { (bounds, i) })
  for capacity in [2, 4, 8, 16] {
    let tree = StrTree4D::build(items, node_capacity=capacity)
    let hits = tree.query(bounds)
    hits.sort()
    assert_eq(hits, Array::makei(64, fn(i) { i }))
    assert_eq(tree.node_levels[tree.root_index], tree.height - 1)
    for parent = 0; parent < tree.num_nodes; parent = parent + 1 {
      for offset = 0; offset < tree.child_count[parent]; offset = offset + 1 {
        let child = tree.child_indices[tree.child_offset[parent] + offset]
        assert_eq(tree.node_levels[child] + 1, tree.node_levels[parent])
      }
    }
  }
}

///|
test "4D repeated IDs and lower bounds retain distinct upper extents" {
  let items = Array::makei(80, fn(i) {
    let upper = (i + 1).to_double()
    (
      @geometry.Box4D::new(0.0, 0.0, 0.0, 0.0, upper, upper, upper, upper),
      i % 7,
    )
  })
  for capacity in [4, 16] {
    let tree = StrTree4D::build(items, node_capacity=capacity)
    for position in [0.0, 1.0, 25.0, 79.0, 81.0] {
      let expected : Array[Int] = []
      for (bounds, id) in items {
        if bounds.max_x >= position {
          expected.push(id)
        }
      }
      let actual = tree.query_point(position, position, position, position)
      actual.sort()
      expected.sort()
      assert_eq(actual, expected)
    }
  }
}

///|
test "4D large packing agrees with exhaustive range and time-slice results" {
  let items = Array::makei(10000, fn(i) {
    let x = (i % 100).to_double()
    let y = (i / 100).to_double()
    let z = (i % 17).to_double()
    let t = (i % 31).to_double()
    (@geometry.Box4D::new(x, y, z, t, x + 2.0, y + 3.0, z + 1.0, t + 4.0), i)
  })
  for capacity in [4, 16, 64] {
    let tree = StrTree4D::build(items, node_capacity=capacity)
    for
      query in [
        @geometry.Box4D::new(-1.0, -1.0, -1.0, -1.0, 110.0, 110.0, 20.0, 40.0),
        @geometry.Box4D::new(20.0, 30.0, 5.0, 10.0, 45.0, 55.0, 12.0, 10.0),
        @geometry.Box4D::new(
          200.0, 200.0, 200.0, 200.0, 210.0, 210.0, 210.0, 210.0,
        ),
      ] {
      let expected : Array[Int] = []
      for (bounds, id) in items {
        if bounds.min_x <= query.max_x &&
          bounds.max_x >= query.min_x &&
          bounds.min_y <= query.max_y &&
          bounds.max_y >= query.min_y &&
          bounds.min_z <= query.max_z &&
          bounds.max_z >= query.min_z &&
          bounds.min_t <= query.max_t &&
          bounds.max_t >= query.min_t {
          expected.push(id)
        }
      }
      let actual = tree.query(query)
      actual.sort()
      assert_eq(actual, expected)
      assert_eq(tree.query_count(query), expected.length())
    }
  }
}
