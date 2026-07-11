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
  let plan = @moonsim.WorkflowPlan::new(worker_count=2)
    .add("fetch", 2)
    .add("parse", 3, deps=[1])
    .add("index", 4, deps=[2])
    .add("publish", 1, deps=[3])
  let result = @moonsim.run_workflow_model(plan, seed=515UL)
  let stream = result.event_stream()
  let fault_policy = @moonsim.event_mutation_policy(
    seed=515UL,
    failure_percent=35,
    reorder_same_tick=true,
  )
  let fault = stream.replay(fault_policy)
  let evidence = @moonsim.event_failure_case(
    "task_terminal_state_is_stable", stream, fault_policy,
  )
  let replay = evidence.replay()
  let fixed = stream.replay(@moonsim.event_mutation_policy(seed=515UL))

  println("workflow reliability")
  println("tasks=" + result.tasks.to_string())
  println("critical_path=" + result.critical_path.to_string())
  println("fault_injected=" + fault.failed.to_string())
  println(
    "dependency_before_execution=" +
    status(result.final_tick == result.critical_path),
  )
  println(
    "terminal_state_no_rollback=" +
    status(fault.failed == 0) +
    " (expected finding when FAIL)",
  )
  println("task_completed_once=" + status(fault.duplicated == 0))
  println("same_seed_replay=" + status(fault.matches_digest(replay)))
  println("fixed_policy=" + status(fixed.failed == 0 && fixed.duplicated == 0))
  println("digest=" + fault.digest.to_string())
}
