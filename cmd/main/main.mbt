///|
fn main {
  println("moonsim deterministic model testing")
  println("")
  println("Problem")
  println("  retry/timeout behavior can hide failures in wall-clock tests")
  println("  a late success may arrive after the caller has already timed out")
  println("")

  let baseline_config = @moonsim.service_resilience_config(
    seed=2026UL,
    requests=32,
    fail_percent=6,
    drop_percent=2,
    min_success_percent=70,
  )
  let baseline = @moonsim.run_service_resilience_suite(config=baseline_config)
  println("Baseline")
  println("  seed=" + baseline_config.seed.to_string())
  println("  requests=" + baseline_config.requests.to_string())
  println(
    "  retries=" +
    baseline.retried.to_string() +
    " timeouts=" +
    baseline.timed_out.to_string() +
    " late_successes=" +
    baseline.late_successes.to_string() +
    " failed=" +
    baseline.failed.to_string(),
  )
  println("  digest=" + baseline.digest.to_string())
  println(
    "  invariant=" +
    (if baseline.invariants.passed() { "pass" } else { "fail" }),
  )
  println("")

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
  let fault = @moonsim.run_service_resilience_suite(config=fault_config)
  println("Fault reproduction")
  println("  seed=" + fault_config.seed.to_string())
  println(
    "  invariant=" +
    (if fault.invariants.passed() { "pass" } else { "fail" }) +
    " (expected demonstration)",
  )
  println("  failed_rule=slo_min_success_percent")
  println("  digest=" + fault.digest.to_string())
  println("")

  let replay = @moonsim.run_service_resilience_suite(config=fault_config)
  println("Replay")
  println("  same_seed=yes")
  println(
    "  same_digest=" +
    (if fault.digest == replay.digest { "yes" } else { "no" }),
  )
  println("")

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
  let fixed = @moonsim.run_service_resilience_suite(config=fixed_config)
  println("Fixed run")
  println(
    "  invariant=" + (if fixed.invariants.passed() { "pass" } else { "fail" }),
  )
  println("  digest=" + fixed.digest.to_string())
  println("")

  println("Seed matrix")
  println(
    @moonsim.service_resilience_seed_matrix([2024UL, 2025UL, 2026UL]).render(),
  )
}
