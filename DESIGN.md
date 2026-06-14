# moonsim Design

`moonsim` is a deterministic simulation, trace, and replay framework for
MoonBit. It targets the competition's "Deterministic simulation framework"
direction and focuses on reusable infrastructure rather than a domain-specific
demo.

## Problem

Many systems are difficult to test when time, random choices, and event order
depend on the host environment. Examples include game loops, retry policies,
queueing systems, schedulers, and small protocol models.

`moonsim` makes those systems reproducible by replacing wall-clock time with
virtual ticks, replacing ambient randomness with seeded RNG, and recording a
trace of what happened.

## Current Scope

The first implementation milestone provides:

- virtual simulation time as integer ticks
- deterministic event scheduling
- stable ordering for same-tick events
- cancellation and idle running
- seeded RNG
- trace entries
- deterministic trace digest
- simple counters
- CLI and example packages

## Non-Goals

- It is not a real-time async runtime.
- It is not a physics engine.
- It is not a game engine.
- It is not a logging or OpenTelemetry replacement.
- It is not a benchmark harness.

## Differentiation

The initial ecosystem research did not find a mature generic MoonBit
deterministic simulation framework. Existing projects contain domain-specific
simulation code, while `moonsim` provides a reusable kernel that other MoonBit
projects can build on.

The project deliberately avoids direct overlap with mature MoonBit Markdown,
template, graph/pathfinding, collections, and tracing libraries found during
ecosystem research. Its independent contribution is a small deterministic
runtime kernel for reproducible model tests and examples.

## Public API

The core API is intentionally small:

- `Sim` owns virtual time, pending events, RNG, trace, and metrics.
- `ScheduledEvent` is the deterministic event record.
- `Rng` provides reproducible random draws.
- `TraceEntry` records simulation actions.
- `Metrics` tracks simulation counters.

Detailed API notes live in `docs/api.md`.

## Examples

The repository includes:

- a retry-style CLI demo in `cmd/main`
- a queue simulation in `examples/queue`
- a retry/backoff simulation in `examples/retry`

Detailed example notes live in `docs/examples.md`.
