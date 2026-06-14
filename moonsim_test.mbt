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

///|
test "time wrappers normalize and compare" {
  let start = @moonsim.tick(-10)
  let delta = @moonsim.duration(5)
  let end = start.plus(delta)
  assert_eq(start.to_int(), 0)
  assert_eq(delta.to_int(), 5)
  assert_eq(end.to_int(), 5)
  assert_eq(end.diff(start).to_int(), 5)
  assert_true(start.compare(end) < 0)
}

///|
test "schedule typed tick and duration" {
  let sim = @moonsim.Sim::new()
  let a = sim.schedule_at_tick(@moonsim.tick(3), "typed-at")
  let b = sim.schedule_after_duration(@moonsim.duration(5), "typed-after")
  assert_eq(a.to_int(), 1)
  assert_eq(b.to_int(), 2)
  assert_eq(sim.run_until_idle(), 2)
  assert_eq(sim.time(), 5)
}

///|
test "repeating events reschedule fixed number of times" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_repeating(1, 3, 4, "heartbeat"))
  let report = sim.run_report_until_idle()
  assert_eq(report.steps, 4)
  assert_eq(report.final_tick, 10)
  assert_eq(report.pending, 0)
  assert_true(report.reason is @moonsim.RunStopReason::Idle)
}

///|
test "run until tick stops before future event" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_after(2, "inside"))
  ignore(sim.schedule_after(9, "outside"))
  let report = sim.run_until_tick(5)
  assert_eq(report.steps, 1)
  assert_eq(report.final_tick, 2)
  assert_eq(report.pending, 1)
  assert_true(report.reason is @moonsim.RunStopReason::TickLimit)
}

///|
test "rng range is bounded and reproducible" {
  let left = @moonsim.Rng::new(7UL)
  let right = @moonsim.Rng::new(7UL)
  let a = left.next_range(10, 20)
  let b = right.next_range(10, 20)
  assert_eq(a, b)
  assert_true(a >= 10 && a < 20)
  assert_eq(left.next_range(5, 5), 5)
}

///|
test "rng choose returns stable option" {
  let left = @moonsim.Rng::new(8UL)
  let right = @moonsim.Rng::new(8UL)
  let items = ["a", "b", "c"]
  assert_true(left.choose(items) == right.choose(items))
  let empty : Array[String] = []
  assert_true(left.choose(empty) is None)
}

///|
test "rng shuffle is reproducible" {
  let left = @moonsim.Rng::new(9UL)
  let right = @moonsim.Rng::new(9UL)
  let items = [1, 2, 3, 4, 5]
  let a = left.shuffle(items)
  let b = right.shuffle(items)
  assert_eq(a.length(), b.length())
  for i in 0..<a.length() {
    assert_eq(a[i], b[i])
  }
}

///|
test "weighted choice ignores zero total" {
  let rng = @moonsim.Rng::new(1UL)
  let choices = [@moonsim.weighted_choice("never", 0)]
  assert_true(rng.choose_weighted(choices) is None)
}

///|
test "weighted choice returns reproducible label" {
  let left = @moonsim.Rng::new(10UL)
  let right = @moonsim.Rng::new(10UL)
  let choices = [
    @moonsim.weighted_choice("low", 1),
    @moonsim.weighted_choice("high", 9),
  ]
  assert_true(left.choose_weighted(choices) == right.choose_weighted(choices))
}

///|
test "sim rng helpers are traced" {
  let sim = @moonsim.Sim::new(seed=11UL)
  ignore(sim.next_range(1, 3))
  ignore(sim.choose("letter", ["x", "y"]))
  ignore(sim.shuffle("numbers", [1, 2, 3]))
  ignore(sim.choose_weighted("route", [@moonsim.weighted_choice("a", 1)]))
  let trace = sim.trace()
  assert_eq(trace.length(), 4)
  assert_eq(trace[0].kind, "rng.range")
  assert_eq(trace[1].kind, "rng.choose")
  assert_eq(trace[2].kind, "rng.shuffle")
  assert_eq(trace[3].kind, "rng.weighted")
}

///|
test "trace text exports stable line format" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_after(2, "hello"))
  let text = sim.trace_text()
  assert_eq(text, "0|1|schedule|hello")
}

///|
test "trace comparison matches identical traces" {
  let left = @moonsim.Sim::new(seed=1UL)
  ignore(left.schedule_after(1, "a"))
  ignore(left.run_until_idle())
  let right = @moonsim.Sim::new(seed=1UL)
  ignore(right.schedule_after(1, "a"))
  ignore(right.run_until_idle())
  let comparison = @moonsim.compare_traces(left.trace(), right.trace())
  assert_eq(comparison.matched, true)
  assert_eq(comparison.checked, left.trace().length())
  assert_true(comparison.mismatch is None)
}

///|
test "trace comparison reports changed entry" {
  let left = [@moonsim.trace_entry(0, 1, "schedule", "a")]
  let right = [@moonsim.trace_entry(0, 1, "schedule", "b")]
  let comparison = @moonsim.compare_traces(left, right)
  assert_eq(comparison.matched, false)
  let mismatch = comparison.mismatch.unwrap()
  assert_eq(mismatch.index, 0)
  assert_eq(mismatch.reason, "entry differs")
}

///|
test "trace comparison reports length mismatch" {
  let left = [@moonsim.trace_entry(0, 1, "schedule", "a")]
  let right : Array[@moonsim.TraceEntry] = []
  let comparison = @moonsim.compare_traces(left, right)
  assert_eq(comparison.matched, false)
  assert_eq(comparison.mismatch.unwrap().reason, "length differs")
}

///|
test "trace comparison summary is human readable" {
  let left = [@moonsim.trace_entry(0, 1, "schedule", "a")]
  let right = [@moonsim.trace_entry(0, 1, "schedule", "b")]
  let summary = @moonsim.compare_traces(left, right).summary()
  assert_true(summary.contains("mismatch index=0"))
}

///|
test "gauges keep latest value" {
  let metrics = @moonsim.Metrics::new()
  metrics.set_gauge("queue_depth", 3)
  metrics.set_gauge("queue_depth", 1)
  assert_eq(metrics.gauge("queue_depth"), 1)
  assert_eq(metrics.gauge("missing"), 0)
}

///|
test "samples produce histogram summary" {
  let metrics = @moonsim.Metrics::new()
  metrics.sample("latency", 5)
  metrics.sample("latency", 9)
  metrics.sample("latency", 1)
  let summary = metrics.summary("latency")
  assert_eq(summary.count, 3)
  assert_eq(summary.min, 1)
  assert_eq(summary.max, 9)
  assert_eq(summary.sum, 15)
  assert_eq(summary.average(), 5.0)
}

///|
test "sim gauge and sample are traced" {
  let sim = @moonsim.Sim::new()
  sim.set_gauge("depth", 2)
  sim.sample("wait", 7)
  assert_eq(sim.metrics().gauge("depth"), 2)
  assert_eq(sim.metrics().sample_count("wait"), 1)
  assert_eq(sim.trace()[0].kind, "metric.gauge")
  assert_eq(sim.trace()[1].kind, "metric.sample")
}

///|
test "metric counter delta compares snapshots" {
  let before = @moonsim.Metrics::new()
  before.inc("requests", delta=2)
  let after = @moonsim.Metrics::new()
  after.inc("requests", delta=5)
  assert_eq(@moonsim.metrics_counter_delta(before, after, "requests"), 3)
}

///|
test "scenario verifies counters and final tick" {
  let scenario = @moonsim.Scenario::new("basic")
    .expect_counter("events_executed", 2)
    .expect_final_tick(2)
    .expect_pending(0)
  let sim = scenario.create_sim()
  ignore(sim.schedule_after(1, "one"))
  ignore(sim.schedule_after(2, "two"))
  let report = scenario.verify(sim)
  assert_eq(report.passed, true)
  assert_eq(report.failures.length(), 0)
  assert_true(report.summary().contains("PASS basic"))
}

///|
test "scenario reports counter failure" {
  let scenario = @moonsim.Scenario::new("bad").expect_counter("events_executed", 3)
  let sim = scenario.create_sim()
  ignore(sim.schedule_after(1, "one"))
  let report = scenario.verify(sim)
  assert_eq(report.passed, false)
  assert_eq(report.failures.length(), 1)
  assert_true(report.failure_text().contains("expected=3 actual=1"))
}

///|
test "scenario can verify digest" {
  let sim = @moonsim.Sim::new(seed=1UL)
  ignore(sim.schedule_after(1, "one"))
  ignore(sim.run_until_idle())
  let digest = sim.digest()

  let scenario = @moonsim.Scenario::new("digest").expect_digest(digest)
  let rerun = scenario.create_sim()
  ignore(rerun.schedule_after(1, "one"))
  let report = scenario.verify(rerun)
  assert_eq(report.passed, true)
}

///|
test "scenario verifies gauge" {
  let scenario = @moonsim.Scenario::new("gauge").expect_gauge("depth", 4)
  let sim = scenario.create_sim()
  sim.set_gauge("depth", 4)
  let report = scenario.verify(sim)
  assert_eq(report.passed, true)
}
