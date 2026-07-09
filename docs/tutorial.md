# Tutorial: Reproduce a Retry/Timeout Bug

This tutorial shows the workflow moonsim is built for: turn a flaky distributed
systems failure into a deterministic model test with a seed, a trace digest, and
invariants that can be checked every time.

The example is a common retry/timeout bug. A request times out, a retry is
scheduled, and the system later receives a success for one of the attempts. If
the model only counts the final success, timeout metrics and SLO checks can look
healthy even though callers already observed failures.

## 1. Run The Showcase

From the repository root:

```bash
moon run cmd/main
```

The showcase prints the problem, runs the service resilience model, records a
digest, replays the same seed, and checks whether the invariants pass.

## 2. Reproduce With One Seed

After installing the package with `moon add zlhahaha/moonsim`, start with a
fixed seed:

```moonbit
let result = @moonsim.run_service_resilience_suite(
  config=@moonsim.service_resilience_config(
    seed=2026UL,
    requests=32,
    fail_percent=6,
    drop_percent=2,
    timeout_ticks=16,
    retry_limit=2,
    min_success_percent=70,
  ),
)

println(@moonsim.render_service_resilience_report(result))
println("digest=" + result.digest.to_string())
println(result.invariants.render())
assert_true(result.invariants.passed())
```

The seed makes the run repeatable. The digest is a compact fingerprint of the
trace and metrics, so a future run with the same configuration should produce
the same digest.

## 3. Add The Invariant That Catches The Bug

For retry and timeout systems, useful invariants are usually business rules, not
implementation details. The service resilience model checks rules such as:

- every request is classified exactly once;
- timeout outcomes are counted as failures;
- queue depth stays inside the configured bound;
- the observed success rate meets the configured SLO.

The timeout rule is the important one for this bug class:

```moonbit
assert_true(result.timed_out <= result.failed)
```

If a timeout is hidden by a later success, this invariant fails and the seed can
be replayed.

## 4. Search A Seed Matrix

One seed proves reproducibility. A small matrix gives confidence that the model
is not only passing one lucky schedule:

```moonbit
let matrix = @moonsim.service_resilience_seed_matrix([
  2024UL, 2025UL, 2026UL, 2027UL,
])

println(matrix.render())
```

When a row fails, keep the seed and digest in the issue or regression test. That
is the evidence needed to replay the same ordering later.

## 5. Verify The Fixed Run

After fixing the model or production retry policy, keep the original failing
seed and run it again:

```moonbit
let fixed = @moonsim.run_service_resilience_suite(
  config=@moonsim.service_resilience_config(
    seed=2026UL,
    requests=32,
    fail_percent=6,
    drop_percent=2,
    timeout_ticks=16,
    retry_limit=2,
    min_success_percent=70,
  ),
)

println("fixed_digest=" + fixed.digest.to_string())
println(fixed.invariants.render())
assert_true(fixed.invariants.passed())
```

The test should pass for the saved seed and for the wider seed matrix. That is
the main value of deterministic simulation: the rare interleaving becomes a
normal regression test.

## 6. Keep It In CI

For repository verification, run:

```bash
moon fmt --check
moon check --deny-warn
moon info
git diff --exit-code
moon test --deny-warn
moon run cmd/main
moon run examples/service_resilience
```

`moon info` plus `git diff --exit-code` ensures generated interface files stay
committed. `moon run cmd/main` and the service example prove the package still
works as an executable tool, not only as a collection of APIs.
