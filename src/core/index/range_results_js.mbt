///|
/// Concrete integer buffers avoid the polymorphic host push used by generic
/// arrays. Only result collection is specialized; traversal remains MoonBit.
#external
priv type HostIntArray

///|
fn host_int_array(values : Array[Int]) -> HostIntArray = "%identity"

///|
extern "js" fn append_id(target : HostIntArray, id : Int) -> Unit =
  #| (target, id) => { target.push(id); }

///|
extern "js" fn append_ids(
  target : HostIntArray,
  source : HostIntArray,
  start : Int,
  end : Int,
) -> Unit =
  #| (target, source, start, end) => {
  #|   for (let i = start; i < end; i++) target.push(source[i]);
  #| }

///|
/// The caller appends at the current logical end, with no placeholder slots.
fn write_range_result(results : Array[Int], _position : Int, id : Int) -> Unit {
  append_id(host_int_array(results), id)
}

///|
/// Source intervals are proven inside immutable packed storage by the caller.
fn append_leaf_span(
  source : Array[Int],
  results : Array[Int],
  start : Int,
  end : Int,
  _position : Int,
) -> Unit {
  append_ids(host_int_array(results), host_int_array(source), start, end)
}
