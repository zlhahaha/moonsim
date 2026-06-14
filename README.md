# moonsim

Deterministic simulation, trace, and replay framework for MoonBit.

`moonsim` is a MoonBit OSC2026 competition project. It provides a reusable
virtual-time simulation kernel for tests, demos, model experiments, game logic,
retry policies, queueing systems, and protocol sketches.

## Quick Start

```bash
moon check
moon test
moon run cmd/main
```

The CLI demo prints a deterministic retry-style simulation trace and digest.

## API Preview

```moonbit
let sim = @moonsim.Sim::new(seed=2026UL)
ignore(sim.schedule_after(5, "request_arrives"))
ignore(sim.schedule_after(13, "retry_succeeds"))
ignore(sim.run_until_idle())

println(sim.metrics().counter("events_executed"))
println(sim.digest())
```

Run the queue example:

```bash
moon run examples/queue
```

Run the retry/backoff example:

```bash
moon run examples/retry
```

Run the traffic light example:

```bash
moon run examples/traffic
```

Run the game loop fork example:

```bash
moon run examples/game_loop
```

Run the message protocol example:

```bash
moon run examples/protocol
```

Run the state machine example:

```bash
moon run examples/order_state
```

## Competition Fit

This project directly targets the recommended "Deterministic simulation
framework" direction. It is designed as reusable MoonBit infrastructure rather
than a one-off application.

The initial ecosystem research found mature or highly overlapping projects in
Markdown parsing, template rendering, graph/pathfinding, collections, and
logging/tracing. `moonsim` avoids those crowded areas and focuses on a reusable
deterministic simulation kernel with trace, digest, metrics, CLI demos, and
examples.

See:

- `docs/ecosystem-research.md`
- `docs/project-proposal-moonsim.md`
- `docs/roadmap.md`
- `docs/api.md`
- `docs/examples.md`
- `DESIGN.md`
