# Project Proposal: moonsim

Working title: `moonsim`

Subtitle: deterministic simulation, trace, and replay framework for MoonBit.

## One-Sentence Pitch

`moonsim` is a reusable MoonBit framework for building deterministic simulations with virtual time, seeded randomness, event scheduling, trace recording, and replay verification.

## Why This Topic

The first ecosystem research pass found high overlap in several obvious competition directions:

- Markdown parsers already exist.
- Template engines already exist and at least one is published on mooncakes.io.
- Graph and pathfinding libraries already exist.
- Logging/tracing libraries already exist.
- Collection utilities already exist.

Deterministic simulation, however, appears to have low direct overlap. Search results show domain-specific simulations inside games or industrial projects, but not a general reusable simulation kernel.

This makes `moonsim` a good competition candidate: it is useful, not just a toy; it can reach the expected 4k-10k LOC scale; and it has clear differentiation through replay, traces, deterministic randomness, and scenario testing.

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

## Proposed Package Layout

```text
moonsim/
  moon.mod.json
  README.md
  DESIGN.md
  docs/
    ecosystem-research.md
    project-proposal-moonsim.md
    api.md
    examples.md
  src/
    core/
    rng/
    scheduler/
    trace/
    scenario/
    snapshot/
    metrics/
    cmd/main/
    examples/queue/
    examples/traffic/
    examples/retry/
    examples/game_loop/
  tests/
```

The exact layout should be adjusted after creating the MoonBit skeleton and checking current `moon` package conventions.

## Core Concepts

### Virtual Time

The framework should use deterministic ticks rather than wall-clock time.

Example concepts:

- `Tick`: integer simulation time
- `Duration`: tick delta
- `EventId`: stable monotonically increasing id
- `SimClock`: current time and helpers

### Scheduler

The scheduler owns pending events and executes them in deterministic order.

Ordering rule:

1. earlier tick first
2. lower priority first or higher priority first, whichever the API defines
3. lower event id as stable tie-breaker

Capabilities:

- schedule now
- schedule after delay
- schedule at tick
- cancel event
- repeat event
- run next event
- run until tick
- run until idle
- run for maximum steps

### Deterministic RNG

Seeded RNG should make all random choices replayable.

Initial scope:

- seed from `UInt64`
- `next_u64`
- `next_int(bound)`
- `next_bool`
- `choose` from array
- simple weighted choice if practical

### Trace And Replay

Trace should capture enough information to debug and verify a run.

Trace entries may include:

- event scheduled
- event cancelled
- event executed
- RNG draw
- metric emitted
- user note
- scenario assertion

Replay can compare:

- event order
- deterministic digest
- final metrics
- explicit trace expectations

### Scenario Testing

Scenario helpers should make tests readable.

Possible API shape:

```moonbit
let sim = @moonsim.Sim::new(seed=42UL)
sim.schedule_after(5, "wake", fn(ctx) {
  ctx.metric_counter("wakeups").inc(1)
})
sim.run_until_idle()
assert_eq(sim.metrics().counter("wakeups"), 1)
```

This is illustrative only. Final API should follow actual MoonBit syntax and package conventions.

### Metrics

Metrics should be simulation outputs, not wall-clock performance metrics.

Initial metrics:

- counter
- gauge
- histogram or sample list
- named metric snapshot

### Snapshot

Snapshot support can start simple.

Possible MVP:

- snapshot clock, pending event metadata, RNG state, and metrics
- restore framework-owned state
- user state restoration via explicit callback or trait, if feasible

This should not become a complex serialization framework in v0.1.

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
- state transitions
- metrics over virtual time

### Game Loop Simulation

Model a simple turn-based or tick-based game loop.

Shows:

- fixed tick stepping
- deterministic random choices
- replayable trace

## Milestones

### Milestone 0: Setup

- Create MoonBit project skeleton.
- Add license, README, design docs, and CI notes.
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
- Add traffic light or game loop example.
- Add CLI runner for examples and trace output.

### Milestone 5: Competition Polish

- Expand README.
- Write `DESIGN.md`.
- Write `docs/api.md` and `docs/examples.md`.
- Add final ecosystem comparison and independent contribution section.
- Run `moon fmt`, `moon check`, and `moon test`.

## Expected Evaluation Highlights

- Low direct overlap with known MoonBit ecosystem projects.
- Clear reusable value across games, protocols, schedulers, and algorithm experiments.
- Determinism is easy to demonstrate through trace replay.
- Strong tests can be written without external services.
- Scope fits the 4k-10k effective MoonBit LOC target.

## Main Risks

### Risk: API Design Too Abstract

Mitigation: build examples early and let them shape the API.

### Risk: Snapshot Scope Grows Too Large

Mitigation: keep v0.1 snapshot support limited to framework-owned state and explicit user hooks.

### Risk: CLI Distracts From Library Quality

Mitigation: implement CLI only after the library API and tests are stable.

### Risk: MoonBit Runtime APIs Differ Across Targets

Mitigation: avoid wall-clock and OS dependencies in the core. Keep target-specific code out of the deterministic kernel.

## Decision

Recommended as the primary competition direction unless a second ecosystem audit finds a mature generic deterministic simulation framework before implementation starts.
