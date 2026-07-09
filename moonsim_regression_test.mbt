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
  assert_true(
    @moonsim.compare_traces(left, right).summary().contains("length differs"),
  )
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
  let backoff = @moonsim.Backoff::new(
    initial=-1,
    factor=0,
    max_delay=0,
    jitter=-1,
  )
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
  let stats = @moonsim.trace_stats([
    @moonsim.trace_entry(0, 0, "message.send", "a"),
  ])
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
  let result = @moonsim.run_retry_model(
    @moonsim.retry_config(max_attempts=2, fail_until=5),
  )
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
  let queue = @moonsim.queue_summary(
    @moonsim.run_queue_model(@moonsim.queue_config(customers=1)),
  )
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
    @moonsim.queue_summary(
      @moonsim.run_queue_model(@moonsim.queue_config(customers=1)),
    ),
    @moonsim.retry_summary(
      @moonsim.run_retry_model(@moonsim.retry_config(fail_until=0)),
    ),
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
test "demo catalog includes reusable examples" {
  let names = @moonsim.demo_names()
  assert_true(names.length() >= 9)
  assert_true(@moonsim.find_demo("queue") is Some(_))
  assert_true(@moonsim.find_demo("network") is Some(_))
  assert_true(@moonsim.find_demo("load_balancer") is Some(_))
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
  assert_true(text.contains("moon run examples/network"))
  assert_true(text.contains("state-machine"))
}

///|
test "missing demo returns none" {
  assert_true(@moonsim.find_demo("nope") is None)
}

///|
test "experiment aggregates model summaries" {
  let report = @moonsim.demo_experiment()
  assert_eq(report.case_count(), 7)
  assert_true(report.total_events() > 0)
  assert_true(report.max_final_tick() > 0)
}

///|
test "experiment combined digest is stable" {
  let left = @moonsim.demo_experiment()
  let right = @moonsim.demo_experiment()
  assert_eq(left.combined_digest(), right.combined_digest())
}

///|
test "experiment render includes notes" {
  let text = @moonsim.demo_experiment().render()
  assert_true(text.contains("moonsim model demo"))
  assert_true(text.contains("deterministic backoff"))
  assert_true(text.contains("worker scheduling model"))
}

///|
test "experiment comparison matches identical reports" {
  let left = @moonsim.demo_experiment()
  let right = @moonsim.demo_experiment()
  assert_eq(@moonsim.compare_experiments(left, right).matched, true)
}

///|
test "experiment comparison detects changed cases" {
  let left = @moonsim.demo_experiment()
  let right = @moonsim.ExperimentReport::new("small").add(
    @moonsim.experiment_case(
      "queue",
      @moonsim.queue_summary(
        @moonsim.run_queue_model(@moonsim.queue_config(customers=1)),
      ),
    ),
  )
  assert_eq(@moonsim.compare_experiments(left, right).matched, false)
}

///|
test "render experiment report delegates to report render" {
  let text = @moonsim.render_experiment_report(@moonsim.demo_experiment())
  assert_true(text.contains("# Experiment"))
}

///|
test "feature matrix includes demos and features" {
  let matrix = @moonsim.build_feature_matrix()
  assert_true(matrix.demos.length() >= 9)
  assert_true(matrix.features.length() >= 10)
  assert_true(
    matrix.cells.length() >= matrix.demos.length() * matrix.features.length(),
  )
}

///|
test "feature matrix supports known feature" {
  let matrix = @moonsim.build_feature_matrix()
  assert_eq(matrix.supports("game_loop", "snapshot"), true)
  assert_eq(matrix.supports("queue", "snapshot"), false)
}

///|
test "feature matrix counts demo features" {
  let matrix = @moonsim.build_feature_matrix()
  assert_true(matrix.feature_count("protocol") >= 3)
}

///|
test "feature matrix counts demos by feature" {
  let matrix = @moonsim.build_feature_matrix()
  assert_true(matrix.demo_count_for_feature("metrics") >= 2)
}

///|
test "feature matrix renders readable report" {
  let text = @moonsim.render_feature_matrix()
  assert_true(text.contains("# Feature Matrix"))
  assert_true(text.contains("game_loop"))
}

///|
test "feature coverage counts supported cells" {
  let coverage = @moonsim.build_feature_matrix().coverage()
  assert_true(coverage.supported_cells > 0)
  assert_true(coverage.total_cells >= coverage.supported_cells)
}

///|
test "feature coverage percent is bounded" {
  let percent = @moonsim.build_feature_matrix().coverage().percent()
  assert_true(percent >= 0)
  assert_true(percent <= 100)
}

///|
test "feature coverage renders one line" {
  let line = @moonsim.render_feature_coverage()
  assert_true(line.contains("coverage="))
}

///|
test "trace query filters by kind detail and tick range" {
  let entries = [
    @moonsim.trace_entry(0, 1, "schedule", "alpha"),
    @moonsim.trace_entry(2, 1, "execute", "alpha"),
    @moonsim.trace_entry(5, 2, "execute", "beta"),
  ]
  assert_eq(@moonsim.trace_filter_kind(entries, "execute").length(), 2)
  assert_eq(@moonsim.trace_filter_detail(entries, "beta").length(), 1)
  assert_eq(@moonsim.trace_filter_tick_range(entries, 1, 3).length(), 1)
  let result = @moonsim.query_trace(
    entries,
    @moonsim.trace_query(kind="execute"),
  )
  assert_eq(result.kind_count("execute"), 2)
  assert_true(result.summary().contains("last_tick=5"))
}

///|
test "trace expectations describe replayable properties" {
  let entries = [
    @moonsim.trace_entry(0, 1, "schedule", "first"),
    @moonsim.trace_entry(1, 1, "execute", "first"),
  ]
  assert_eq(
    @moonsim.expect_trace_contains_kind(entries, "execute").passed,
    true,
  )
  assert_eq(
    @moonsim.expect_trace_kind_count(entries, "execute", 1).passed,
    true,
  )
  assert_eq(
    @moonsim.expect_trace_contains_detail(entries, "first").passed,
    true,
  )
  assert_eq(
    @moonsim.expect_trace_order(entries, "schedule", "first").passed,
    false,
  )
  assert_eq(@moonsim.expect_trace_monotonic_ticks(entries).passed, true)
  assert_eq(
    @moonsim.expect_trace_digest(entries, @moonsim.trace_digest(entries)).passed,
    true,
  )
}

///|
test "trace monotonic expectation catches regressions" {
  let entries = [
    @moonsim.trace_entry(3, 1, "execute", "late"),
    @moonsim.trace_entry(2, 2, "execute", "early"),
  ]
  let expectation = @moonsim.expect_trace_monotonic_ticks(entries)
  assert_eq(expectation.passed, false)
  assert_true(expectation.actual.contains("after"))
}

///|
test "replay baseline matches identical simulation" {
  let left = @moonsim.Sim::new(seed=55UL)
  ignore(left.schedule_after(1, "a"))
  left.inc_counter("requests")
  ignore(left.run_until_idle())
  let baseline = @moonsim.replay_baseline("same", left)

  let right = @moonsim.Sim::new(seed=55UL)
  ignore(right.schedule_after(1, "a"))
  right.inc_counter("requests")
  ignore(right.run_until_idle())
  let comparison = @moonsim.compare_replay(baseline, right)
  assert_eq(comparison.matched, true)
  assert_true(comparison.summary().contains("matched"))
}

///|
test "replay baseline detects counter mismatch" {
  let left = @moonsim.Sim::new()
  left.inc_counter("requests")
  let baseline = @moonsim.replay_baseline("counter", left)
  let right = @moonsim.Sim::new()
  right.inc_counter("requests", delta=2)
  let comparison = @moonsim.compare_replay(baseline, right)
  assert_eq(comparison.matched, false)
  assert_eq(comparison.counter_mismatches, 1)
}

///|
test "scenario supports range trace and validation expectations" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_after(1, "a"))
  sim.inc_counter("jobs", delta=3)
  sim.sample("wait", 4)
  sim.sample("wait", 6)
  let report = @moonsim.Scenario::new("range")
    .expect_counter_range("jobs", 1, 5)
    .expect_final_tick_range(1, 2)
    .expect_trace_kind_count("execute", 1)
    .expect_summary_average_range("wait", 4, 6)
    .expect_no_validation_issues()
    .verify(sim)
  assert_eq(report.passed, true)
}

///|
test "scenario suite aggregates pass and failure reports" {
  let ok = @moonsim.Sim::new()
  ok.inc_counter("x")
  let bad = @moonsim.Sim::new()
  let suite = @moonsim.ScenarioSuite::new("suite")
    .add(@moonsim.Scenario::new("ok").expect_counter("x", 1), ok)
    .add(@moonsim.Scenario::new("bad").expect_counter("missing", 1), bad)
  let report = suite.run()
  assert_eq(report.passed(), false)
  assert_eq(report.passed_count(), 1)
  assert_eq(report.failed_count(), 1)
  assert_true(report.render().contains("FAIL bad"))
}

///|
test "metric diff compares snapshots" {
  let metrics = @moonsim.Metrics::new()
  metrics.inc("jobs", delta=1)
  metrics.set_gauge("depth", 4)
  let before = metrics.metric_snapshot()
  metrics.inc("jobs", delta=3)
  metrics.set_gauge("depth", 1)
  metrics.sample("wait", 7)
  let diff = metrics.diff_from(before)
  assert_eq(diff.counters.length(), 1)
  assert_eq(diff.counters[0].delta, 3)
  assert_eq(diff.gauges[0].delta, -3)
  assert_eq(diff.sample_delta, 1)
  assert_true(diff.summary().contains("sample_delta=1"))
}

///|
test "sample distribution is deterministic" {
  let metrics = @moonsim.Metrics::new()
  metrics.sample("latency", 10)
  metrics.sample("latency", 1)
  metrics.sample("latency", 5)
  metrics.sample("latency", 20)
  let dist = metrics.distribution("latency")
  assert_eq(dist.min, 1)
  assert_eq(dist.max, 20)
  assert_eq(dist.median, 10)
  assert_eq(dist.p90, 10)
  assert_true(
    @moonsim.render_sample_distribution(metrics, "latency").contains(
      "median=10",
    ),
  )
}

///|
test "report renders metric diff and replay comparison" {
  let sim = @moonsim.Sim::new()
  sim.inc_counter("a")
  let baseline = @moonsim.replay_baseline("report", sim)
  let comparison = @moonsim.compare_replay(baseline, sim)
  let diff = sim.metrics().diff_from(@moonsim.Metrics::new().metric_snapshot())
  assert_true(
    @moonsim.render_replay_comparison(comparison).contains("# Replay"),
  )
  assert_true(@moonsim.render_metric_diff(diff).contains("# Metric Diff"))
  assert_true(@moonsim.render_sim_report(sim).contains("validation: PASS sim"))
}

///|
test "network model is deterministic and drains pending messages" {
  let config = @moonsim.network_config(
    seed=707UL,
    messages=8,
    drop_percent=25,
    retry_delay=3,
  )
  let left = @moonsim.run_network_model(config)
  let right = @moonsim.run_network_model(config)
  assert_eq(left.digest, right.digest)
  assert_eq(left.messages, 8)
  assert_eq(left.pending, 0)
  assert_true(left.delivered > 0)
  assert_true(left.dropped >= 0)
  assert_true(@moonsim.network_summary(left).line().contains("network tick="))
}

///|
test "network model records retry and message trace kinds" {
  let result = @moonsim.run_network_model(
    @moonsim.network_config(seed=1UL, messages=5, drop_percent=100),
  )
  assert_eq(result.dropped, 5)
  assert_eq(result.retries, 5)
  assert_true(
    @moonsim.expect_trace_contains_kind(result.trace, "message.drop").passed,
  )
  assert_true(
    @moonsim.expect_trace_contains_kind(result.trace, "message.send").passed,
  )
}

///|
test "load balancer model is deterministic for same strategy" {
  let config = @moonsim.load_balancer_config(
    seed=808UL,
    jobs=12,
    workers=3,
    strategy="least_queue",
  )
  let left = @moonsim.run_load_balancer_model(config)
  let right = @moonsim.run_load_balancer_model(config)
  assert_eq(left.digest, right.digest)
  assert_eq(left.jobs, 12)
  assert_eq(left.workers, 3)
  assert_true(left.events_executed >= 36)
  assert_true(
    @moonsim.load_balancer_summary(left).line().contains("load_balancer"),
  )
}

///|
test "load balancer strategies can produce different digests" {
  let least = @moonsim.run_load_balancer_model(
    @moonsim.load_balancer_config(seed=808UL, strategy="least_queue"),
  )
  let random = @moonsim.run_load_balancer_model(
    @moonsim.load_balancer_config(seed=808UL, strategy="random"),
  )
  assert_true(least.digest != random.digest)
  assert_eq(least.strategy, "least_queue")
  assert_eq(random.strategy, "random")
}

///|
test "load balancer normalizes invalid config values" {
  let config = @moonsim.load_balancer_config(
    jobs=-1,
    workers=0,
    max_arrival_gap=0,
    min_service=0,
    max_service=0,
  )
  assert_eq(config.jobs, 0)
  assert_eq(config.workers, 1)
  assert_eq(config.max_arrival_gap, 1)
  assert_eq(config.min_service, 1)
  assert_eq(config.max_service, 2)
}

///|
test "timeline buckets trace entries deterministically" {
  let entries = [
    @moonsim.trace_entry(0, 1, "schedule", "a"),
    @moonsim.trace_entry(2, 1, "execute", "a"),
    @moonsim.trace_entry(7, 0, "metric.counter", "x"),
    @moonsim.trace_entry(9, 0, "message.send", "m"),
  ]
  let view = @moonsim.build_timeline(entries, bucket_size=5)
  assert_eq(view.bucket_count(), 2)
  assert_eq(view.total_events(), 4)
  assert_eq(view.peak_bucket().events, 2)
  assert_true(view.render().contains("0..4"))
}

///|
test "sim timeline uses trace entries" {
  let sim = @moonsim.Sim::new()
  ignore(sim.schedule_after(1, "a"))
  sim.inc_counter("x")
  ignore(sim.run_until_idle())
  let timeline = sim.timeline(bucket_size=2)
  assert_true(timeline.total_events() >= 3)
}

///|
test "workflow model respects dependencies and workers" {
  let plan = @moonsim.WorkflowPlan::new(worker_count=2)
    .add("fetch", 2)
    .add("parse", 3, deps=[1])
    .add("index", 4, deps=[2])
  assert_eq(plan.validate().passed(), true)
  let result = @moonsim.run_workflow_model(plan)
  assert_eq(result.tasks, 3)
  assert_eq(result.workers, 2)
  assert_eq(result.critical_path, 9)
  assert_true(result.final_tick >= result.critical_path)
  assert_true(result.render().contains("parse"))
}

///|
test "workflow validation catches bad dependency" {
  let plan = @moonsim.WorkflowPlan::new().add("bad", 1, deps=[9])
  let report = plan.validate()
  assert_eq(report.passed(), false)
  assert_true(report.text().contains("bad-workflow-dependency"))
}

///|
test "workflow model is deterministic" {
  let plan = @moonsim.WorkflowPlan::new(worker_count=2)
    .add("a", 2)
    .add("b", 1)
    .add("c", 3, deps=[1, 2])
  let left = @moonsim.run_workflow_model(plan)
  let right = @moonsim.run_workflow_model(plan)
  assert_eq(left.digest, right.digest)
  assert_true(left.summary().line().contains("workflow"))
}

///|
test "reliability model is deterministic" {
  let config = @moonsim.reliability_config(
    seed=44UL,
    operations=8,
    fail_percent=35,
    retry_limit=2,
  )
  let left = @moonsim.run_reliability_model(config)
  let right = @moonsim.run_reliability_model(config)
  assert_eq(left.digest, right.digest)
  assert_eq(left.operations, 8)
  assert_true(left.successes + left.exhausted <= 8)
  assert_true(left.line().contains("success_rate="))
}

///|
test "reliability model handles guaranteed failure" {
  let result = @moonsim.run_reliability_model(
    @moonsim.reliability_config(operations=3, fail_percent=100, retry_limit=1),
  )
  assert_eq(result.successes, 0)
  assert_eq(result.exhausted, 3)
  assert_eq(result.retries, 3)
  assert_true(
    @moonsim.expect_trace_contains_kind(result.trace, "rng.int").passed,
  )
}

///|
test "reliability config normalizes values" {
  let config = @moonsim.reliability_config(
    operations=-1,
    fail_percent=120,
    retry_limit=-2,
    backoff=-3,
  )
  assert_eq(config.operations, 0)
  assert_eq(config.fail_percent, 100)
  assert_eq(config.retry_limit, 0)
  assert_eq(config.backoff, 0)
}

///|
test "circuit breaker model is deterministic" {
  let left = @moonsim.run_circuit_breaker_model(seed=606UL, calls=12)
  let right = @moonsim.run_circuit_breaker_model(seed=606UL, calls=12)
  assert_eq(left.digest, right.digest)
  assert_true(left.allowed + left.rejected >= 12)
  assert_true(left.summary().line().contains("circuit_breaker"))
}

///|
test "circuit breaker rejects while open" {
  let sim = @moonsim.Sim::new()
  let breaker = @moonsim.CircuitBreaker::new(
    "svc",
    config=@moonsim.circuit_breaker_config(
      failure_threshold=1,
      reset_timeout=10,
    ),
  )
  assert_eq(breaker.allow(sim), true)
  breaker.record_failure(sim)
  assert_eq(breaker.state(), "open")
  assert_eq(breaker.allow(sim), false)
  assert_eq(sim.metrics().counter("circuit_rejected"), 1)
}

///|
test "token bucket model is deterministic" {
  let left = @moonsim.run_token_bucket_model(seed=7070UL, requests=14)
  let right = @moonsim.run_token_bucket_model(seed=7070UL, requests=14)
  assert_eq(left.digest, right.digest)
  assert_true(left.allowed > 0)
  assert_true(left.summary().line().contains("token_bucket"))
}

///|
test "token bucket refills and rejects deterministically" {
  let sim = @moonsim.Sim::new()
  let bucket = @moonsim.TokenBucket::new(
    "api",
    capacity=2,
    refill=1,
    interval=2,
  )
  assert_eq(bucket.allow(sim), true)
  assert_eq(bucket.allow(sim), true)
  assert_eq(bucket.allow(sim), false)
  ignore(sim.schedule_at(2, "tick"))
  ignore(sim.run_until_tick(2))
  assert_eq(bucket.allow(sim), true)
  assert_eq(sim.metrics().counter("bucket_allowed"), 3)
  assert_eq(sim.metrics().counter("bucket_rejected"), 1)
}

///|
test "sweep report compares scores and digest is stable" {
  let report = @moonsim.sweep_load_balancer_strategies(seed=808UL, jobs=12)
  assert_eq(report.count(), 3)
  assert_true(report.best_by_score() is Some(_))
  assert_eq(
    report.combined_digest(),
    @moonsim.sweep_load_balancer_strategies(seed=808UL, jobs=12).combined_digest(),
  )
  assert_true(report.render().contains("best_score="))
}

///|
test "reliability sweep contains three failure rates" {
  let report = @moonsim.sweep_reliability_failure_rates(seed=9090UL)
  assert_eq(report.count(), 3)
  assert_true(report.best_by_final_tick() is Some(_))
  assert_true(report.render().contains("fail_70"))
}

///|
test "invariant report aggregates checks" {
  let sim = @moonsim.Sim::new()
  sim.inc_counter("jobs", delta=2)
  let report = @moonsim.check_sim_invariants(sim)
    .add(@moonsim.check_counter_at_least(sim, "jobs", 1))
    .add(@moonsim.check_no_pending(sim))
  assert_eq(report.passed(), true)
  assert_eq(report.failed_count(), 0)
  assert_true(report.render().contains("counter_at_least:jobs"))
}

///|
test "invariant report records failures" {
  let sim = @moonsim.Sim::new()
  let report = @moonsim.InvariantReport::new("custom").add(
    @moonsim.check_counter_at_least(sim, "missing", 1),
  )
  assert_eq(report.passed(), false)
  assert_eq(report.failed_count(), 1)
  assert_eq(report.passed_count(), 0)
  assert_eq(report.check_count(), 1)
  assert_eq(report.is_empty(), false)
  assert_eq(report.has_check("counter_at_least:missing"), true)
  assert_eq(report.only_failures().failed_count(), 1)
  assert_true(report.summary().contains("FAIL invariants"))
}

///|
test "invariant reports can merge" {
  let left = @moonsim.InvariantReport::new("left").add(
    @moonsim.invariant_check("a", true),
  )
  let right = @moonsim.InvariantReport::new("right").add(
    @moonsim.invariant_check("b", false),
  )
  let merged = left.merge(right)
  assert_eq(merged.checks.length(), 2)
  assert_eq(merged.failed_count(), 1)
  assert_true(merged.summary().contains("left+right"))
}

///|
test "seed matrix aggregates retry runs" {
  let matrix = @moonsim.retry_seed_matrix([1UL, 2UL, 3UL])
  assert_eq(matrix.count(), 3)
  assert_eq(matrix.is_empty(), false)
  assert_eq(matrix.has_seed(2UL), true)
  assert_eq(matrix.has_seed(9UL), false)
  assert_true(matrix.total_events() > 0)
  assert_true(matrix.unique_digests() > 0)
  assert_true(matrix.tick_span() >= 0)
  assert_eq(matrix.lines().length(), 3)
  assert_true(matrix.render().contains("Seed Matrix retry"))
  assert_true(matrix.summary_line().contains("unique_digests="))
  assert_eq(
    matrix.combined_digest(),
    @moonsim.retry_seed_matrix([1UL, 2UL, 3UL]).combined_digest(),
  )
}

///|
test "seed matrix supports network and load balancer families" {
  let seeds = [1UL, 2UL]
  let network = @moonsim.network_seed_matrix(seeds)
  let lb = @moonsim.load_balancer_seed_matrix(seeds, strategy="random")
  assert_eq(network.count(), 2)
  assert_eq(lb.count(), 2)
  assert_true(network.slowest() is Some(_))
  assert_true(network.fastest() is Some(_))
  assert_true(lb.render().contains("load_balancer:random"))
}

///|
test "seed matrix comparison detects stable and changed matrices" {
  let left = @moonsim.retry_seed_matrix([1UL, 2UL])
  let same = @moonsim.retry_seed_matrix([1UL, 2UL])
  let changed = @moonsim.retry_seed_matrix([1UL, 3UL])
  assert_eq(@moonsim.compare_seed_matrices(left, same).matched(), true)
  assert_eq(@moonsim.compare_seed_matrices(left, same).is_stable(), true)
  let comparison = @moonsim.compare_seed_matrices(left, changed)
  assert_eq(comparison.matched(), false)
  assert_eq(comparison.digest_changed(), true)
  assert_eq(comparison.count_changed(), false)
  assert_eq(comparison.fully_changed(), false)
  assert_true(comparison.summary().contains("mismatch"))
}
