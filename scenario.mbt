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
pub(all) struct ScenarioCase {
  scenario : Scenario
  sim : Sim
}

///|
pub(all) struct ScenarioSuite {
  name : String
  mut cases : Array[ScenarioCase]
}

///|
pub(all) struct ScenarioSuiteReport {
  name : String
  reports : Array[ScenarioReport]
}

///|
pub fn Scenario::new(
  name : String,
  seed? : UInt64 = 1UL,
  max_steps? : Int = 100000,
) -> Scenario {
  { name, seed, max_steps, expectations: [] }
}

///|
pub fn Scenario::expect_counter(
  self : Scenario,
  name : String,
  value : Int,
) -> Scenario {
  self.expectations.push({ kind: "counter", name, expected: value.to_string() })
  self
}

///|
pub fn Scenario::expect_counter_range(
  self : Scenario,
  name : String,
  min : Int,
  max : Int,
) -> Scenario {
  self.expectations.push({
    kind: "counter_range",
    name,
    expected: min.to_string() + ".." + max.to_string(),
  })
  self
}

///|
pub fn Scenario::expect_gauge(
  self : Scenario,
  name : String,
  value : Int,
) -> Scenario {
  self.expectations.push({ kind: "gauge", name, expected: value.to_string() })
  self
}

///|
pub fn Scenario::expect_final_tick(self : Scenario, value : Int) -> Scenario {
  self.expectations.push({
    kind: "final_tick",
    name: "time",
    expected: value.to_string(),
  })
  self
}

///|
pub fn Scenario::expect_final_tick_range(
  self : Scenario,
  min : Int,
  max : Int,
) -> Scenario {
  self.expectations.push({
    kind: "final_tick_range",
    name: "time",
    expected: min.to_string() + ".." + max.to_string(),
  })
  self
}

///|
pub fn Scenario::expect_pending(self : Scenario, value : Int) -> Scenario {
  self.expectations.push({
    kind: "pending",
    name: "events",
    expected: value.to_string(),
  })
  self
}

///|
pub fn Scenario::expect_digest(self : Scenario, value : UInt64) -> Scenario {
  self.expectations.push({
    kind: "digest",
    name: "trace",
    expected: value.to_string(),
  })
  self
}

///|
pub fn Scenario::expect_trace_contains(
  self : Scenario,
  text : String,
) -> Scenario {
  self.expectations.push({
    kind: "trace_contains",
    name: "trace",
    expected: text,
  })
  self
}

///|
pub fn Scenario::expect_trace_kind_count(
  self : Scenario,
  kind : String,
  count : Int,
) -> Scenario {
  self.expectations.push({
    kind: "trace_kind_count",
    name: kind,
    expected: count.to_string(),
  })
  self
}

///|
pub fn Scenario::expect_sample_count(
  self : Scenario,
  name : String,
  value : Int,
) -> Scenario {
  self.expectations.push({
    kind: "sample_count",
    name,
    expected: value.to_string(),
  })
  self
}

///|
pub fn Scenario::expect_summary_min(
  self : Scenario,
  name : String,
  value : Int,
) -> Scenario {
  self.expectations.push({
    kind: "summary_min",
    name,
    expected: value.to_string(),
  })
  self
}

///|
pub fn Scenario::expect_summary_max(
  self : Scenario,
  name : String,
  value : Int,
) -> Scenario {
  self.expectations.push({
    kind: "summary_max",
    name,
    expected: value.to_string(),
  })
  self
}

///|
pub fn Scenario::expect_summary_average_range(
  self : Scenario,
  name : String,
  min : Int,
  max : Int,
) -> Scenario {
  self.expectations.push({
    kind: "summary_average_range",
    name,
    expected: min.to_string() + ".." + max.to_string(),
  })
  self
}

///|
pub fn Scenario::expect_no_validation_issues(self : Scenario) -> Scenario {
  self.expectations.push({ kind: "validation", name: "sim", expected: "PASS" })
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
  report : ScenarioReport,
) -> Unit {
  let actual = match expectation.kind {
    "counter" => sim.metrics().counter(expectation.name).to_string()
    "counter_range" =>
      range_actual(
        sim.metrics().counter(expectation.name),
        expectation.expected,
      )
    "gauge" => sim.metrics().gauge(expectation.name).to_string()
    "final_tick" => sim.time().to_string()
    "final_tick_range" => range_actual(sim.time(), expectation.expected)
    "pending" => sim.pending_count().to_string()
    "digest" => sim.digest().to_string()
    "trace_contains" =>
      if sim.trace_text().contains(expectation.expected) {
        expectation.expected
      } else {
        ""
      }
    "trace_kind_count" =>
      trace_query_result(sim.trace()).kind_count(expectation.name).to_string()
    "sample_count" => sim.metrics().sample_count(expectation.name).to_string()
    "summary_min" => sim.metrics().summary(expectation.name).min.to_string()
    "summary_max" => sim.metrics().summary(expectation.name).max.to_string()
    "summary_average_range" =>
      range_actual(
        sim.metrics().summary(expectation.name).average().to_int(),
        expectation.expected,
      )
    "validation" => if sim.validate().passed() { "PASS" } else { "FAIL" }
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
fn range_actual(value : Int, expected : String) -> String {
  let bounds = parse_range(expected)
  if value >= bounds.min && value <= bounds.max {
    expected
  } else {
    value.to_string()
  }
}

///|
pub(all) struct IntRange {
  min : Int
  max : Int
}

///|
fn parse_range(text : String) -> IntRange {
  let mut split = -1
  for i in 0..<text.length() {
    if text.code_unit_at(i).to_int() == 46 {
      split = i
      break
    }
  }
  if split < 0 {
    { min: 0, max: 0 }
  } else {
    let min = parse_int_slice(text, 0, split)
    let max = parse_int_slice(text, split + 2, text.length())
    { min, max }
  }
}

///|
fn parse_int_slice(text : String, start : Int, end : Int) -> Int {
  let mut value = 0
  let mut sign = 1
  let mut i = start
  if i < end && text.code_unit_at(i).to_int() == 45 {
    sign = -1
    i += 1
  }
  while i < end {
    let code = text.code_unit_at(i).to_int()
    if code >= 48 && code <= 57 {
      value = value * 10 + (code - 48)
    }
    i += 1
  }
  value * sign
}

///|
pub fn ScenarioReport::summary(self : ScenarioReport) -> String {
  let status = if self.passed { "PASS" } else { "FAIL" }
  status +
  " " +
  self.name +
  " steps=" +
  self.steps.to_string() +
  " tick=" +
  self.final_tick.to_string() +
  " digest=" +
  self.digest.to_string()
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
      failure.kind +
      ":" +
      failure.name +
      " expected=" +
      failure.expected +
      " actual=" +
      failure.actual,
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

///|
pub fn ScenarioSuite::new(name : String) -> ScenarioSuite {
  { name, cases: [] }
}

///|
pub fn ScenarioSuite::add(
  self : ScenarioSuite,
  scenario : Scenario,
  sim : Sim,
) -> ScenarioSuite {
  self.cases.push({ scenario, sim })
  self
}

///|
pub fn ScenarioSuite::run(self : ScenarioSuite) -> ScenarioSuiteReport {
  let reports : Array[ScenarioReport] = []
  for item in self.cases {
    reports.push(item.scenario.verify(item.sim))
  }
  { name: self.name, reports }
}

///|
pub fn ScenarioSuiteReport::passed(self : ScenarioSuiteReport) -> Bool {
  self.failed_count() == 0
}

///|
pub fn ScenarioSuiteReport::passed_count(self : ScenarioSuiteReport) -> Int {
  let mut count = 0
  for report in self.reports {
    if report.passed {
      count += 1
    }
  }
  count
}

///|
pub fn ScenarioSuiteReport::failed_count(self : ScenarioSuiteReport) -> Int {
  self.reports.length() - self.passed_count()
}

///|
pub fn ScenarioSuiteReport::summary(self : ScenarioSuiteReport) -> String {
  let status = if self.passed() { "PASS" } else { "FAIL" }
  status +
  " suite=" +
  self.name +
  " passed=" +
  self.passed_count().to_string() +
  " failed=" +
  self.failed_count().to_string()
}

///|
pub fn ScenarioSuiteReport::render(self : ScenarioSuiteReport) -> String {
  let buf = StringBuilder::new()
  buf.write_string(self.summary())
  for report in self.reports {
    buf.write_string("\n- " + report.summary())
    if !report.passed {
      buf.write_string("\n" + report.failure_text())
    }
  }
  buf.to_string()
}
