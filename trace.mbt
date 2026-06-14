///|
/// A deterministic record of an action observed during a simulation run.
pub(all) struct TraceEntry {
  tick : Int
  event_id : Int
  kind : String
  detail : String
}

///|
pub fn trace_entry(
  tick : Int,
  event_id : Int,
  kind : String,
  detail : String
) -> TraceEntry {
  { tick, event_id, kind, detail }
}

///|
pub fn TraceEntry::format(self : TraceEntry) -> String {
  "tick=" + self.tick.to_string() + " event=" + self.event_id.to_string() +
  " kind=" + self.kind + " detail=" + self.detail
}
