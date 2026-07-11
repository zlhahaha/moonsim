///|
test "http replay keeps late success evidence stable" {
  let recording = @moonsim.retry_timeout_recording()
  let policy = @moonsim.retry_timeout_fault_policy()
  let first = recording.replay(policy~)
  let second = recording.replay(policy~)
  assert_true(!first.invariants.passed())
  assert_eq(first.digest, second.digest)
  assert_eq(first.duplicate_processed, 1)
  assert_eq(first.late_success_accepted, 1)
  let failure = recording.failure_case(policy~).unwrap()
  assert_eq(failure.failed_rule, "http_request_finalized_once")
  assert_eq(failure.digest, first.digest)
}

///|
test "http replay verifies a fixed policy against the original seed" {
  let recording = @moonsim.retry_timeout_recording()
  let failure = recording
    .failure_case(policy=@moonsim.retry_timeout_fault_policy())
    .unwrap()
  let fixed = failure.verify_fixed_policy(@moonsim.retry_timeout_fixed_policy())
  assert_true(fixed.invariants.passed())
  assert_eq(fixed.policy.seed, failure.seed)
  assert_eq(fixed.late_success_accepted, 0)
}

///|
test "http replay json escapes recorded request strings" {
  let request = @moonsim.http_request("quote\"slash\\line\n", path="/a\tb")
  let exchange = @moonsim.recorded_http_exchange(
    request,
    @moonsim.http_response_outcome(@moonsim.http_response(200)),
  )
  let transport = @moonsim.recorded_http_transport("json", [exchange])
  let json = transport.to_json()
  assert_true(json.contains("quote\\\"slash\\\\line\\n"))
  assert_true(json.contains("/a\\tb"))
}

///|
test "http replay reports retry limits and cancelled exchanges" {
  let request = @moonsim.http_request("cancelled", attempt=3)
  let transport = @moonsim.recorded_http_transport("retry cap", [
    @moonsim.recorded_http_exchange(request, @moonsim.http_cancelled_outcome()),
  ])
  let result = transport.replay(
    policy=@moonsim.http_reliability_policy(retry_limit=1),
  )
  assert_eq(result.retry_limit_violations, 1)
  assert_eq(result.cancelled, 0)
  assert_true(!result.invariants.passed())
}
