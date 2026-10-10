///|
/// CLI demonstration and benchmark utility for MoonSTRtree.
fn main {
  println("==================================================")
  println(" MoonSTRtree: Fast Packed 2D Spatial Index Engine ")
  println("==================================================")

  // 1. Generate 100 sample spatial elements across 10x10 grid
  let items : Array[(@lib.Rect, Int)] = []
  for i = 0; i < 100; i = i + 1 {
    let x = (i % 10).to_double() * 10.0
    let y = (i / 10).to_double() * 10.0
    let r = @lib.Rect::new(x, y, x + 5.0, y + 5.0)
    items.push((r, i))
  }

  // 2. Build packed STR tree with node capacity M = 16
  let tree = @lib.StrTree::build(items, node_capacity=16)
  let s = tree.stats()

  println("Index Construction Completed:")
  println("  Indexed Items   : \{s.num_items}")
  println("  Total Nodes     : \{s.num_nodes}")
  println("  Tree Height     : \{s.height}")
  println("  Node Capacity   : \{s.node_capacity}")
  println("  Fill Factor     : \{s.fill_factor}")
  println("  Estimated Memory: \{s.estimated_memory_bytes} bytes")

  // 3. Execute range query window
  let search_win = @lib.Rect::new(15.0, 15.0, 35.0, 35.0)
  let range_hits = tree.query(search_win)
  println("\nRange Query [15, 15] x [35, 35]:")
  println("  Hits Count      : \{range_hits.length()}")

  // 4. Execute point containment query
  let point_hits = tree.query_point(22.0, 22.0)
  println("\nPoint Query (22.0, 22.0):")
  println("  Hits Count      : \{point_hits.length()}")
  println("==================================================")
}
