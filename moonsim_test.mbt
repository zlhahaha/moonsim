///|
test "version is exposed" {
  assert_eq(@moonsim.version(), "0.1.0")
}

///|
test "rng is reproducible from seed" {
  let left = @moonsim.Rng::new(99UL)
  let right = @moonsim.Rng::new(99UL)
  assert_eq(left.next_u64(), right.next_u64())
  assert_eq(left.next_int(1000), right.next_int(1000))
  assert_eq(left.next_bool(), right.next_bool())
}

///|
test "rng normalizes zero seed" {
  let rng = @moonsim.Rng::new(0UL)
  assert_true(rng.state() != 0UL)
}
