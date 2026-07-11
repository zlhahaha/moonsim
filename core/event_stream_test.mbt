///|
test "event stream orders events and retains causality" {
  let stream = EventStream::new()
  ignore(
    stream.record(
      timer_event_kind(),
      1,
      "retry.timer",
      correlation_id="order-1",
      source="worker",
      target="worker",
      priority=1,
    ),
  )
  let parent = stream.record(
    message_event_kind(),
    3,
    "message.send",
    correlation_id="order-1",
    source="client",
    target="queue",
    priority=3,
  )
  let child = stream.record(
    state_transition_event_kind(),
    4,
    "order.processing",
    correlation_id="order-1",
    source="queue",
    target="worker",
    parent_id=parent.id,
  )

  let ordered = stream.ordered()
  assert_eq(ordered.length(), 3)
  assert_eq(ordered[0].label, "retry.timer")
  assert_eq(ordered[1].id, parent.id)
  assert_eq(ordered[2].parent_id, parent.id)
  assert_eq(child.id, ordered[2].id)
  assert_true(stream.invariants().passed())
}

///|
test "event stream snapshots and replays deterministically" {
  let stream = EventStream::new()
  let parent = stream.record(
    external_call_event_kind(),
    2,
    "call.request",
    correlation_id="request-7",
  )
  ignore(
    stream.record(
      external_call_event_kind(),
      5,
      "call.response",
      correlation_id="request-7",
      parent_id=parent.id,
    ),
  )
  let snapshot = stream.snapshot()
  let digest = stream.digest()
  ignore(stream.record(timer_event_kind(), 6, "unexpected.timer"))
  stream.restore(snapshot)
  assert_eq(stream.digest(), digest)

  let policy = event_mutation_policy(seed=73UL)
  let left = stream.replay(policy)
  let right = stream.replay(policy)
  assert_true(left.matches_digest(right))
  let failure = event_failure_case("replay_consistency", stream, policy)
  assert_eq(failure.digest, left.digest)
  assert_eq(failure.replay().digest, left.digest)
}

///|
test "event stream keeps ten thousand events in deterministic order" {
  let stream = EventStream::new()
  for index in 0..<10000 {
    ignore(
      stream.record(
        message_event_kind(),
        index / 5,
        "load.message",
        correlation_id=index.to_string(),
        priority=index % 3,
      ),
    )
  }
  let ordered = stream.ordered()
  assert_eq(ordered.length(), 10000)
  assert_eq(ordered[0].id, 1)
  assert_eq(ordered[9999].tick, 1999)
  assert_true(ordered[9998].tick <= ordered[9999].tick)
  assert_true(stream.digest() != 0UL)
}

///|
test "event mutations are repeatable and affect only configured dimensions" {
  let stream = EventStream::new()
  for index in 0..<20 {
    ignore(
      stream.record(
        message_event_kind(),
        index,
        "message.deliver",
        correlation_id=index.to_string(),
      ),
    )
  }

  let delayed = event_mutation_policy(seed=91UL, max_delay=3, delay_percent=100)
  let delayed_left = stream.replay(delayed)
  let delayed_right = stream.replay(delayed)
  assert_true(delayed_left.matches_digest(delayed_right))
  assert_eq(delayed_left.events.length(), 20)
  assert_eq(delayed_left.dropped, 0)
  assert_eq(delayed_left.duplicated, 0)
  assert_eq(delayed_left.failed, 0)

  let dropped = stream.replay(
    event_mutation_policy(seed=92UL, drop_percent=100),
  )
  assert_eq(dropped.dropped, 20)
  assert_eq(dropped.duplicated, 0)
  assert_eq(dropped.failed, 0)

  let duplicated = stream.replay(
    event_mutation_policy(seed=93UL, duplicate_percent=100),
  )
  assert_eq(duplicated.dropped, 0)
  assert_eq(duplicated.duplicated, 20)
  assert_eq(duplicated.events.length(), 40)

  let failed = stream.replay(
    event_mutation_policy(seed=94UL, failure_percent=100),
  )
  assert_eq(failed.failed, 20)
  assert_eq(failed.dropped, 0)
  assert_eq(failed.duplicated, 0)

  let reordered = event_mutation_policy(seed=95UL, reorder_same_tick=true)
  let same_tick = EventStream::new()
  for index in 0..<20 {
    ignore(same_tick.record(task_event_kind(), 1, index.to_string()))
  }
  let reordered_left = same_tick.replay(reordered)
  let reordered_right = same_tick.replay(reordered)
  assert_true(reordered_left.matches_digest(reordered_right))
  assert_eq(reordered_left.events.length(), 20)
}
