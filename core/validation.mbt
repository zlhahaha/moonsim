///|
pub(all) struct ValidationIssue {
  code : String
  message : String
  severity : String
}

///|
pub(all) struct ValidationReport {
  subject : String
  issues : Array[ValidationIssue]
}

///|
pub fn validation_issue(
  code : String,
  message : String,
  severity? : String = "error",
) -> ValidationIssue {
  { code, message, severity }
}

///|
pub fn ValidationReport::passed(self : ValidationReport) -> Bool {
  self.issues.length() == 0
}

///|
pub fn ValidationReport::summary(self : ValidationReport) -> String {
  if self.passed() {
    "PASS " + self.subject
  } else {
    "FAIL " + self.subject + " issues=" + self.issues.length().to_string()
  }
}

///|
pub fn ValidationReport::text(self : ValidationReport) -> String {
  let buf = StringBuilder::new()
  buf.write_string(self.summary())
  for issue in self.issues {
    buf.write_string("\n")
    buf.write_string(
      "- " + issue.severity + " " + issue.code + ": " + issue.message,
    )
  }
  buf.to_string()
}

///|
pub fn validate_sim(sim : Sim) -> ValidationReport {
  let issues : Array[ValidationIssue] = []
  if sim.now < 0 {
    issues.push(
      validation_issue("negative-time", "simulation time must not be negative"),
    )
  }
  if sim.next_id < 1 {
    issues.push(
      validation_issue("bad-next-id", "next event id must be positive"),
    )
  }
  validate_event_ids(sim.events, issues)
  validate_event_ticks(sim.events, sim.now, issues)
  { subject: "sim", issues }
}

///|
fn validate_event_ids(
  events : Array[ScheduledEvent],
  issues : Array[ValidationIssue],
) -> Unit {
  let mut i = 0
  while i < events.length() {
    if events[i].id < 1 {
      issues.push(validation_issue("bad-event-id", "event id must be positive"))
    }
    let mut j = i + 1
    while j < events.length() {
      if events[i].id == events[j].id &&
        !events[i].cancelled &&
        !events[j].cancelled {
        issues.push(
          validation_issue(
            "duplicate-event-id", "pending event ids must be unique",
          ),
        )
      }
      j += 1
    }
    i += 1
  }
}

///|
fn validate_event_ticks(
  events : Array[ScheduledEvent],
  now : Int,
  issues : Array[ValidationIssue],
) -> Unit {
  for event in events {
    if event.tick < now && !event.cancelled {
      issues.push(
        validation_issue(
          "past-pending-event", "pending event cannot be before current time",
        ),
      )
    }
    if event.repeat_every < 0 {
      issues.push(
        validation_issue(
          "negative-repeat", "repeat interval must not be negative",
        ),
      )
    }
  }
}

///|
pub fn validate_trace(entries : Array[TraceEntry]) -> ValidationReport {
  let issues : Array[ValidationIssue] = []
  let mut last_tick = 0
  let mut seen = false
  for entry in entries {
    if entry.tick < 0 {
      issues.push(
        validation_issue(
          "negative-trace-tick", "trace tick must be non-negative",
        ),
      )
    }
    if seen && entry.tick < last_tick && entry.kind == "execute" {
      issues.push(
        validation_issue(
          "trace-time-regression", "execute trace moved backwards",
        ),
      )
    }
    last_tick = entry.tick
    seen = true
    if entry.kind == "" {
      issues.push(
        validation_issue("empty-trace-kind", "trace kind should be non-empty"),
      )
    }
  }
  { subject: "trace", issues }
}

///|
pub fn validate_metrics(metrics : Metrics) -> ValidationReport {
  let issues : Array[ValidationIssue] = []
  for counter in metrics.snapshot() {
    if counter.name == "" {
      issues.push(
        validation_issue(
          "empty-counter-name", "counter name should be non-empty",
        ),
      )
    }
  }
  for gauge in metrics.gauge_snapshot() {
    if gauge.name == "" {
      issues.push(
        validation_issue("empty-gauge-name", "gauge name should be non-empty"),
      )
    }
  }
  for sample in metrics.sample_snapshot() {
    if sample.name == "" {
      issues.push(
        validation_issue("empty-sample-name", "sample name should be non-empty"),
      )
    }
  }
  { subject: "metrics", issues }
}

///|
pub fn Sim::validate(self : Sim) -> ValidationReport {
  validate_sim(self)
}
