///|
/// Both providers return independently owned host arrays through the same API.
fn[T] host_array(values : Array[T]) -> FixedArray[T] {
  FixedArray::from_array(values[:])
}
