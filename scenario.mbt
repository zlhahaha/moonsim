///|
pub(all) struct ScenarioExpectation {
  kind : String
  name : String
  expected : String
}

///|
pub(all) struct ScenarioFailure {
  kind : String
  name : String
  expected : String
  actual : String
}

///|
pub(all) struct ScenarioReport {
  name : String
  mut passed : Bool
  steps : Int
  final_tick : Int
  digest : UInt64
  mut failures : Array[ScenarioFailure]
}

///|
pub(all) struct Scenario {
  name : String
  seed : UInt64
  max_steps : Int
  mut expectations : Array[ScenarioExpectation]
}

///|
pub fn Scenario::new(name : String, seed? : UInt64 = 1UL, max_steps? : Int = 100000) -> Scenario {
  { name, seed, max_steps, expectations: [] }
}

///|
pub fn Scenario::expect_counter(self : Scenario, name : String, value : Int) -> Scenario {
  self.expectations.push({ kind: "counter", name, expected: value.to_string() })
  self
}

///|
pub fn Scenario::expect_gauge(self : Scenario, name : String, value : Int) -> Scenario {
  self.expectations.push({ kind: "gauge", name, expected: value.to_string() })
  self
}

///|
pub fn Scenario::expect_final_tick(self : Scenario, value : Int) -> Scenario {
  self.expectations.push({ kind: "final_tick", name: "time", expected: value.to_string() })
  self
}

///|
pub fn Scenario::expect_pending(self : Scenario, value : Int) -> Scenario {
  self.expectations.push({ kind: "pending", name: "events", expected: value.to_string() })
  self
}

///|
pub fn Scenario::expect_digest(self : Scenario, value : UInt64) -> Scenario {
  self.expectations.push({ kind: "digest", name: "trace", expected: value.to_string() })
  self
}

///|
pub fn Scenario::expect_trace_contains(self : Scenario, text : String) -> Scenario {
  self.expectations.push({ kind: "trace_contains", name: "trace", expected: text })
  self
}

///|
pub fn Scenario::expect_sample_count(self : Scenario, name : String, value : Int) -> Scenario {
  self.expectations.push({ kind: "sample_count", name, expected: value.to_string() })
  self
}

///|
pub fn Scenario::expect_summary_min(self : Scenario, name : String, value : Int) -> Scenario {
  self.expectations.push({ kind: "summary_min", name, expected: value.to_string() })
  self
}

///|
pub fn Scenario::expect_summary_max(self : Scenario, name : String, value : Int) -> Scenario {
  self.expectations.push({ kind: "summary_max", name, expected: value.to_string() })
  self
}

///|
pub fn Scenario::create_sim(self : Scenario) -> Sim {
  Sim::new(seed=self.seed)
}

///|
pub fn Scenario::verify(self : Scenario, sim : Sim) -> ScenarioReport {
  let steps = sim.run_until_idle(max_steps=self.max_steps)
  let report = {
    name: self.name,
    passed: true,
    steps,
    final_tick: sim.time(),
    digest: sim.digest(),
    failures: [],
  }
  for expectation in self.expectations {
    self.check_expectation(expectation, sim, report)
  }
  if report.failures.length() > 0 {
    report.passed = false
  }
  report
}

///|
fn Scenario::check_expectation(
  _self : Scenario,
  expectation : ScenarioExpectation,
  sim : Sim,
  report : ScenarioReport
) -> Unit {
  let actual = match expectation.kind {
    "counter" => sim.metrics().counter(expectation.name).to_string()
    "gauge" => sim.metrics().gauge(expectation.name).to_string()
    "final_tick" => sim.time().to_string()
    "pending" => sim.pending_count().to_string()
    "digest" => sim.digest().to_string()
    "trace_contains" => if sim.trace_text().contains(expectation.expected) { expectation.expected } else { "" }
    "sample_count" => sim.metrics().sample_count(expectation.name).to_string()
    "summary_min" => sim.metrics().summary(expectation.name).min.to_string()
    "summary_max" => sim.metrics().summary(expectation.name).max.to_string()
    _ => ""
  }
  if actual != expectation.expected {
    report.failures.push({
      kind: expectation.kind,
      name: expectation.name,
      expected: expectation.expected,
      actual,
    })
  }
}

///|
pub fn ScenarioReport::summary(self : ScenarioReport) -> String {
  let status = if self.passed { "PASS" } else { "FAIL" }
  status + " " + self.name + " steps=" + self.steps.to_string() +
  " tick=" + self.final_tick.to_string() + " digest=" + self.digest.to_string()
}

///|
pub fn ScenarioReport::failure_text(self : ScenarioReport) -> String {
  let buf = StringBuilder::new()
  for i in 0..<self.failures.length() {
    if i > 0 {
      buf.write_string("\n")
    }
    let failure = self.failures[i]
    buf.write_string(
      failure.kind + ":" + failure.name + " expected=" + failure.expected +
      " actual=" + failure.actual,
    )
  }
  buf.to_string()
}

///|
pub fn ScenarioReport::detailed_text(self : ScenarioReport) -> String {
  let base = self.summary()
  if self.passed {
    base
  } else {
    base + "\n" + self.failure_text()
  }
}

///|
pub fn ScenarioReport::failure_count(self : ScenarioReport) -> Int {
  self.failures.length()
}
