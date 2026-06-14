# moonsim Design

`moonsim` is a deterministic simulation, trace, and replay framework for
MoonBit. It focuses on reusable infrastructure for model tests and experiments
rather than a domain-specific simulator.

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
- counters, gauges, samples, and summaries
- scenario assertions and reports
- snapshots, restore, and fork comparison
- timer, backoff, state-machine, and message helpers
- CLI and example packages

## Non-Goals

- It is not a real-time async runtime.
- It is not a physics engine.
- It is not a game engine.
- It is not a logging or OpenTelemetry replacement.
- It is not a benchmark harness.

## Differentiation

MoonBit projects may already contain domain-specific simulation code, but
`moonsim` provides a reusable kernel that other projects can build on. Its
independent contribution is a small deterministic runtime for reproducible
model tests, traces, metrics, and examples.

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

Detailed example notes live in `docs/examples.md`.
