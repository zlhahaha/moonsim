# moonsim

Deterministic simulation and model testing toolkit for MoonBit.

`moonsim` provides a reusable virtual-time toolkit for deterministic model
tests. It helps MoonBit projects describe system behavior with scenarios,
metrics, snapshots, traces, and reusable model helpers without depending on
wall-clock timing or a specific concurrency runtime.

## Why This Exists

A retry/timeout bug can look healthy if the only metric is eventual success:

```text
request starts
-> first attempt times out
-> retry is scheduled
-> the original request succeeds late
-> the retry also produces a result
```

`moonsim` keeps these observations separate: eventual completion,
caller-visible timeout, and late success after a timeout. With virtual time, a
fixed seed, trace digest, invariants, and replay, the same failure can be
inspected and rerun as a regression test.

### Relationship To Existing Tools

`moonsim` builds on established ideas rather than claiming to replace them:

- [SimPy](https://simpy.readthedocs.io/en/latest/index.html) primarily provides discrete-event simulation.
- [Go fuzzing](https://go.dev/doc/security/fuzz/) explores inputs and retains failing inputs for regression.
- Rust property-testing and randomized-testing tools provide related input and invariant exploration.
- [FoundationDB's deterministic simulation testing](https://apple.github.io/foundationdb/testing.html) demonstrates the engineering value of reproducible simulation in complex systems.

`moonsim` combines the relevant pieces into a MoonBit workflow for reliability
models: virtual time, seeded randomness, trace/digest, invariants, and replay.
It is not an actor runtime, a real-network test framework, or a general
performance benchmark.

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
- Service reliability model suite for queues, retries, rate limits, circuit
  breakers, SLO invariants, seed matrices, and replayable digests.
- Workflow scheduling, parameter sweeps, and invariant checks for model suites.
- Multi-seed regression matrices for exploring deterministic variability.

## Quick Start

Install in another MoonBit project:

```bash
moon add zlhahaha/moonsim
```

The package is published under the `zlhahaha` MoonBit namespace. For local
development, the repository itself can be checked and run with the commands
below.

Run this repository:

```bash
moon check
moon test
moon run cmd/main
```

The CLI demo starts from a retry/timeout reliability problem, runs a deterministic
service model, replays the same seed, checks invariants, and prints the digest
you can use to compare future runs.

The `Fault reproduction` section intentionally prints
`invariant=fail (expected demonstration)`. This is a model finding, so the
showcase still exits successfully. A changed replay digest, a failed assertion
in `moon test`, a failed `moon check`, or a generated-interface diff is a real
verification failure.

Minimal usage after `moon add zlhahaha/moonsim`:

```moonbit
let result = @moonsim.run_service_resilience_suite(
  config=@moonsim.service_resilience_config(seed=2026UL, requests=32),
)

println(@moonsim.render_service_resilience_report(result))
assert_true(result.invariants.passed())
```

For a step-by-step workflow that starts from a retry/timeout bug and ends with a
replayable fixed run, read `docs/tutorial.md`.

## Package Layout

The root package remains the stable facade for application code and examples:

- `zlhahaha/moonsim`: common facade for simulation, models, reports, and
  quick-start examples.
- `zlhahaha/moonsim/core`: focused entry points for virtual time, scheduling,
  deterministic RNG, traces, replay, invariants, and validation.
- `zlhahaha/moonsim/models`: reusable queue, retry, network, load-balancing,
  workflow, and service reliability models.
- `zlhahaha/moonsim/reports`: text reports, feature matrices, demo catalogs,
  and trace/metrics summaries.

Most users can start with the root package and move to the focused packages
when they want clearer module boundaries.

## Verification

The repository is kept checkable with these commands:

```bash
moon fmt --check
moon check --deny-warn
moon info
git diff --exit-code
moon test --deny-warn
moon run cmd/main
```

The repository includes `.github/workflows/moonbit.yml` with the same core
steps on Linux, macOS, and Windows. `moon info` writes the checked-in
`pkg.generated.mbti` files, and `git diff --exit-code` verifies that the
generated public interfaces are up to date.

One validated local toolchain was:

```text
moon 0.1.20260703 (6fbf8c3 2026-07-03)
moonc v0.10.3+16975d007 (2026-07-03)
moonrun 0.1.20260703 (6fbf8c3 2026-07-03)
```

In this toolchain, `--deny-warn` is supported by `moon check` and `moon test`.
Formatting is checked with `moon fmt --check`, and generated package interfaces
are checked with `moon info` followed by `git diff --exit-code`.

## Test Scale And Boundaries

Use the smallest scale that answers the question:

- Small event traces: fast unit tests for scheduling and invariants.
- Medium scenarios: normal queue, retry, timeout, and state-machine model tests.
- Multiple seeds: deterministic exploration of different event orderings.
- Large event traces: pressure smoke tests for scheduler and trace handling.

The project documents observed runs rather than claiming to be the fastest.
Model tests complement, but do not replace, integration tests against real
networks or databases, deployment tests, and production monitoring. A passing
model means the modeled rules hold for the tested seeds and configuration; it
does not prove that a production system is completely correct.

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
moon run examples/service_resilience
moon run examples/workflow
moon run examples/sweep
moon run examples/seed_matrix
```

The examples cover queueing, retry/backoff, traffic lights, fixed-tick game
loops, message delivery, state-machine transitions, network retry behavior,
worker scheduling strategies, resilience policies, and an end-to-end service
reliability suite.

## Documentation

- `docs/design.md`: design goals, non-goals, and module boundaries.
- `docs/api.md`: public API and package layout notes.
- `docs/examples.md`: runnable examples and smoke-test notes.
- `docs/tutorial.md`: retry/timeout debugging with deterministic replay and
  invariants.
- `docs/testing.md`: local verification, CI checks, and release gates.
- `docs/roadmap.md`: project roadmap.

## Current Status

- 190+ tests plus CLI and example smoke checks.
- No runtime dependency beyond MoonBit core.
- Deterministic scheduler, RNG, trace/replay, metrics, scenario suites,
  snapshots, model helpers, validation, reports, and examples.
- Structured root, core, models, and reports package entry points.
