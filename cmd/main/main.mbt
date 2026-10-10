///|
/// CLI demonstration and benchmark utility for MoonSTRtree.
fn main {
  println("================================================================")
  println("     MoonSTRtree: Packed 2D Spatial Index Engine & Benchmark    ")
  println("================================================================")

  let distributions : Array[(String, Array[(@lib.Rect, Int)])] = [
    ("Uniform Random", @lib.generate_uniform(@lib.Rng::new(42), 1000)),
    (
      "Clustered Gaussian",
      @lib.generate_clustered(@lib.Rng::new(43), 1000, num_clusters=8),
    ),
    ("Diagonal Degenerate", @lib.generate_diagonal(@lib.Rng::new(44), 1000)),
    ("Nested Concentric", @lib.generate_concentric(1000)),
    ("Regular Grid", @lib.generate_grid(25, 40)),
  ]

  let query_window = @lib.Rect::new(200.0, 200.0, 600.0, 600.0)

  for d = 0; d < distributions.length(); d = d + 1 {
    let (name, items) = distributions[d]
    let tree = @lib.StrTree::build(items, node_capacity=16)
    let s = tree.stats()
    let hits = tree.query(query_window)
    let pt_hits = tree.query_point(400.0, 400.0)

    println("Distribution: \{name}")
    println(
      "  Items: \{s.num_items} | Nodes: \{s.num_nodes} | Height: \{s.height}",
    )
    println(
      "  Fill Factor: \{s.fill_factor} | Memory: \{s.estimated_memory_bytes} B",
    )
    println(
      "  Range Query Hits: \{hits.length()} | Point Query Hits: \{pt_hits.length()}",
    )
    println("----------------------------------------------------------------")
  }

  println("Benchmark evaluation across 5 synthetic distributions completed.")
  println("================================================================")
}
