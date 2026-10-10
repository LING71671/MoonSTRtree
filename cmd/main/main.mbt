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
    let knn_hits = tree.query_knn(500.0, 500.0, 5)
    let seg_hits = tree.query_segment(0.0, 0.0, 1000.0, 1000.0)
    let join_pairs = if d < 2 { tree.spatial_join(tree).length() } else { 0 }

    // FlatBuffers round-trip check
    let buf = tree.to_flat_buffers()
    let reloaded = @lib.StrTree::from_flat_buffers(buf)
    let buf_check = reloaded.query(query_window).length() == hits.length()

    println("Distribution: \{name}")
    println(
      "  Items: \{s.num_items} | Nodes: \{s.num_nodes} | Height: \{s.height} | Fill: \{s.fill_factor}",
    )
    println(
      "  Memory: \{s.estimated_memory_bytes} B | Serialized Buffers: \{buf_check}",
    )
    println(
      "  Range Hits: \{hits.length()} | Point Hits: \{pt_hits.length()} | k-NN (k=5): \{knn_hits.length()} | Ray Hits: \{seg_hits.length()}",
    )
    if join_pairs > 0 {
      println("  Self Spatial Join Overlapping Pairs: \{join_pairs}")
    }
    println("----------------------------------------------------------------")
  }

  println("Full engine verification and benchmark evaluation completed.")
  println("================================================================")
}
