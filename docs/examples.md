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
