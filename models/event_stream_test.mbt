///|
test "workflow results project into task events" {
  let plan = WorkflowPlan::new(worker_count=2)
  ignore(plan.add("fetch", 2))
  ignore(plan.add("commit", 1, deps=[1]))

  let stream = run_workflow_model(plan).event_stream()
  let events = stream.ordered()
  assert_eq(events.length(), 4)
  assert_eq(events[0].kind.label(), "task")
  assert_eq(events[1].kind.label(), "task")
  assert_eq(events[1].parent_id, events[0].id)
  assert_true(stream.invariants().passed())
}

///|
test "queue results project into message events" {
  let result = run_queue_model(queue_config(seed=19UL, customers=3))
  let stream = result.event_stream()
  let events = stream.ordered()
  assert_eq(events.length(), result.trace.length())
  assert_eq(events[0].kind.label(), "message")
  assert_true(stream.invariants().passed())
}

///|
test "recorded HTTP exchanges project into external call events" {
  let stream = retry_timeout_recording().event_stream()
  let events = stream.ordered()
  assert_eq(events.length(), 4)
  assert_eq(events[0].kind.label(), "external_call")
  assert_eq(events[1].kind.label(), "external_call")
  let mut response_has_request = false
  for event in events {
    if event.label == "external.response" && event.parent_id > 0 {
      response_has_request = true
    }
  }
  assert_true(response_has_request)
  assert_true(stream.invariants().passed())
}
