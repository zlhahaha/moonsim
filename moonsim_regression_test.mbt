///|
test "regression schedule clamps past tick" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_at(10, "future"))
  ignore(sim.run_next())
  ignore(sim.schedule_at(3, "past"))
  let event = sim.run_next().unwrap()
  assert_eq(event.tick, 10)
}

///|
test "regression negative delay schedules now" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_after(-5, "now"))
  let event = sim.run_next().unwrap()
  assert_eq(event.tick, 0)
}

///|
test "regression empty run report is idle" {
  let sim = @moonsim.Sim::new()
  let report = sim.run_report_until_idle()
  assert_eq(report.steps, 0)
  assert_true(report.reason is @moonsim.RunStopReason::Idle)
}

///|
test "regression step returns idle on empty queue" {
  let sim = @moonsim.Sim::new()
  assert_true(sim.step() is @moonsim.RunStep::Idle)
}

///|
test "regression step returns executed event" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_after(1, "one"))
  match sim.step() {
    @moonsim.RunStep::Executed(event) => assert_eq(event.name, "one")
    _ => fail("expected executed step")
  }
}

///|
test "regression repeated single run behaves once" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_repeating(1, 2, 1, "once"))
  assert_eq(sim.run_until_idle(), 1)
}

///|
test "regression repeated normalizes zero interval" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_repeating(1, 0, 3, "pulse"))
  ignore(sim.run_until_idle())
  assert_eq(sim.time(), 3)
}

///|
test "regression priority beats event id" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_at(1, "first", priority=5))
  ignore(sim.schedule_at(1, "second", priority=-1))
  assert_eq(sim.run_next().unwrap().name, "second")
}

///|
test "regression event id tie break is stable" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_at(1, "a"))
  ignore(sim.schedule_at(1, "b"))
  assert_eq(sim.run_next().unwrap().name, "a")
  assert_eq(sim.run_next().unwrap().name, "b")
}

///|
test "regression cancel missing returns false" {
  let sim = @moonsim.Sim::new()
  assert_eq(sim.cancel(999), false)
}

///|
test "regression queue stats empty are zero" {
  let sim = @moonsim.Sim::new()
  let stats = sim.queue_stats()
  assert_eq(stats.pending, 0)
  assert_eq(stats.cancelled, 0)
}

///|
test "regression event views include cancelled status" {
  let sim = @moonsim.Sim::new()
  let id = sim.schedule_after(1, "drop")
  ignore(sim.cancel(id))
  assert_eq(sim.event_views()[0].status, "cancelled")
}

///|
test "regression trace digest empty is stable" {
  let empty : Array[@moonsim.TraceEntry] = []
  assert_eq(@moonsim.trace_digest(empty), @moonsim.trace_digest(empty))
}

///|
test "regression trace text empty is empty" {
  let empty : Array[@moonsim.TraceEntry] = []
  assert_eq(@moonsim.trace_to_text(empty), "")
}

///|
test "regression trace compare empty matches" {
  let left : Array[@moonsim.TraceEntry] = []
  let right : Array[@moonsim.TraceEntry] = []
  assert_eq(@moonsim.compare_traces(left, right).matched, true)
}

///|
test "regression mismatch summary for length differs" {
  let left = [@moonsim.trace_entry(0, 0, "a", "b")]
  let right : Array[@moonsim.TraceEntry] = []
  assert_true(@moonsim.compare_traces(left, right).summary().contains("length differs"))
}

///|
test "regression rng bound zero returns zero" {
  let rng = @moonsim.Rng::new(1UL)
  assert_eq(rng.next_int(0), 0)
}

///|
test "regression rng negative bound returns zero" {
  let rng = @moonsim.Rng::new(1UL)
  assert_eq(rng.next_int(-3), 0)
}

///|
test "regression range inverted returns low" {
  let rng = @moonsim.Rng::new(1UL)
  assert_eq(rng.next_range(10, 3), 10)
}

///|
test "regression choose singleton returns item" {
  let rng = @moonsim.Rng::new(1UL)
  assert_true(rng.choose(["only"]) == Some("only"))
}

///|
test "regression shuffle empty stays empty" {
  let rng = @moonsim.Rng::new(1UL)
  let empty : Array[Int] = []
  assert_eq(rng.shuffle(empty).length(), 0)
}

///|
test "regression weighted negative treated as zero" {
  let rng = @moonsim.Rng::new(1UL)
  let choices = [@moonsim.weighted_choice("bad", -5)]
  assert_true(rng.choose_weighted(choices) is None)
}

///|
test "regression sim choose empty traces none index" {
  let sim = @moonsim.Sim::new()
  let empty : Array[String] = []
  assert_true(sim.choose("empty", empty) is None)
  assert_true(sim.trace()[0].detail.contains("-1"))
}

///|
test "regression metrics default gauge is zero" {
  let metrics = @moonsim.Metrics::new()
  assert_eq(metrics.gauge("x"), 0)
}

///|
test "regression metrics sample missing summary is zero" {
  let metrics = @moonsim.Metrics::new()
  let summary = metrics.summary("missing")
  assert_eq(summary.count, 0)
  assert_eq(summary.average(), 0.0)
}

///|
test "regression metric snapshots copy counters" {
  let metrics = @moonsim.Metrics::new()
  metrics.inc("a")
  let snapshot = metrics.snapshot()
  metrics.inc("a")
  assert_eq(snapshot[0].value, 1)
  assert_eq(metrics.counter("a"), 2)
}

///|
test "regression gauge snapshots copy gauges" {
  let metrics = @moonsim.Metrics::new()
  metrics.set_gauge("g", 2)
  let snapshot = metrics.gauge_snapshot()
  metrics.set_gauge("g", 5)
  assert_eq(snapshot[0].value, 2)
}

///|
test "regression sample snapshots copy samples" {
  let metrics = @moonsim.Metrics::new()
  metrics.sample("s", 2)
  let snapshot = metrics.sample_snapshot()
  metrics.sample("s", 5)
  assert_eq(snapshot.length(), 1)
}

///|
test "regression scenario no expectations passes" {
  let scenario = @moonsim.Scenario::new("empty")
  let report = scenario.verify(scenario.create_sim())
  assert_eq(report.passed, true)
}

///|
test "regression scenario gauge expectation fails" {
  let scenario = @moonsim.Scenario::new("gauge-fail").expect_gauge("depth", 9)
  let sim = scenario.create_sim()
  sim.set_gauge("depth", 1)
  let report = scenario.verify(sim)
  assert_eq(report.passed, false)
}

///|
test "regression scenario max steps leaves pending" {
  let scenario = @moonsim.Scenario::new("limit", max_steps=1).expect_pending(1)
  let sim = scenario.create_sim()
  ignore(sim.schedule_after(1, "a"))
  ignore(sim.schedule_after(2, "b"))
  let report = scenario.verify(sim)
  assert_eq(report.passed, true)
}

///|
test "regression snapshot records digest" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_after(1, "a"))
  let snapshot = sim.snapshot(name="s")
  assert_eq(snapshot.digest, sim.digest())
}

///|
test "regression fork records fork trace" {
  let sim = @moonsim.Sim::new()
  let fork = sim.snapshot(name="s").fork("branch")
  assert_true(fork.trace_text().contains("fork"))
}

///|
test "regression compare equal forks can match" {
  let sim = @moonsim.Sim::new()
  let snapshot = sim.snapshot(name="s")
  let left = snapshot.fork("same")
  let right = snapshot.fork("same")
  let comparison = @moonsim.compare_forks("l", left, "r", right)
  assert_eq(comparison.same_digest, true)
}

///|
test "regression backoff normalizes invalid config" {
  let backoff = @moonsim.Backoff::new(initial=-1, factor=0, max_delay=0, jitter=-1)
  let rng = @moonsim.Rng::new(1UL)
  assert_eq(backoff.next_delay(rng), 1)
}

///|
test "regression timer plan normalizes invalid values" {
  let plan = @moonsim.timer_plan("t", start_after=-1, interval=0, times=0)
  let sim = @moonsim.Sim::new()
  ignore(sim.install_timer(plan))
  assert_eq(sim.run_until_idle(), 1)
}

///|
test "regression timeout beats urgent normal event" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_at(1, "urgent", priority=-50))
  ignore(sim.schedule_timeout(1, "x"))
  assert_eq(sim.run_next().unwrap().name, "timeout:x")
}

///|
test "regression state machine action can be empty" {
  let result = @moonsim.StateMachine::new("m", "a")
    .add(@moonsim.transition("a", "go", "b"))
    .send("go")
  assert_eq(result.action, "")
}

///|
test "regression state machine rejected transition keeps state" {
  let machine = @moonsim.StateMachine::new("m", "a")
  ignore(machine.send("missing"))
  assert_eq(machine.state(), "a")
}

///|
test "regression state machine record rejected increments counter" {
  let sim = @moonsim.Sim::new()
  let machine = @moonsim.StateMachine::new("m", "a")
  sim.record_transition(machine, machine.send("missing"))
  assert_eq(sim.metrics().counter("state.rejected"), 1)
}

///|
test "regression message bus starts ids at one" {
  let sim = @moonsim.Sim::new()
  let bus = @moonsim.MessageBus::new()
  assert_eq(bus.send(sim, "a", "b", "x"), 1)
  assert_eq(bus.send(sim, "a", "b", "y"), 2)
}

///|
test "regression message negative delay delivers now" {
  let sim = @moonsim.Sim::new()
  let bus = @moonsim.MessageBus::new()
  ignore(bus.send(sim, "a", "b", "x", delay=-5))
  assert_eq(bus.messages()[0].deliver_tick, 0)
}

///|
test "regression message pending ignores dropped" {
  let sim = @moonsim.Sim::new()
  let bus = @moonsim.MessageBus::new()
  let id = bus.send(sim, "a", "b", "x", delay=10)
  ignore(bus.drop(sim, id))
  assert_eq(bus.pending(sim), 0)
}

///|
test "regression deliver due before time returns zero" {
  let sim = @moonsim.Sim::new()
  let bus = @moonsim.MessageBus::new()
  ignore(bus.send(sim, "a", "b", "x", delay=10))
  assert_eq(bus.deliver_due(sim), 0)
}

///|
test "regression run until tick with no events is idle" {
  let sim = @moonsim.Sim::new()
  let report = sim.run_until_tick(5)
  assert_true(report.reason is @moonsim.RunStopReason::Idle)
}

///|
test "regression run until tick max steps wins" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_repeating(0, 1, 5, "pulse"))
  let report = sim.run_until_tick(10, max_steps=2)
  assert_true(report.reason is @moonsim.RunStopReason::StepLimit)
}

///|
test "regression trace stats sees message class" {
  let stats = @moonsim.trace_stats([@moonsim.trace_entry(0, 0, "message.send", "a")])
  assert_eq(stats.messages, 1)
}

///|
test "regression timeline empty is empty" {
  let sim = @moonsim.Sim::new()
  assert_eq(sim.timeline_text(), "")
}

///|
test "regression pending count ignores cancelled repeat" {
  let sim = @moonsim.Sim::new()
  let id = sim.schedule_repeating(1, 1, 3, "x")
  ignore(sim.cancel(id))
  assert_eq(sim.pending_count(), 0)
}

///|
test "regression digest includes metric trace" {
  let left = @moonsim.Sim::new()
  let right = @moonsim.Sim::new()
  left.inc_counter("x")
  right.inc_counter("y")
  assert_true(left.digest() != right.digest())
}

///|
test "regression digest includes rng range detail" {
  let left = @moonsim.Sim::new(seed=1UL)
  let right = @moonsim.Sim::new(seed=1UL)
  ignore(left.next_range(0, 3))
  ignore(right.next_range(1, 4))
  assert_true(left.digest() != right.digest())
}

///|
test "regression scenario summary includes digest" {
  let scenario = @moonsim.Scenario::new("summary")
  let report = scenario.verify(scenario.create_sim())
  assert_true(report.summary().contains("digest="))
}

///|
test "regression sample average handles negatives" {
  let metrics = @moonsim.Metrics::new()
  metrics.sample("delta", -2)
  metrics.sample("delta", 2)
  assert_eq(metrics.summary("delta").average(), 0.0)
}

///|
test "regression weighted choice can select only positive choice" {
  let rng = @moonsim.Rng::new(1UL)
  let choices = [
    @moonsim.weighted_choice("zero", 0),
    @moonsim.weighted_choice("one", 1),
  ]
  assert_true(rng.choose_weighted(choices) == Some("one"))
}

///|
test "regression event next repeat decrements remaining runs" {
  let event = @moonsim.ScheduledEvent::repeating(1, 0, "r", 2, 3)
  let next = event.next_repeat()
  assert_eq(next.tick, 2)
  assert_eq(next.remaining_runs, 2)
}

///|
test "regression duration scale normalizes negative result" {
  assert_eq(@moonsim.duration(3).scale(-2).to_int(), 0)
}

///|
test "regression event id wrapper exposes int" {
  assert_eq(@moonsim.event_id(42).to_int(), 42)
}

///|
test "regression trace line contains separators" {
  let line = @moonsim.trace_entry(1, 2, "k", "d").to_line()
  assert_eq(line, "1|2|k|d")
}

///|
test "regression queue stats after execution has no pending" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_after(1, "a"))
  ignore(sim.run_until_idle())
  assert_eq(sim.queue_stats().pending, 0)
}

///|
test "model queue result is deterministic" {
  let left = @moonsim.run_queue_model(@moonsim.queue_config())
  let right = @moonsim.run_queue_model(@moonsim.queue_config())
  assert_eq(left.digest, right.digest)
  assert_eq(left.customers, 5)
}

///|
test "model queue normalizes negative customers" {
  let result = @moonsim.run_queue_model(@moonsim.queue_config(customers=-5))
  assert_eq(result.customers, 0)
  assert_eq(result.events_executed, 0)
}

///|
test "model retry succeeds after configured failures" {
  let result = @moonsim.run_retry_model(@moonsim.retry_config(fail_until=2))
  assert_eq(result.success, true)
  assert_eq(result.retries, 2)
}

///|
test "model retry can exhaust attempts" {
  let result = @moonsim.run_retry_model(@moonsim.retry_config(max_attempts=2, fail_until=5))
  assert_eq(result.success, false)
  assert_eq(result.attempts, 2)
}

///|
test "model traffic produces configured cars" {
  let result = @moonsim.run_traffic_model(@moonsim.traffic_config(cars=7))
  assert_eq(result.cars, 7)
  assert_true(result.events_executed > 0)
}

///|
test "model summaries render stable lines" {
  let queue = @moonsim.queue_summary(@moonsim.run_queue_model(@moonsim.queue_config(customers=1)))
  assert_true(queue.line().contains("queue tick="))
}

///|
test "report renders metrics counters" {
  let metrics = @moonsim.Metrics::new()
  metrics.inc("events", delta=3)
  let report = @moonsim.render_metrics_report(metrics)
  assert_true(report.contains("counter events = 3"))
}

///|
test "report renders trace stats" {
  let trace = [@moonsim.trace_entry(0, 1, "schedule", "a")]
  let report = @moonsim.render_trace_report(trace)
  assert_true(report.contains("# Trace"))
  assert_true(report.contains("schedules=1"))
}

///|
test "report renders sim summary" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_after(1, "a"))
  let report = @moonsim.render_sim_report(sim, title="Demo")
  assert_true(report.contains("# Demo"))
  assert_true(report.contains("pending: 1"))
}

///|
test "report renders scenario failure" {
  let scenario = @moonsim.Scenario::new("bad").expect_counter("x", 1)
  let report = scenario.verify(scenario.create_sim())
  let text = @moonsim.render_scenario_report(report)
  assert_true(text.contains("# Scenario bad"))
  assert_true(text.contains("expected=1 actual=0"))
}

///|
test "report renders model summaries" {
  let summaries = [
    @moonsim.queue_summary(@moonsim.run_queue_model(@moonsim.queue_config(customers=1))),
    @moonsim.retry_summary(@moonsim.run_retry_model(@moonsim.retry_config(fail_until=0))),
  ]
  let text = @moonsim.render_model_summaries(summaries)
  assert_true(text.contains("Model Summaries"))
  assert_true(text.contains("retry tick="))
}

///|
test "validation passes clean sim" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_after(1, "a"))
  assert_eq(sim.validate().passed(), true)
}

///|
test "validation trace catches negative tick" {
  let report = @moonsim.validate_trace([@moonsim.trace_entry(-1, 0, "x", "y")])
  assert_eq(report.passed(), false)
  assert_true(report.text().contains("negative-trace-tick"))
}

///|
test "validation metrics catches empty counter name" {
  let metrics = @moonsim.Metrics::new()
  metrics.inc("")
  let report = @moonsim.validate_metrics(metrics)
  assert_eq(report.passed(), false)
  assert_true(report.summary().contains("FAIL metrics"))
}

///|
test "validation report text lists issues" {
  let issue = @moonsim.validation_issue("code", "message", severity="warn")
  let report : @moonsim.ValidationReport = { subject: "x", issues: [issue] }
  assert_true(report.text().contains("warn code"))
}

///|
test "demo catalog includes first prize examples" {
  let names = @moonsim.demo_names()
  assert_true(names.length() >= 7)
  assert_true(@moonsim.find_demo("queue") is Some(_))
}

///|
test "demo descriptor feature lookup works" {
  let demo = @moonsim.find_demo("game_loop").unwrap()
  assert_eq(demo.has_feature("snapshot"), true)
  assert_eq(demo.has_feature("missing"), false)
}

///|
test "demo catalog renders commands" {
  let text = @moonsim.render_demo_catalog()
  assert_true(text.contains("moon run examples/protocol"))
  assert_true(text.contains("state-machine"))
}

///|
test "missing demo returns none" {
  assert_true(@moonsim.find_demo("nope") is None)
}
