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

///|
test "events compare by tick priority and id" {
  let early = @moonsim.ScheduledEvent::new(3, 1, "early")
  let late = @moonsim.ScheduledEvent::new(1, 5, "late")
  let high_priority = @moonsim.ScheduledEvent::new(2, 5, "high", priority=-1)
  let low_id = @moonsim.ScheduledEvent::new(1, 5, "low-id")
  let high_id = @moonsim.ScheduledEvent::new(9, 5, "high-id")
  assert_true(@moonsim.compare_event(early, late) < 0)
  assert_true(@moonsim.compare_event(high_priority, late) < 0)
  assert_true(@moonsim.compare_event(low_id, high_id) < 0)
}

///|
test "event cancellation flag is mutable" {
  let event = @moonsim.ScheduledEvent::new(1, 0, "cancel")
  assert_eq(event.is_cancelled(), false)
  event.cancel()
  assert_eq(event.is_cancelled(), true)
}
