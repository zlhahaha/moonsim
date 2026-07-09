# moonsim Testing

This repository uses deterministic tests and example smoke checks as the main
quality gate. The goal is that a fresh checkout can be checked, tested, and run
without hidden local state.

## Local Verification

Run these commands before committing:

```bash
moon fmt --check
moon check --deny-warn
moon info
git diff --exit-code
moon test --deny-warn
moon run cmd/main
moon run examples/service_resilience
moon run examples/workflow
moon run examples/seed_matrix
```

`moon info` refreshes the checked-in `pkg.generated.mbti` files. The following
`git diff --exit-code` verifies that generated public interfaces are already
committed and reproducible.

## CI Coverage

The GitHub Actions workflow runs the same core checks on Linux, macOS, and
Windows:

- MoonBit version reporting
- formatting check
- warning-as-error package check
- generated interface verification
- warning-as-error test run
- CLI demo run
- representative example smoke tests

Linux also runs a coverage summary. The coverage step is useful for visibility,
while the deterministic checks and smoke examples remain the release gate.

## Deterministic Evidence

Examples print stable digests and invariant reports. These values are intended
to make behavioral regressions visible without depending on wall-clock timing,
thread scheduling, or random host state.
