# moonsim Background Notes

Working title: `moonsim`

Subtitle: deterministic simulation, trace, and replay framework for MoonBit.

## One-Sentence Pitch

`moonsim` is a reusable MoonBit framework for building deterministic
simulations with virtual time, seeded randomness, event scheduling, trace
recording, and replay verification.

## Why This Topic

The initial ecosystem research found high overlap in several obvious library
directions:

- Markdown parsers already exist.
- Template engines already exist and at least one is published on mooncakes.io.
- Graph and pathfinding libraries already exist.
- Logging/tracing libraries already exist.
- Collection utilities already exist.

Deterministic simulation, however, appears to have low direct overlap. Search
results show domain-specific simulations inside games or industrial projects,
but not a general reusable simulation kernel.

This makes `moonsim` a useful MoonBit ecosystem project: it is reusable, can
grow naturally from examples and tests, and has clear differentiation through
replay, traces, deterministic randomness, and scenario testing.

## Target Users

- MoonBit developers building games or game logic tests
- Developers testing schedulers, retry logic, queues, protocols, or distributed workflows
- Algorithm authors who need reproducible experiments
- Educators demonstrating simulations without wall-clock nondeterminism
- Library authors who want deterministic model tests

## Goals

1. Provide a deterministic virtual-time event scheduler.
2. Provide seeded RNG so simulations are reproducible.
3. Record traces of scheduled and executed events.
4. Replay traces and verify deterministic behavior.
5. Provide scenario helpers for tests and examples.
6. Provide a small CLI runner for demos and trace comparison.
7. Include practical examples that prove reuse value.

## Non-Goals

1. Not a real-time async runtime.
2. Not a physics engine.
3. Not a game engine.
4. Not a distributed systems framework.
5. Not a replacement for logging/tracing libraries such as `moontrace` or OpenTelemetry.
6. Not a benchmark harness, although examples may emit timing-independent metrics.

## Core Concepts

### Virtual Time

The framework uses deterministic ticks rather than wall-clock time.

Key concepts:

- `Tick`: integer simulation time
- `Duration`: tick delta
- `EventId`: stable monotonically increasing id
- `SimClock`: current time and helpers

### Scheduler

The scheduler owns pending events and executes them in deterministic order.

Ordering rule:

1. earlier tick first
2. lower priority first
3. lower event id as stable tie-breaker

Capabilities:

- schedule now
- schedule after delay
- schedule at tick
- cancel event
- run next event
- run until tick
- run until idle
- run for maximum steps

### Deterministic RNG

Seeded RNG makes random choices replayable.

Initial scope:

- seed from `UInt64`
- `next_u64`
- `next_int(bound)`
- `next_bool`
- range and distribution helpers

### Trace And Replay

Trace captures enough information to debug and verify a run.

Trace entries include:

- event scheduled
- event cancelled
- event executed
- RNG draw
- metric emitted
- user note
- scenario assertion

Replay and comparison can use event order, deterministic digest, final metrics,
and explicit trace expectations.

### Scenario Testing

Scenario helpers make tests readable by bundling setup, assertions, and failure
reports around a deterministic simulation.

### Metrics

Metrics are simulation outputs, not wall-clock performance metrics.

Implemented metric types include:

- counter
- gauge
- sample list
- histogram summary
- named metric snapshot

### Snapshot

Snapshot support focuses on framework-owned state:

- current clock
- pending event metadata
- RNG state
- metrics
- trace state used for fork comparison

## Example Scenarios

### Queue Simulation

Model customers arriving at a service queue.

Shows:

- random arrivals
- scheduled service completion
- counters and wait-time samples
- deterministic replay by seed

### Retry / Backoff Simulation

Model request retry with deterministic failures.

Shows:

- delayed scheduling
- cancellation
- seeded failure pattern
- trace debugging

### Traffic Light Simulation

Model cyclic traffic lights and vehicle movement.

Shows:

- repeating events
- state-like phase changes
- metrics over virtual time

### Game Loop Simulation

Model a simple fixed-tick game loop.

Shows:

- fixed tick stepping
- deterministic random choices
- replayable trace
- snapshot-based strategy comparison

## Milestones

### Milestone 0: Setup

- Create MoonBit project skeleton.
- Add license, README, design docs, and build notes.
- Confirm build/test commands.

### Milestone 1: Deterministic Kernel

- Implement `Tick`, `Duration`, `EventId`.
- Implement seeded RNG.
- Implement event queue and scheduler.
- Add unit tests for ordering, delay, cancellation, and reproducibility.

### Milestone 2: Trace And Metrics

- Add trace entries.
- Add deterministic digest.
- Add counters/gauges/sample metrics.
- Add tests for trace stability and metrics.

### Milestone 3: Scenario Helpers

- Add scenario runner helpers.
- Add assertions and failure reporting.
- Add example tests using the scenario API.

### Milestone 4: Examples And CLI

- Add queue simulation.
- Add retry/backoff simulation.
- Add traffic light and game loop examples.
- Add CLI runner for examples and trace output.

### Milestone 5: Documentation And Polish

- Keep README concise.
- Maintain `docs/design.md`.
- Maintain `docs/api.md` and `docs/examples.md`.
- Keep examples and tests passing.

## Main Risks

### Risk: API Design Too Abstract

Mitigation: build examples early and let them shape the API.

### Risk: Snapshot Scope Grows Too Large

Mitigation: keep snapshot support focused on framework-owned state and explicit
user-level model data.

### Risk: CLI Distracts From Library Quality

Mitigation: keep CLI as a thin demonstration layer over the library API.

### Risk: MoonBit Runtime APIs Differ Across Targets

Mitigation: avoid wall-clock and OS dependencies in the core. Keep
target-specific code out of the deterministic kernel.
