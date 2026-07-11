///|
fn verdict(ok : Bool) -> String {
  if ok {
    "pass"
  } else {
    "fail"
  }
}

///|
fn main {
  println("moonsim: deterministic typed event simulation for MoonBit")
  println("kinds=Message,Task,Timer,StateTransition,ExternalCall")
  println("")

  let stream = @moonsim.event_stream()
  let sent = stream.record(
    @moonsim.message_event_kind(),
    0,
    "message.send",
    correlation_id="job-7",
    source="producer",
    target="worker",
  )
  ignore(
    stream.record(
      @moonsim.task_event_kind(),
      3,
      "task.complete",
      correlation_id="job-7",
      source="worker",
      target="result",
      parent_id=sent.id,
    ),
  )
  let fault_policy = @moonsim.event_mutation_policy(
    seed=2026UL,
    duplicate_percent=100,
  )
  let fault = stream.replay(fault_policy)
  let evidence = @moonsim.event_failure_case(
    "job_completed_once", stream, fault_policy,
  )
  let replay = evidence.replay()
  let fixed = stream.replay(@moonsim.event_mutation_policy(seed=evidence.seed))

  println("message/task fault reproduction")
  println("  seed=" + evidence.seed.to_string())
  println("  duplicated=" + fault.duplicated.to_string())
  println(
    "  invariant=" + verdict(fault.duplicated == 0) + " (expected finding)",
  )
  println("  digest=" + evidence.digest.to_string())
  println("same seed replay")
  println("  same_digest=" + verdict(fault.matches_digest(replay)))
  println("fixed policy regression")
  println("  invariant=" + verdict(fixed.duplicated == 0 && fixed.failed == 0))
  println("")

  let recording = @moonsim.retry_timeout_recording()
  let http_fault = recording.replay(
    policy=@moonsim.retry_timeout_fault_policy(),
  )
  let http_fixed = recording.replay(
    policy=@moonsim.retry_timeout_fixed_policy(),
  )
  println("ExternalCall adapter: recorded HTTP compatibility")
  println(
    "  fault_invariant=" +
    verdict(http_fault.invariants.passed()) +
    " (expected finding)",
  )
  println("  fixed_invariant=" + verdict(http_fixed.invariants.passed()))
  println("  showcase_exit=success")
}
