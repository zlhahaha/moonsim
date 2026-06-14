# moonsim API

This document describes the current public API shape.

## Simulation

```moonbit
let sim = @moonsim.Sim::new(seed=2026UL)
```

Key methods:

- `time() -> Int`: current virtual tick.
- `schedule_at(tick, name, priority?) -> Int`: schedule an event at a virtual tick.
- `schedule_after(delay, name, priority?) -> Int`: schedule relative to current tick.
- `cancel(event_id) -> Bool`: cancel a pending event.
- `pending_count() -> Int`: count non-cancelled pending events.
- `run_next() -> ScheduledEvent?`: execute the next deterministic event.
- `run_until_idle(max_steps?) -> Int`: execute until no events remain or the step limit is reached.
- `next_int(bound) -> Int`: draw from the deterministic RNG and record the draw.
- `trace() -> Array[TraceEntry]`: copy the trace log.
- `digest() -> UInt64`: compute a deterministic digest from the trace.
- `metrics() -> Metrics`: access counters.
- `inc_counter(name, delta?)`: increment a simulation counter and trace it.

## Event Ordering

Events are ordered by:

1. lower tick
2. lower priority
3. lower event id

The event id tie-breaker makes same-tick behavior stable.

## Trace

Trace entries record deterministic actions:

- `schedule`
- `cancel`
- `execute`
- `rng.int`
- `metric.counter`

Use `TraceEntry::format()` for human-readable output and `trace_digest()` or
`Sim::digest()` for regression checks.

Trace utilities also support:

- `query_trace(...)`: filter by kind, detail text, and tick range.
- `TraceQueryResult::kind_count(...)`: count trace entries by kind.
- `expect_trace_*`: assert trace count, detail, order, monotonic ticks, and digest.
- `replay_baseline(...)` and `compare_replay(...)`: compare a later run against
  an in-memory baseline of trace, counters, and gauges.

## Metrics

Metrics support counters, gauges, samples, summaries, distributions, snapshots,
and diffs:

```moonbit
sim.inc_counter("requests")
sim.inc_counter("bytes", delta=128)
let requests = sim.metrics().counter("requests")
let before = sim.metrics().metric_snapshot()
sim.sample("latency", 7)
let diff = sim.metrics().diff_from(before)
```

The scheduler automatically increments `events_executed`.

## Higher-Level APIs

The library also includes:

- `Scenario`: scenario assertions and readable failure reports.
- `ScenarioSuite`: multi-scenario aggregation and suite reports.
- `SimSnapshot`: checkpoint, restore, and fork comparison.
- `Backoff` and `TimerPlan`: deterministic retry and interval helpers.
- `StateMachine`: transition modeling and trace integration.
- `MessageBus`: delayed message delivery and drop modeling.
- `ValidationReport`: invariant checks for simulations, traces, and metrics.
- `ExperimentReport`: model-suite reporting for demos and comparisons.
- `run_network_model`: deterministic network delivery, drop, and retry model.
- `run_load_balancer_model`: multi-worker scheduling strategy model.
- `run_circuit_breaker_model`: service protection model.
- `run_token_bucket_model`: deterministic rate limiting model.
- `WorkflowPlan` and `run_workflow_model`: dependency-aware task scheduling.
- `SweepReport`: compare deterministic model variants.
- `InvariantReport`: aggregate reusable simulation invariants.
- `SeedMatrix`: run deterministic model families across multiple seeds.
