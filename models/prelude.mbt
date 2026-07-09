///|
pub type Sim = @core.Sim

///|
pub type TraceEntry = @core.TraceEntry

///|
pub type InvariantCheck = @core.InvariantCheck

///|
pub type InvariantReport = @core.InvariantReport

///|
pub type ValidationIssue = @core.ValidationIssue

///|
pub type ValidationReport = @core.ValidationReport

///|
pub type Backoff = @core.Backoff

///|
pub type TimerPlan = @core.TimerPlan

///|
pub type MessageBus = @core.MessageBus

///|
pub fn trace_entry(
  tick : Int,
  event_id : Int,
  kind : String,
  detail : String,
) -> TraceEntry {
  @core.trace_entry(tick, event_id, kind, detail)
}

///|
pub fn trace_digest(entries : Array[TraceEntry]) -> UInt64 {
  @core.trace_digest(entries)
}

///|
pub fn timer_plan(
  name : String,
  start_after? : Int = 0,
  interval? : Int = 1,
  times? : Int = 1,
  priority? : Int = 0,
) -> TimerPlan {
  @core.timer_plan(name, start_after~, interval~, times~, priority~)
}

///|
pub fn validation_issue(
  code : String,
  message : String,
  severity? : String = "error",
) -> ValidationIssue {
  @core.validation_issue(code, message, severity~)
}

///|
pub fn check_sim_invariants(sim : Sim) -> InvariantReport {
  @core.check_sim_invariants(sim)
}

///|
pub fn invariant_check(
  name : String,
  passed : Bool,
  detail? : String = "",
) -> InvariantCheck {
  @core.invariant_check(name, passed, detail~)
}

///|
pub fn version() -> String {
  @core.version()
}
