///|
/// Reserve small result blocks, then fill slots with an index proven in bounds.
fn write_range_result(results : Array[Int], position : Int, id : Int) -> Unit {
  if position == results.length() {
    results.resize(position + 64, 0)
  }
  results.unsafe_set(position, id)
}

///|
fn append_leaf_span(
  source : Array[Int],
  results : Array[Int],
  start : Int,
  end : Int,
  position : Int,
) -> Unit {
  source[start:end].blit_to(results, dst_offset=position)
}
