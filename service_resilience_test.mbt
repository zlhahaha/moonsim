///|
test "service resilience suite is deterministic" {
  let config = @moonsim.service_resilience_config(seed=9090UL, requests=24)
  let left = @moonsim.run_service_resilience_suite(config~)
  let right = @moonsim.run_service_resilience_suite(config~)
  assert_eq(left.digest, right.digest)
  assert_eq(left.completed, right.completed)
  assert_true(left.invariants.passed())
}

///|
test "service resilience reports request conservation" {
  let result = @moonsim.run_service_resilience_suite(
    config=@moonsim.service_resilience_config(seed=101UL, requests=18),
  )
  assert_eq(result.accepted + result.rejected, result.config.requests)
  assert_true(result.invariants.has_check("request_conservation"))
  assert_true(result.trace.length() > 0)
  assert_true(result.line().contains("service_resilience"))
}

///|
test "service resilience seed matrix aggregates runs" {
  let matrix = @moonsim.service_resilience_seed_matrix([11UL, 12UL, 13UL])
  assert_eq(matrix.count(), 3)
  assert_true(matrix.combined_digest() != 0UL)
}

///|
test "late success is reported separately from timeout" {
  let result = @moonsim.run_service_resilience_suite(
    config=@moonsim.service_resilience_config(
      seed=404UL,
      requests=12,
      workers=8,
      queue_limit=12,
      timeout_ticks=1,
      retry_limit=0,
      base_latency=2,
      jitter=0,
      fail_percent=0,
      drop_percent=0,
      rate_limit_capacity=100,
      rate_limit_refill=100,
      min_success_percent=0,
    ),
  )
  assert_true(result.late_successes > 0)
  assert_true(result.timed_out >= result.late_successes)
  assert_true(result.invariants.passed())
}

///|
test "fixed timeout policy replays original seed" {
  let result = @moonsim.run_service_resilience_suite(
    config=@moonsim.service_resilience_config(
      seed=404UL,
      requests=12,
      workers=8,
      queue_limit=12,
      timeout_ticks=16,
      retry_limit=0,
      base_latency=2,
      jitter=0,
      fail_percent=0,
      drop_percent=0,
      rate_limit_capacity=100,
      rate_limit_refill=100,
      min_success_percent=90,
    ),
  )
  assert_true(result.slo_passed)
  assert_true(result.invariants.passed())
}
