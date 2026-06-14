# moonsim

Deterministic simulation, trace, and replay framework for MoonBit.

`moonsim` provides a reusable virtual-time simulation kernel for tests,
model experiments, game logic, retry policies, queueing systems, protocol
sketches, and other workflows where reproducibility matters.

## Use Cases

- Test retry, timeout, and backoff logic without waiting for wall-clock time.
- Model queues, schedulers, state machines, and small protocols.
- Replay game-loop or model decisions from the same seed.
- Compare two strategies from the same checkpoint.
- Produce stable traces, digests, and metrics for regression tests.

## Core Features

- Virtual simulation time based on deterministic ticks.
- Stable event scheduling with delay, cancellation, and run limits.
- Seeded random number generation for reproducible runs.
- Trace recording, trace formatting, and deterministic digests.
- Trace querying, replay baselines, and structured comparison reports.
- Metrics for counters, gauges, samples, summaries, distributions, and diffs.
- Scenario and scenario-suite helpers for readable model tests.
- Snapshot, restore, and fork comparison helpers.
- Reusable model helpers for timers, backoff, state machines, messages,
  network delivery, load balancing, circuit breakers, and token buckets.
- Workflow scheduling, parameter sweeps, and invariant checks for model suites.
- Multi-seed regression matrices for exploring deterministic variability.

## Quick Start

```bash
moon check
moon test
moon run cmd/main
```

The CLI demo prints a deterministic retry-style simulation trace and digest.

## API Preview

```moonbit
let sim = @moonsim.Sim::new(seed=2026UL)
ignore(sim.schedule_after(5, "request_arrives"))
ignore(sim.schedule_after(13, "retry_succeeds"))
ignore(sim.run_until_idle())

println(sim.metrics().counter("events_executed"))
println(sim.digest())
```

## Examples

```bash
moon run examples/queue
moon run examples/retry
moon run examples/traffic
moon run examples/game_loop
moon run examples/protocol
moon run examples/order_state
moon run examples/network
moon run examples/load_balancer
moon run examples/resilience
moon run examples/workflow
moon run examples/sweep
moon run examples/seed_matrix
```

The examples cover queueing, retry/backoff, traffic lights, fixed-tick game
loops, message delivery, state-machine transitions, network retry behavior,
worker scheduling strategies, and resilience policies.

## Documentation

- `DESIGN.md`: design goals, non-goals, and module boundaries.
- `docs/api.md`: public API notes.
- `docs/examples.md`: runnable example notes.
- `docs/roadmap.md`: project roadmap.

## Current Status

- 170+ tests.
- No runtime dependency beyond MoonBit core.
- Deterministic scheduler, RNG, trace/replay, metrics, scenarios, snapshots,
  model helpers, validation, reports, and examples.
