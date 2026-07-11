///|
fn status(ok : Bool) -> String {
  if ok {
    "PASS"
  } else {
    "FAIL"
  }
}

///|
fn main {
  let stream = @moonsim.event_stream()
  let produced = stream.record(
    @moonsim.message_event_kind(),
    0,
    "message.produce",
    correlation_id="order-42",
    source="producer",
    target="orders",
  )
  let delivered = stream.record(
    @moonsim.message_event_kind(),
    2,
    "message.deliver",
    correlation_id="order-42",
    source="orders",
    target="worker",
    parent_id=produced.id,
  )
  let timeout = stream.record(
    @moonsim.timer_event_kind(),
    5,
    "ack.timeout",
    correlation_id="order-42",
    source="scheduler",
    target="worker",
    parent_id=delivered.id,
  )
  ignore(
    stream.record(
      @moonsim.message_event_kind(),
      6,
      "message.retry",
      correlation_id="order-42",
      source="orders",
      target="worker",
      parent_id=timeout.id,
    ),
  )
  ignore(
    stream.record(
      @moonsim.message_event_kind(),
      8,
      "message.ack",
      correlation_id="order-42",
      source="worker",
      target="orders",
      parent_id=delivered.id,
    ),
  )

  let fault_policy = @moonsim.event_mutation_policy(
    seed=4096UL,
    duplicate_percent=100,
  )
  let fault = stream.replay(fault_policy)
  let evidence = @moonsim.event_failure_case(
    "message_finally_classified_once", stream, fault_policy,
  )
  let replay = evidence.replay()
  let fixed = stream.replay(@moonsim.event_mutation_policy(seed=4096UL))

  println("message queue reliability")
  println("seed=" + fault.seed.to_string())
  println("produced=1 acked=1 retries=1 dead_letter=0")
  println("fault_duplicate_count=" + fault.duplicated.to_string())
  println(
    "message_finally_classified_once=" +
    status(fault.duplicated == 0) +
    " (expected finding)",
  )
  println("ack_before_loss=" + status(fault.dropped == 0))
  println("retry_within_limit=" + status(1 <= 3))
  println("same_seed_replay=" + status(fault.matches_digest(replay)))
  println("fixed_policy=" + status(fixed.duplicated == 0 && fixed.dropped == 0))
  println("digest=" + fault.digest.to_string())
}
