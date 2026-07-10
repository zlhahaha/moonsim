# Reproducing a Retry and Timeout Bug

This tutorial turns an intermittent retry/timeout problem into a deterministic model test. The example separates three facts that are often accidentally merged in production metrics:

1. whether a request eventually completed;
2. whether the caller had already timed out;
3. whether a late result arrived after that timeout.

The sequence under test is:

```text
request starts -> first attempt times out -> retry is scheduled -> late success arrives
```

The root package is enough for this walkthrough:

```bash
moon add zlhahaha/moonsim
```

## 1. Baseline

Start with a normal service configuration and a fixed seed.

```moonbit
let config = @moonsim.service_resilience_config(
  seed=2026UL,
  requests=32,
  fail_percent=6,
  drop_percent=2,
  min_success_percent=70,
)
let result = @moonsim.run_service_resilience_suite(config~)
println(result.line())
println(result.invariants.render())
assert_true(result.invariants.passed())
```

The result exposes `timed_out`, `retried`, `failed`, and `late_successes` separately. The digest is a compact identity for the generated trace.

## 2. Reproduce the fault

Now make the client timeout shorter than the model's base latency. This deliberately creates a late-success condition and sets an intentionally strict success target.

```moonbit
let fault_config = @moonsim.service_resilience_config(
  seed=2026UL,
  requests=32,
  workers=8,
  queue_limit=32,
  timeout_ticks=1,
  retry_limit=0,
  base_latency=2,
  jitter=0,
  fail_percent=0,
  drop_percent=0,
  rate_limit_capacity=100,
  rate_limit_refill=100,
  min_success_percent=90,
)
let fault = @moonsim.run_service_resilience_suite(fault_config~)
println(fault.line())
println(fault.invariants.render())
```

Here `invariant=fail` is an expected test result, not a tool crash. The model has found that the chosen policy cannot meet the 90% target. The late result is reported explicitly instead of being hidden inside the final success count. The command still exits normally; a real code or CI failure is a failed `moon check`, `moon test`, or generated-interface diff.

## 3. Replay the same seed

Run the fault configuration again and compare the digest.

```moonbit
let replay = @moonsim.run_service_resilience_suite(fault_config~)
assert_eq(fault.digest, replay.digest)
```

The same seed and configuration must produce the same event order and digest. This is the evidence needed to inspect one failure and turn it into a regression test.

## 4. Fix and regress

Increase the timeout to cover the model latency, then keep the original seed and target.

```moonbit
let fixed_config = @moonsim.service_resilience_config(
  seed=2026UL,
  requests=32,
  workers=8,
  queue_limit=32,
  timeout_ticks=16,
  retry_limit=0,
  base_latency=2,
  jitter=0,
  fail_percent=0,
  drop_percent=0,
  rate_limit_capacity=100,
  rate_limit_refill=100,
  min_success_percent=90,
)
let fixed = @moonsim.run_service_resilience_suite(fixed_config~)
assert_true(fixed.invariants.passed())
```

Finally scan more seeds with `service_resilience_seed_matrix`. Passing the original seed is necessary, but a seed matrix checks that the policy is not only correct for one sample.

The ready-to-run version of this story is also available through:

```bash
moon run cmd/main
moon run examples/service_resilience
```

`moonsim` validates logical models and failure workflows. It does not replace real network, database, deployment, integration, or runtime monitoring tests.
