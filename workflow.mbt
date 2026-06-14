///|
pub(all) struct WorkflowTask {
  id : Int
  name : String
  duration : Int
  deps : Array[Int]
}

///|
pub(all) struct WorkflowPlan {
  worker_count : Int
  mut tasks : Array[WorkflowTask]
}

///|
pub(all) struct WorkflowTaskRun {
  id : Int
  name : String
  worker : Int
  start_tick : Int
  finish_tick : Int
}

///|
pub(all) struct WorkflowResult {
  tasks : Int
  workers : Int
  final_tick : Int
  critical_path : Int
  runs : Array[WorkflowTaskRun]
  digest : UInt64
}

///|
pub fn WorkflowPlan::new(worker_count? : Int = 1) -> WorkflowPlan {
  { worker_count: if worker_count < 1 { 1 } else { worker_count }, tasks: [] }
}

///|
pub fn WorkflowPlan::add(
  self : WorkflowPlan,
  name : String,
  duration : Int,
  deps? : Array[Int] = []
) -> WorkflowPlan {
  let id = self.tasks.length() + 1
  self.tasks.push({
    id,
    name,
    duration: if duration < 1 { 1 } else { duration },
    deps,
  })
  self
}

///|
pub fn WorkflowPlan::task_count(self : WorkflowPlan) -> Int {
  self.tasks.length()
}

///|
pub fn WorkflowPlan::validate(self : WorkflowPlan) -> ValidationReport {
  let issues : Array[ValidationIssue] = []
  for task in self.tasks {
    for dep in task.deps {
      if dep < 1 || dep > self.tasks.length() {
        issues.push(validation_issue("bad-workflow-dependency", "dependency id is out of range"))
      }
      if dep == task.id {
        issues.push(validation_issue("self-workflow-dependency", "task cannot depend on itself"))
      }
    }
  }
  { subject: "workflow", issues }
}

///|
pub fn run_workflow_model(plan : WorkflowPlan, seed? : UInt64 = 515UL) -> WorkflowResult {
  let sim = Sim::new(seed~)
  let worker_available : Array[Int] = []
  let completed : Array[Int] = []
  let runs : Array[WorkflowTaskRun] = []
  for _ in 0..<plan.worker_count {
    worker_available.push(0)
  }
  for task in plan.tasks {
    let ready = workflow_ready_tick(task, runs)
    let worker = workflow_choose_worker(worker_available)
    let start = if worker_available[worker] > ready { worker_available[worker] } else { ready }
    let finish = start + task.duration
    worker_available[worker] = finish
    completed.push(task.id)
    runs.push({ id: task.id, name: task.name, worker, start_tick: start, finish_tick: finish })
    ignore(sim.schedule_at(start, "workflow:" + task.name + ":start"))
    ignore(sim.schedule_at(finish, "workflow:" + task.name + ":finish"))
    sim.inc_counter("workflow_tasks")
    sim.sample("workflow_duration", task.duration)
    sim.sample("workflow_finish", finish)
  }
  ignore(sim.run_until_idle())
  {
    tasks: plan.tasks.length(),
    workers: plan.worker_count,
    final_tick: sim.time(),
    critical_path: workflow_critical_path(plan),
    runs,
    digest: sim.digest(),
  }
}

///|
fn workflow_ready_tick(task : WorkflowTask, runs : Array[WorkflowTaskRun]) -> Int {
  let mut ready = 0
  for dep in task.deps {
    for run in runs {
      if run.id == dep && run.finish_tick > ready {
        ready = run.finish_tick
      }
    }
  }
  ready
}

///|
fn workflow_choose_worker(worker_available : Array[Int]) -> Int {
  let mut best = 0
  let mut i = 1
  while i < worker_available.length() {
    if worker_available[i] < worker_available[best] {
      best = i
    }
    i += 1
  }
  best
}

///|
pub fn workflow_critical_path(plan : WorkflowPlan) -> Int {
  let finish : Array[Int] = []
  for task in plan.tasks {
    let mut ready = 0
    for dep in task.deps {
      if dep > 0 && dep <= finish.length() && finish[dep - 1] > ready {
        ready = finish[dep - 1]
      }
    }
    finish.push(ready + task.duration)
  }
  let mut max = 0
  for value in finish {
    if value > max {
      max = value
    }
  }
  max
}

///|
pub fn WorkflowResult::summary(self : WorkflowResult) -> ModelSummary {
  {
    name: "workflow",
    digest: self.digest,
    final_tick: self.final_tick,
    events: self.tasks * 2,
  }
}

///|
pub fn WorkflowResult::render(self : WorkflowResult) -> String {
  let buf = StringBuilder::new()
  buf.write_string("# Workflow\n")
  buf.write_string("tasks=" + self.tasks.to_string() + "\n")
  buf.write_string("workers=" + self.workers.to_string() + "\n")
  buf.write_string("final_tick=" + self.final_tick.to_string() + "\n")
  buf.write_string("critical_path=" + self.critical_path.to_string() + "\n")
  for run in self.runs {
    buf.write_string(
      "- " + run.name +
      " worker=" + run.worker.to_string() +
      " start=" + run.start_tick.to_string() +
      " finish=" + run.finish_tick.to_string() + "\n",
    )
  }
  buf.to_string()
}
