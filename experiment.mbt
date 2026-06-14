///|
pub(all) struct ExperimentCase {
  name : String
  summary : ModelSummary
  notes : String
}

///|
pub(all) struct ExperimentReport {
  title : String
  cases : Array[ExperimentCase]
}

///|
pub fn experiment_case(name : String, summary : ModelSummary, notes? : String = "") -> ExperimentCase {
  { name, summary, notes }
}

///|
pub fn ExperimentReport::new(title : String) -> ExperimentReport {
  { title, cases: [] }
}

///|
pub fn ExperimentReport::add(self : ExperimentReport, item : ExperimentCase) -> ExperimentReport {
  self.cases.push(item)
  self
}

///|
pub fn ExperimentReport::case_count(self : ExperimentReport) -> Int {
  self.cases.length()
}

///|
pub fn ExperimentReport::combined_digest(self : ExperimentReport) -> UInt64 {
  let entries : Array[TraceEntry] = []
  for i in 0..<self.cases.length() {
    let item = self.cases[i]
    entries.push(trace_entry(i, i + 1, "experiment.case", item.summary.line()))
  }
  trace_digest(entries)
}

///|
pub fn ExperimentReport::total_events(self : ExperimentReport) -> Int {
  let mut total = 0
  for item in self.cases {
    total += item.summary.events
  }
  total
}

///|
pub fn ExperimentReport::max_final_tick(self : ExperimentReport) -> Int {
  let mut max = 0
  for item in self.cases {
    if item.summary.final_tick > max {
      max = item.summary.final_tick
    }
  }
  max
}

///|
pub fn ExperimentReport::render(self : ExperimentReport) -> String {
  let buf = StringBuilder::new()
  buf.write_string("# Experiment " + self.title + "\n")
  buf.write_string("cases: " + self.case_count().to_string() + "\n")
  buf.write_string("events: " + self.total_events().to_string() + "\n")
  buf.write_string("max_tick: " + self.max_final_tick().to_string() + "\n")
  buf.write_string("digest: " + self.combined_digest().to_string() + "\n")
  for item in self.cases {
    buf.write_string("- " + item.name + ": " + item.summary.line())
    if item.notes != "" {
      buf.write_string(" (" + item.notes + ")")
    }
    buf.write_string("\n")
  }
  buf.to_string()
}

///|
pub fn demo_experiment() -> ExperimentReport {
  ExperimentReport::new("moonsim model demo")
    .add(experiment_case(
      "queue",
      queue_summary(run_queue_model(queue_config(customers=5))),
      notes="arrival and service model",
    ))
    .add(experiment_case(
      "retry",
      retry_summary(run_retry_model(retry_config(fail_until=2))),
      notes="deterministic backoff",
    ))
    .add(experiment_case(
      "traffic",
      traffic_summary(run_traffic_model(traffic_config(cars=12))),
      notes="timer and sample metrics",
    ))
    .add(experiment_case(
      "network",
      network_summary(run_network_model(network_config(messages=6))),
      notes="message delivery and retry",
    ))
    .add(experiment_case(
      "load_balancer",
      load_balancer_summary(run_load_balancer_model(load_balancer_config(jobs=8))),
      notes="worker scheduling model",
    ))
    .add(experiment_case(
      "circuit_breaker",
      run_circuit_breaker_model(calls=8).summary(),
      notes="service protection model",
    ))
    .add(experiment_case(
      "token_bucket",
      run_token_bucket_model(requests=8).summary(),
      notes="rate limiting model",
    ))
}

///|
pub fn compare_experiments(left : ExperimentReport, right : ExperimentReport) -> TraceComparison {
  let left_entries : Array[TraceEntry] = []
  let right_entries : Array[TraceEntry] = []
  for i in 0..<left.cases.length() {
    left_entries.push(trace_entry(i, i + 1, "experiment.case", left.cases[i].summary.line()))
  }
  for i in 0..<right.cases.length() {
    right_entries.push(trace_entry(i, i + 1, "experiment.case", right.cases[i].summary.line()))
  }
  compare_traces(left_entries, right_entries)
}
