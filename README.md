# moonsim

Deterministic simulation and model testing toolkit for MoonBit.

`moonsim` provides a reusable virtual-time toolkit for deterministic model
tests. It helps MoonBit projects describe system behavior with scenarios,
metrics, snapshots, traces, and reusable model helpers without depending on
wall-clock timing or a specific concurrency runtime.

## Use Cases

- Test retry, timeout, and backoff logic without waiting for wall-clock time.
- Model queues, schedulers, state machines, and small protocols.
- Replay game-loop or model decisions from the same seed.
- Compare two strategies from the same checkpoint.
- Produce stable traces, digests, and metrics for regression tests.

## Focus

`moonsim` is not an Actor framework or a backend concurrency runtime. Message
delivery is one optional model helper; the main API is built around `Sim`,
scenarios, metrics, snapshots, trace/replay, and reusable system models.

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

## Submission Verification

The OSC 2026 MoonBit project submission is verified with these commands:

```bash
moon fmt --check
moon check --deny-warn
moon info
git diff --exit-code
moon test --deny-warn
moon run cmd/main
```

The repository includes `.github/workflows/moonbit.yml` with the same required
steps on Linux, macOS, and Windows. `moon info` writes the checked-in
`pkg.generated.mbti` files, and `git diff --exit-code` verifies that the
generated public interfaces are up to date.

The local stable toolchain observed during this repair was:

```text
moon 0.1.20260703 (6fbf8c3 2026-07-03)
moonc v0.10.3+16975d007 (2026-07-03)
moonrun 0.1.20260703 (6fbf8c3 2026-07-03)
```

In this toolchain, `--deny-warn` is supported by `moon check` and `moon test`.
Formatting is checked with `moon fmt --check`, and generated package interfaces
are checked with `moon info` followed by `git diff --exit-code`.

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

- 190+ tests.
- No runtime dependency beyond MoonBit core.
- Deterministic scheduler, RNG, trace/replay, metrics, scenario suites,
  snapshots, model helpers, validation, reports, and examples.
