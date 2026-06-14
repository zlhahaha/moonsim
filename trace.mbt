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

///|
pub fn trace_digest(entries : Array[TraceEntry]) -> UInt64 {
  let mut hash = 14695981039346656037UL
  for entry in entries {
    hash = digest_int(hash, entry.tick)
    hash = digest_int(hash, entry.event_id)
    hash = digest_string(hash, entry.kind)
    hash = digest_string(hash, entry.detail)
  }
  hash
}

///|
fn digest_int(hash : UInt64, value : Int) -> UInt64 {
  (hash ^ value.to_uint64()) * 1099511628211UL
}

///|
fn digest_string(hash : UInt64, value : String) -> UInt64 {
  let mut h = hash
  for i in 0..<value.length() {
    h = (h ^ value.code_unit_at(i).to_int().to_uint64()) * 1099511628211UL
  }
  h
}
