///|
fn pass_or_fail(passed : Bool) -> String {
  if passed {
    "pass"
  } else {
    "fail"
  }
}

///|
fn policy_for_seed(
  seed : UInt64,
  accept_late_success : Bool,
) -> @moonsim.HttpReliabilityPolicy {
  @moonsim.http_reliability_policy(
    seed~,
    timeout_ticks=5,
    retry_limit=1,
    deadline_ticks=8,
    accept_late_success~,
  )
}

///|
fn main {
  println("moonsim 确定性 HTTP 可靠性测试")
  println("Deterministic simulation and model testing for MoonBit")
  println("")
  println("问题")
  println(
    "  在真实 HTTP 测试中，超时后的迟到成功和重试结果可能掩盖重复处理。",
  )
  println(
    "  moonsim 将已记录的调用放入虚拟时间，用固定 seed 重放并检查业务规则。",
  )
  println("")

  let recording = @moonsim.retry_timeout_recording()
  let fault_policy = @moonsim.retry_timeout_fault_policy()
  let fault = recording.replay(policy=fault_policy)
  println("记录与故障重放")
  println("  scenario=retry timeout late success")
  println("  seed=" + fault_policy.seed.to_string())
  println("  http_success=" + fault.http_successes.to_string())
  println("  on_time_success=" + fault.on_time_successes.to_string())
  println("  late_success=" + fault.late_successes.to_string())
  println("  duplicate_processed=" + fault.duplicate_processed.to_string())
  println(
    "  invariant=" +
    pass_or_fail(fault.invariants.passed()) +
    "（预期的故障演示）",
  )
  println("  failed_rule=http_request_finalized_once")
  println("  digest=" + fault.digest.to_string())
  println("  evidence_json=" + recording.to_json(policy=fault_policy))
  println("")

  let evidence = recording.failure_case(policy=fault_policy).unwrap()
  let replay = evidence.replay()
  println("固定 seed 重放")
  println(
    "  same_seed=" +
    (if replay.policy.seed == evidence.seed { "yes" } else { "no" }),
  )
  println(
    "  same_digest=" +
    (if replay.digest == evidence.digest { "yes" } else { "no" }),
  )
  println("  failed_rule=" + evidence.failed_rule)
  println("")

  let fixed = evidence.verify_fixed_policy(
    @moonsim.retry_timeout_fixed_policy(),
  )
  println("修复后回归")
  println(
    "  seed=" + fixed.policy.seed.to_string() + "（使用原失败 seed）",
  )
  println("  late_success_accepted=" + fixed.late_success_accepted.to_string())
  println("  invariant=" + pass_or_fail(fixed.invariants.passed()))
  println("  digest=" + fixed.digest.to_string())
  println("")

  let seeds : Array[UInt64] = [2024UL, 2025UL, 2026UL]
  let mut passed : Int = 0
  let mut failed : Int = 0
  let mut index : Int = 0
  while index < seeds.length() {
    let result = recording.replay(policy=policy_for_seed(seeds[index], false))
    if result.invariants.passed() {
      passed = passed + 1
    } else {
      failed = failed + 1
    }
    index = index + 1
  }
  println("Seed matrix")
  println("  seeds=" + seeds.length().to_string())
  println("  passed=" + passed.to_string() + " failed=" + failed.to_string())
  println(
    "  这里的 fail 表示模型发现业务规则被违反，不表示 showcase 命令执行失败。",
  )
}
