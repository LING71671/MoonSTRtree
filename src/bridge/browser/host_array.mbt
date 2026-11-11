///|
/// Copy only logical elements across the documented JavaScript array boundary.
fn[T] host_array(values : Array[T]) -> FixedArray[T] {
  FixedArray::from_array(values[:])
}
