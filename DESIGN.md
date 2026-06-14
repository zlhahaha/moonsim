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

The first implementation milestone starts with a standard MoonBit library and a
CLI entry point. Later milestones add deterministic RNG, virtual time, event
scheduling, trace recording, replay checks, metrics, examples, and docs.

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
