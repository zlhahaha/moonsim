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

///|
test "scheduler executes by tick then insertion id" {
  let sim = @moonsim.Sim::new(seed=42UL)
  let third = sim.schedule_after(10, "third")
  let first = sim.schedule_after(1, "first")
  let second = sim.schedule_after(1, "second")
  assert_eq(third, 1)
  assert_eq(first, 2)
  assert_eq(second, 3)

  let first_event = sim.run_next().unwrap()
  let second_event = sim.run_next().unwrap()
  let third_event = sim.run_next().unwrap()
  assert_eq(first_event.name, "first")
  assert_eq(second_event.name, "second")
  assert_eq(third_event.name, "third")
  assert_eq(sim.time(), 10)
}

///|
test "scheduler honors priority within same tick" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_at(5, "normal"))
  ignore(sim.schedule_at(5, "urgent", priority=-10))
  let event = sim.run_next().unwrap()
  assert_eq(event.name, "urgent")
}

///|
test "cancelled events are skipped" {
  let sim = @moonsim.Sim::new(seed=7UL)
  let dropped = sim.schedule_after(1, "drop-me")
  let kept = sim.schedule_after(2, "keep-me")
  assert_eq(sim.cancel(dropped), true)
  assert_eq(sim.cancel(dropped), false)
  assert_eq(sim.pending_count(), 1)
  let event = sim.run_next().unwrap()
  assert_eq(event.id, kept)
  assert_eq(event.name, "keep-me")
  assert_true(sim.run_next() is None)
}

///|
test "run until idle returns executed step count" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_after(1, "one"))
  ignore(sim.schedule_after(2, "two"))
  assert_eq(sim.run_until_idle(), 2)
  assert_eq(sim.pending_count(), 0)
  assert_eq(sim.run_until_idle(), 0)
}

///|
test "run until idle respects max steps" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_after(1, "one"))
  ignore(sim.schedule_after(2, "two"))
  assert_eq(sim.run_until_idle(max_steps=1), 1)
  assert_eq(sim.pending_count(), 1)
}

///|
test "trace records scheduling cancellation execution and rng" {
  let sim = @moonsim.Sim::new(seed=123UL)
  let dropped = sim.schedule_after(1, "drop")
  ignore(sim.schedule_after(2, "run"))
  ignore(sim.cancel(dropped))
  ignore(sim.next_int(10))
  ignore(sim.run_until_idle())

  let trace = sim.trace()
  assert_eq(trace.length(), 5)
  assert_eq(trace[0].kind, "schedule")
  assert_eq(trace[1].kind, "schedule")
  assert_eq(trace[2].kind, "cancel")
  assert_eq(trace[3].kind, "rng.int")
  assert_eq(trace[4].kind, "execute")
  assert_eq(trace[4].tick, 2)
}

///|
test "trace entry formats useful text" {
  let entry = @moonsim.trace_entry(3, 9, "execute", "job")
  assert_eq(entry.format(), "tick=3 event=9 kind=execute detail=job")
}

///|
test "digest is stable for identical runs" {
  let left = @moonsim.Sim::new(seed=42UL)
  ignore(left.schedule_after(5, "a"))
  ignore(left.schedule_after(2, "b"))
  ignore(left.next_int(100))
  ignore(left.run_until_idle())

  let right = @moonsim.Sim::new(seed=42UL)
  ignore(right.schedule_after(5, "a"))
  ignore(right.schedule_after(2, "b"))
  ignore(right.next_int(100))
  ignore(right.run_until_idle())

  assert_eq(left.digest(), right.digest())
  assert_eq(@moonsim.trace_digest(left.trace()), right.digest())
}

///|
test "digest changes when event order changes" {
  let left = @moonsim.Sim::new()
  ignore(left.schedule_after(1, "a"))
  ignore(left.schedule_after(2, "b"))
  ignore(left.run_until_idle())

  let right = @moonsim.Sim::new()
  ignore(right.schedule_after(2, "b"))
  ignore(right.schedule_after(1, "a"))
  ignore(right.run_until_idle())

  assert_true(left.digest() != right.digest())
}

///|
test "metrics count executed events" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_after(1, "one"))
  ignore(sim.schedule_after(2, "two"))
  ignore(sim.run_until_idle())
  assert_eq(sim.metrics().counter("events_executed"), 2)
  assert_eq(sim.metrics().counter("missing"), 0)
}

///|
test "custom counters are traced and snapshotted" {
  let sim = @moonsim.Sim::new()
  sim.inc_counter("requests")
  sim.inc_counter("requests", delta=3)
  assert_eq(sim.metrics().counter("requests"), 4)
  assert_eq(sim.metrics().snapshot().length(), 1)
  let trace = sim.trace()
  assert_eq(trace[0].kind, "metric.counter")
  assert_eq(trace[1].detail, "requests+=3")
}
