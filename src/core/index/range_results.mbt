///|
/// Reserve result blocks through MoonBit's array API on every backend.
fn write_range_result(
  results : Array[Int32],
  position : Int32,
  id : Int32,
) -> Unit {
  if position == results.length() {
    results.resize(position + 64, 0)
  }
  results.unsafe_set(position, id)
}

///|
fn append_leaf_span(
  source : Array[Int32],
  results : Array[Int32],
  start : Int32,
  end : Int32,
  position : Int32,
) -> Unit {
  source[start:end].blit_to(results, dst_offset=position)
}
