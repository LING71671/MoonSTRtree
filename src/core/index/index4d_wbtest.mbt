///|
test "StrTree4D spatiotemporal building, range query, point containment, and time slice" {
  let empty = StrTree4D::build([])
  assert_eq(empty.num_items, 0)
  assert_eq(
    empty.query(@geometry.Box4D::new(0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0)),
    [],
  )

  let items : Array[(@geometry.Box4D, Int)] = []
  for i = 0; i < 30; i = i + 1 {
    let fi = i.to_double() * 5.0
    items.push(
      (
        @geometry.Box4D::new(
          fi,
          fi,
          fi,
          i.to_double() * 2.0,
          fi + 10.0,
          fi + 10.0,
          fi + 10.0,
          i.to_double() * 2.0 + 4.0,
        ),
        i,
      ),
    )
  }

  let tree = StrTree4D::build(items, node_capacity=4)
  assert_eq(tree.num_items, 30)
  assert_true(tree.height >= 2)

  // 1. Range query covering first 3 items
  let q_box = @geometry.Box4D::new(0.0, 0.0, 0.0, 0.0, 12.0, 12.0, 12.0, 6.0)
  let hits = tree.query(q_box)
  assert_true(hits.contains(0))
  assert_true(hits.contains(1))
  assert_false(hits.contains(20))

  // 2. Query count zero-allocation equivalence
  let count = tree.query_count(q_box)
  assert_eq(count, hits.length())

  // 3. Point query at specific (x, y, z, t)
  let pt_hits = tree.query_point(1.0, 1.0, 1.0, 1.0)
  assert_true(pt_hits.contains(0))

  // 4. Time slice query at t = 2.0
  let slice_hits = tree.query_time_slice(
    2.0,
    @geometry.Box3D::new(0.0, 0.0, 0.0, 15.0, 15.0, 15.0),
  )
  assert_true(slice_hits.contains(0))
  assert_true(slice_hits.contains(1))

  // 5. Diagnostics stats
  let s = tree.stats()
  assert_eq(s.num_items, 30)
  assert_true(s.fill_factor > 0.0)
}
