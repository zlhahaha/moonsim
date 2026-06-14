///|
fn main {
  let plan = @moonsim.WorkflowPlan::new(worker_count=2)
    .add("fetch", 2)
    .add("parse", 3, deps=[1])
    .add("index", 4, deps=[2])
    .add("publish", 1, deps=[3])
  let result = @moonsim.run_workflow_model(plan)

  println("workflow simulation")
  println("tasks=" + result.tasks.to_string())
  println("workers=" + result.workers.to_string())
  println("critical_path=" + result.critical_path.to_string())
  println("final_tick=" + result.final_tick.to_string())
  println("digest=" + result.digest.to_string())
}
