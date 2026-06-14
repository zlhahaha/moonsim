# Roadmap

This roadmap tracks the initial work for the MoonBit OSC2026 project.

## Phase 0: Topic Confirmation

Status: complete

Tasks:

- Review `docs/ecosystem-research.md`.
- Review `docs/project-proposal-moonsim.md`.
- Confirm whether the primary topic is `moonsim`.
- Confirm backup topic, likely benchmark harness.
- Write final `DESIGN.md` after confirmation.

Acceptance criteria:

- Topic is final.
- Non-goals are explicit.
- Competition differentiation is clear.

## Phase 1: MoonBit Project Skeleton

Status: complete

Tasks:

- Create `moon.mod.json`.
- Create package layout.
- Add `README.md`.
- Add `LICENSE`.
- Add `DESIGN.md`.
- Add smoke tests.
- Document build/test commands.

Acceptance criteria:

- `moon check` works.
- `moon test` works.
- Repository can be cloned and built by another developer.

## Phase 2: Deterministic Kernel

Status: complete

Tasks:

- Implement virtual tick/time model.
- Implement stable event ids.
- Implement event queue.
- Implement scheduling at tick and after delay.
- Implement deterministic same-tick ordering.
- Implement cancellation.
- Implement seeded RNG.

Acceptance criteria:

- Tests cover event ordering.
- Tests cover cancellation.
- Tests cover RNG reproducibility.
- Kernel has no wall-clock dependency.

## Phase 3: Trace, Replay, And Metrics

Status: complete

Tasks:

- Add trace entries for scheduling, execution, cancellation, RNG, metrics, and user notes.
- Add deterministic digest or replay comparison.
- Add counters.
- Add gauges.
- Add sample metrics or simple histograms.

Acceptance criteria:

- A simulation run can produce a trace.
- A trace can be compared against a later run.
- Metrics are deterministic and testable.

## Phase 4: Scenario Helpers

Status: partial

Tasks:

- Add scenario runner helpers.
- Add assertion helpers.
- Add readable failure messages.
- Add fixtures for repeatable tests.

Acceptance criteria:

- Example scenarios are shorter and clearer than raw scheduler calls.
- Scenario failures show useful context.

## Phase 5: Examples And CLI

Status: partial

Tasks:

- Queue simulation example.
- Retry/backoff simulation example.
- Traffic light or game loop example.
- CLI runner for examples.
- Trace output from CLI.

Acceptance criteria:

- At least three examples are runnable.
- README shows how to run them.
- Examples demonstrate real usage scenarios.

## Phase 6: Competition Polish

Status: partial

Tasks:

- Expand README.
- Complete `DESIGN.md`.
- Add `docs/api.md`.
- Add `docs/examples.md`.
- Add final ecosystem comparison and independent contribution section.
- Run formatting and tests.

Acceptance criteria:

- Project explains why it does not duplicate existing MoonBit projects.
- Documentation is enough for another developer to use the library.
- Tests and examples demonstrate completeness.
