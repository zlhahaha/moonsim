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

Run the queue example:

```bash
moon run examples/queue
```

## Competition Fit

This project directly targets the recommended "Deterministic simulation
framework" direction. It is designed as reusable MoonBit infrastructure rather
than a one-off application.

See:

- `docs/ecosystem-research.md`
- `docs/project-proposal-moonsim.md`
- `docs/roadmap.md`
- `DESIGN.md`
