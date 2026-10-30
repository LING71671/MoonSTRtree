///|
/// Concrete integer buffers avoid the polymorphic host push used by generic
/// arrays. Only result collection is specialized; traversal remains MoonBit.
#external
priv type HostIntArray

///|
fn host_int_array(values : Array[Int32]) -> HostIntArray = "%identity"

///|
extern "js" fn append_id(target : HostIntArray, id : Int32) -> Unit =
  #| (target, id) => { target.push(id); }

///|
extern "js" fn append_ids(
  target : HostIntArray,
  source : HostIntArray,
  start : Int32,
  end : Int32,
) -> Unit =
  #| (target, source, start, end) => {
  #|   for (let i = start; i < end; i++) target.push(source[i]);
  #| }

///|
/// The caller appends at the current logical end, with no placeholder slots.
fn write_range_result(
  results : Array[Int32],
  _position : Int32,
  id : Int32,
) -> Unit {
  append_id(host_int_array(results), id)
}

///|
/// Source intervals are proven inside immutable packed storage by the caller.
fn append_leaf_span(
  source : Array[Int32],
  results : Array[Int32],
  start : Int32,
  end : Int32,
  _position : Int32,
) -> Unit {
  append_ids(host_int_array(results), host_int_array(source), start, end)
}
