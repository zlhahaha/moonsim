///|
pub fn version() -> String {
  @moonsim.version()
}

///|
pub fn sim(seed? : UInt64 = 1UL) -> @moonsim.Sim {
  @moonsim.Sim::new(seed~)
}

///|
pub fn tick(value : Int) -> @moonsim.Tick {
  @moonsim.tick(value)
}

///|
pub fn duration(value : Int) -> @moonsim.Duration {
  @moonsim.duration(value)
}

///|
pub fn event_id(value : Int) -> @moonsim.EventId {
  @moonsim.event_id(value)
}

///|
pub fn rng(seed : UInt64) -> @moonsim.Rng {
  @moonsim.Rng::new(seed)
}

///|
pub fn trace_digest(entries : Array[@moonsim.TraceEntry]) -> UInt64 {
  @moonsim.trace_digest(entries)
}

///|
pub fn replay_baseline(
  name : String,
  sim : @moonsim.Sim,
) -> @moonsim.ReplayBaseline {
  @moonsim.replay_baseline(name, sim)
}

///|
pub fn compare_replay(
  baseline : @moonsim.ReplayBaseline,
  sim : @moonsim.Sim,
) -> @moonsim.ReplayComparison {
  @moonsim.compare_replay(baseline, sim)
}

///|
pub fn invariant_check(
  name : String,
  passed : Bool,
  detail? : String = "",
) -> @moonsim.InvariantCheck {
  @moonsim.invariant_check(name, passed, detail~)
}

///|
pub fn check_no_pending(sim : @moonsim.Sim) -> @moonsim.InvariantCheck {
  @moonsim.check_no_pending(sim)
}

///|
pub fn check_sim_invariants(sim : @moonsim.Sim) -> @moonsim.InvariantReport {
  @moonsim.check_sim_invariants(sim)
}

///|
pub fn validate_sim(sim : @moonsim.Sim) -> @moonsim.ValidationReport {
  @moonsim.validate_sim(sim)
}

///|
pub fn validate_trace(
  entries : Array[@moonsim.TraceEntry],
) -> @moonsim.ValidationReport {
  @moonsim.validate_trace(entries)
}
