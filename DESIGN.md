# moonsim Design

`moonsim` is a deterministic simulation and model testing toolkit for MoonBit.
It focuses on reusable infrastructure for scenario-based tests, metrics,
snapshots, trace/replay, and model experiments rather than a domain-specific
simulator or a concurrency runtime.

## Problem

Many systems are difficult to test when time, random choices, and event order
depend on the host environment. Examples include game loops, retry policies,
queueing systems, schedulers, state machines, and small protocol models.

`moonsim` makes those systems reproducible by replacing wall-clock time with
virtual ticks, replacing ambient randomness with seeded RNG, and recording a
trace of what happened.

## Current Scope

The current implementation provides:

- virtual simulation time as integer ticks
- deterministic event scheduling
- stable ordering for same-tick events
- cancellation, idle running, and run limits
- seeded RNG and simple distributions
- trace entries and deterministic trace digests
- trace queries, replay baselines, and structured comparisons
- counters, gauges, samples, summaries, distributions, and diffs
- scenario assertions, suites, and reports
- snapshots, restore, and fork comparison
- timer, backoff, state-machine, message, network, load-balancer, and
  resilience helpers
- workflow, sweep, seed-matrix, timeline, and invariant helpers
- CLI and example packages

## Non-Goals

- It is not a real-time async runtime.
- It is not a physics engine.
- It is not a game engine.
- It is not a logging or OpenTelemetry replacement.
- It is not a benchmark harness.
- It is not an Actor framework or mailbox runtime.

## Differentiation

MoonBit projects may already contain domain-specific simulations or concurrency
experiments. `moonsim` keeps a different boundary: the core API is `Sim`,
scenario assertions, metrics, snapshots, trace/replay, and reusable model
helpers. Message delivery is an optional helper, not the center of the design.

The project deliberately keeps the core free of wall-clock and operating-system
dependencies. This makes the behavior easier to verify and easier to reuse
across MoonBit targets.

## Public API

The core API is intentionally small:

- `Sim` owns virtual time, pending events, RNG, trace, and metrics.
- `ScheduledEvent` is the deterministic event record.
- `Rng` provides reproducible random draws.
- `TraceEntry` records simulation actions.
- `Metrics` tracks simulation counters and summaries.

Detailed API notes live in `docs/api.md`.

## Examples

The repository includes:

- a retry-style CLI demo in `cmd/main`
- a queue simulation in `examples/queue`
- a retry/backoff simulation in `examples/retry`
- a traffic light simulation in `examples/traffic`
- a game-loop fork comparison in `examples/game_loop`
- a message protocol simulation in `examples/protocol`
- an order state-machine simulation in `examples/order_state`
- a network delivery and retry simulation in `examples/network`
- a load-balancer scheduling simulation in `examples/load_balancer`
- a resilience simulation in `examples/resilience`
- a workflow simulation in `examples/workflow`
- a sweep simulation in `examples/sweep`
- a seed matrix simulation in `examples/seed_matrix`

Detailed example notes live in `docs/examples.md`.
