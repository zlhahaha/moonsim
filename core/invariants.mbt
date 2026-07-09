///|
pub(all) struct InvariantCheck {
  name : String
  passed : Bool
  detail : String
}

///|
pub(all) struct InvariantReport {
  subject : String
  checks : Array[InvariantCheck]
}

///|
pub fn invariant_check(
  name : String,
  passed : Bool,
  detail? : String = "",
) -> InvariantCheck {
  { name, passed, detail }
}

///|
pub fn InvariantReport::new(subject : String) -> InvariantReport {
  { subject, checks: [] }
}

///|
pub fn InvariantReport::add(
  self : InvariantReport,
  check : InvariantCheck,
) -> InvariantReport {
  self.checks.push(check)
  self
}

///|
pub fn InvariantReport::passed(self : InvariantReport) -> Bool {
  self.failed_count() == 0
}

///|
pub fn InvariantReport::failed_count(self : InvariantReport) -> Int {
  let mut failed = 0
  for check in self.checks {
    if !check.passed {
      failed += 1
    }
  }
  failed
}

///|
pub fn InvariantReport::passed_count(self : InvariantReport) -> Int {
  self.checks.length() - self.failed_count()
}

///|
pub fn InvariantReport::check_count(self : InvariantReport) -> Int {
  self.checks.length()
}

///|
pub fn InvariantReport::is_empty(self : InvariantReport) -> Bool {
  self.checks.length() == 0
}

///|
pub fn InvariantReport::has_check(
  self : InvariantReport,
  name : String,
) -> Bool {
  for check in self.checks {
    if check.name == name {
      return true
    }
  }
  false
}

///|
pub fn InvariantReport::merge(
  self : InvariantReport,
  other : InvariantReport,
) -> InvariantReport {
  let merged = InvariantReport::new(self.subject + "+" + other.subject)
  for check in self.checks {
    ignore(merged.add(check))
  }
  for check in other.checks {
    ignore(merged.add(check))
  }
  merged
}

///|
pub fn InvariantReport::only_failures(
  self : InvariantReport,
) -> InvariantReport {
  let failures = InvariantReport::new(self.subject + ":failures")
  for check in self.checks {
    if !check.passed {
      ignore(failures.add(check))
    }
  }
  failures
}

///|
pub fn InvariantReport::summary(self : InvariantReport) -> String {
  let status = if self.passed() { "PASS" } else { "FAIL" }
  status +
  " invariants=" +
  self.subject +
  " checks=" +
  self.checks.length().to_string() +
  " failed=" +
  self.failed_count().to_string()
}

///|
pub fn InvariantReport::render(self : InvariantReport) -> String {
  let buf = StringBuilder::new()
  buf.write_string(self.summary())
  for check in self.checks {
    buf.write_string("\n- ")
    buf.write_string(if check.passed { "PASS " } else { "FAIL " })
    buf.write_string(check.name)
    if check.detail != "" {
      buf.write_string(": " + check.detail)
    }
  }
  buf.to_string()
}

///|
pub fn check_sim_invariants(sim : Sim) -> InvariantReport {
  InvariantReport::new("sim")
  .add(
    invariant_check(
      "non_negative_time",
      sim.time() >= 0,
      detail=sim.time().to_string(),
    ),
  )
  .add(
    invariant_check(
      "valid_pending_events",
      sim.validate().passed(),
      detail=sim.validate().summary(),
    ),
  )
  .add(
    invariant_check(
      "trace_monotonic",
      expect_trace_monotonic_ticks(sim.trace()).passed,
    ),
  )
}

///|
pub fn check_counter_at_least(
  sim : Sim,
  name : String,
  minimum : Int,
) -> InvariantCheck {
  let value = sim.metrics().counter(name)
  invariant_check(
    "counter_at_least:" + name,
    value >= minimum,
    detail=value.to_string() + ">=" + minimum.to_string(),
  )
}

///|
pub fn check_no_pending(sim : Sim) -> InvariantCheck {
  invariant_check(
    "no_pending_events",
    sim.pending_count() == 0,
    detail=sim.pending_count().to_string(),
  )
}
