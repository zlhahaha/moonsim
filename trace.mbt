///|
/// A deterministic record of an action observed during a simulation run.
pub(all) struct TraceEntry {
  tick : Int
  event_id : Int
  kind : String
  detail : String
}

///|
pub(all) struct TraceMismatch {
  index : Int
  left : String
  right : String
  reason : String
}

///|
pub(all) struct TraceComparison {
  matched : Bool
  checked : Int
  left_digest : UInt64
  right_digest : UInt64
  mismatch : TraceMismatch?
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
pub fn TraceEntry::to_line(self : TraceEntry) -> String {
  self.tick.to_string() + "|" + self.event_id.to_string() + "|" + self.kind + "|" + self.detail
}

///|
pub fn trace_to_text(entries : Array[TraceEntry]) -> String {
  let buf = StringBuilder::new()
  for i in 0..<entries.length() {
    if i > 0 {
      buf.write_string("\n")
    }
    buf.write_string(entries[i].to_line())
  }
  buf.to_string()
}

///|
pub fn compare_traces(left : Array[TraceEntry], right : Array[TraceEntry]) -> TraceComparison {
  let limit = if left.length() < right.length() { left.length() } else { right.length() }
  let mut i = 0
  while i < limit {
    let l = left[i].to_line()
    let r = right[i].to_line()
    if l != r {
      return {
        matched: false,
        checked: i,
        left_digest: trace_digest(left),
        right_digest: trace_digest(right),
        mismatch: Some({ index: i, left: l, right: r, reason: "entry differs" }),
      }
    }
    i += 1
  }
  if left.length() != right.length() {
    return {
      matched: false,
      checked: limit,
      left_digest: trace_digest(left),
      right_digest: trace_digest(right),
      mismatch: Some({
        index: limit,
        left: "len=" + left.length().to_string(),
        right: "len=" + right.length().to_string(),
        reason: "length differs",
      }),
    }
  }
  {
    matched: true,
    checked: limit,
    left_digest: trace_digest(left),
    right_digest: trace_digest(right),
    mismatch: None,
  }
}

///|
pub fn TraceComparison::summary(self : TraceComparison) -> String {
  if self.matched {
    "matched checked=" + self.checked.to_string() + " digest=" + self.left_digest.to_string()
  } else {
    match self.mismatch {
      None => "mismatch"
      Some(m) =>
        "mismatch index=" + m.index.to_string() + " reason=" + m.reason +
        " left=[" + m.left + "] right=[" + m.right + "]"
    }
  }
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
