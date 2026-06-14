# Roadmap

This roadmap tracks the initial work for `moonsim` as a reusable MoonBit
simulation library.

## Phase 0: Topic Confirmation

Status: complete

Tasks:

- Review ecosystem overlap and adjacent MoonBit libraries.
- Confirm the primary topic: deterministic simulation and replay.
- Define non-goals and module boundaries.
- Write the initial design document.

Acceptance criteria:

- Topic is final.
- Non-goals are explicit.
- Reuse value is clear.

## Phase 1: MoonBit Project Skeleton

Status: complete

Tasks:

- Create the MoonBit package layout.
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
- Add deterministic digest and trace comparison.
- Add counters.
- Add gauges.
- Add sample metrics and simple histogram summaries.

Acceptance criteria:

- A simulation run can produce a trace.
- A trace can be compared against a later run.
- Metrics are deterministic and testable.

## Phase 4: Scenario And Snapshot Helpers

Status: complete

Tasks:

- Add scenario runner helpers.
- Add assertion helpers.
- Add readable failure messages.
- Add snapshot, restore, and fork comparison helpers.

Acceptance criteria:

- Example scenarios are shorter and clearer than raw scheduler calls.
- Scenario failures show useful context.
- Forked runs can be compared from the same checkpoint.

## Phase 5: Model Helpers And Examples

Status: complete

Tasks:

- Queue simulation example.
- Retry/backoff simulation example.
- Traffic light simulation example.
- Game loop fork comparison example.
- Message protocol example.
- State-machine example.
- CLI runner for demo output.

Acceptance criteria:

- Examples are runnable from the command line.
- README shows how to run them.
- Examples demonstrate real usage scenarios.

## Phase 6: Documentation And Polish

Status: in progress

Tasks:

- Keep README concise and user-focused.
- Maintain `DESIGN.md`.
- Maintain `docs/api.md`.
- Maintain `docs/examples.md`.
- Keep examples and tests passing.

Acceptance criteria:

- Documentation is enough for another developer to use the library.
- Tests and examples demonstrate completeness.
- Public docs emphasize reusable infrastructure and model-testing value.
