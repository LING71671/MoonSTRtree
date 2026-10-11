///|
test "integer packing arithmetic does not overflow" {
  assert_eq(isqrt(2147483647), 46340)
  assert_eq(ceil_div(2147483647, 16), 134217728)
  assert_eq(ceil_div(2147483647, 2147483647), 1)
  assert_eq(ceil_sqrt(2147483647), 46341)
  assert_eq(icbrt(2147483647), 1290)
  assert_eq(ceil_cbrt(2147483647), 1291)
  assert_eq(icbrt(0), 0)
  assert_eq(ceil_cbrt(27), 3)
}
