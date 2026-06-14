# moonsim Examples

## CLI Demo

```bash
moon run cmd/main
```

Runs a small retry-style simulation and prints metrics, trace entries, and a
deterministic digest.

## Queue Simulation

```bash
moon run examples/queue
```

Models five customers arriving at a single-server queue. Arrival gaps are drawn
from the seeded RNG, service time is fixed, and the resulting final tick and
digest are reproducible.

Demonstrates:

- seeded arrivals
- scheduled arrival and finish events
- counters
- deterministic digest

## Retry / Backoff Simulation

```bash
moon run examples/retry
```

Models a request that fails twice, backs off with deterministic jitter, and then
succeeds.

Demonstrates:

- retry attempts
- delayed scheduling
- seeded jitter
- counters for attempts, retries, and success
- deterministic digest

## Traffic Light Simulation

```bash
moon run examples/traffic
```

Models a cyclic traffic light and deterministic vehicle arrivals.

Demonstrates:

- repeating timer events
- state-like phase changes
- counters and sample summaries
- deterministic digest

## Game Loop Simulation

```bash
moon run examples/game_loop
```

Demonstrates fixed ticks, seeded damage rolls, checkpointing, and forked
strategy comparison.

## Message Protocol Simulation

```bash
moon run examples/protocol
```

Demonstrates node-to-node messages, delivery delay, drops, retries, timers, and
message metrics.

## Order State Simulation

```bash
moon run examples/order_state
```

Demonstrates state transitions, rejected events, transition trace records, and
state-machine metrics.

## Network Simulation

```bash
moon run examples/network
```

Demonstrates deterministic message latency, drops, retries, delivery metrics,
and trace/digest reporting.

## Load Balancer Simulation

```bash
moon run examples/load_balancer
```

Compares deterministic worker scheduling strategies such as least-queue and
random assignment. Demonstrates seeded job arrivals, service-time samples,
worker counters, total wait, final tick, and stable digests.

## Resilience Simulation

```bash
moon run examples/resilience
```

Demonstrates circuit breaker behavior and token bucket rate limiting under
deterministic request streams.

## Workflow Simulation

```bash
moon run examples/workflow
```

Demonstrates dependency-aware task scheduling, worker assignment, critical path
calculation, and deterministic workflow digests.

## Sweep Simulation

```bash
moon run examples/sweep
```

Demonstrates parameter sweeps across model variants and stable digest reports
for comparing deterministic runs.

## Seed Matrix Simulation

```bash
moon run examples/seed_matrix
```

Demonstrates deterministic regression matrices over multiple seeds for retry,
network, and scheduling-style models.
