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
