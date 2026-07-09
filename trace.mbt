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
pub(all) struct TraceQuery {
  kind : String
  detail : String
  min_tick : Int
  max_tick : Int
}

///|
pub(all) struct TraceKindCount {
  kind : String
  count : Int
}

///|
pub(all) struct TraceQueryResult {
  entries : Array[TraceEntry]
  first_tick : Int
  last_tick : Int
  kind_counts : Array[TraceKindCount]
}

///|
pub(all) struct TraceExpectation {
  passed : Bool
  label : String
  expected : String
  actual : String
}

///|
pub(all) struct ReplayBaseline {
  name : String
  digest : UInt64
  entries : Array[TraceEntry]
  counters : Array[CounterSample]
  gauges : Array[CounterSample]
}

///|
pub(all) struct ReplayComparison {
  name : String
  matched : Bool
  trace : TraceComparison
  counter_mismatches : Int
  gauge_mismatches : Int
}

///|
pub fn trace_entry(
  tick : Int,
  event_id : Int,
  kind : String,
  detail : String,
) -> TraceEntry {
  { tick, event_id, kind, detail }
}

///|
pub fn TraceEntry::format(self : TraceEntry) -> String {
  "tick=" +
  self.tick.to_string() +
  " event=" +
  self.event_id.to_string() +
  " kind=" +
  self.kind +
  " detail=" +
  self.detail
}

///|
pub fn TraceEntry::to_line(self : TraceEntry) -> String {
  self.tick.to_string() +
  "|" +
  self.event_id.to_string() +
  "|" +
  self.kind +
  "|" +
  self.detail
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
pub fn trace_query(
  kind? : String = "",
  detail? : String = "",
  min_tick? : Int = -1,
  max_tick? : Int = -1,
) -> TraceQuery {
  { kind, detail, min_tick, max_tick }
}

///|
pub fn TraceQuery::matches(self : TraceQuery, entry : TraceEntry) -> Bool {
  if self.kind != "" && entry.kind != self.kind {
    false
  } else if self.detail != "" && !entry.detail.contains(self.detail) {
    false
  } else if self.min_tick >= 0 && entry.tick < self.min_tick {
    false
  } else if self.max_tick >= 0 && entry.tick > self.max_tick {
    false
  } else {
    true
  }
}

///|
pub fn query_trace(
  entries : Array[TraceEntry],
  query : TraceQuery,
) -> TraceQueryResult {
  let result : Array[TraceEntry] = []
  for entry in entries {
    if query.matches(entry) {
      result.push(entry)
    }
  }
  trace_query_result(result)
}

///|
pub fn trace_filter_kind(
  entries : Array[TraceEntry],
  kind : String,
) -> Array[TraceEntry] {
  query_trace(entries, trace_query(kind~)).entries
}

///|
pub fn trace_filter_detail(
  entries : Array[TraceEntry],
  detail : String,
) -> Array[TraceEntry] {
  query_trace(entries, trace_query(detail~)).entries
}

///|
pub fn trace_filter_tick_range(
  entries : Array[TraceEntry],
  min_tick : Int,
  max_tick : Int,
) -> Array[TraceEntry] {
  query_trace(entries, trace_query(min_tick~, max_tick~)).entries
}

///|
pub fn trace_query_result(entries : Array[TraceEntry]) -> TraceQueryResult {
  let mut first = 0
  let mut last = 0
  let mut seen = false
  let counts : Array[TraceKindCount] = []
  for entry in entries {
    if !seen {
      first = entry.tick
      last = entry.tick
      seen = true
    } else {
      if entry.tick < first {
        first = entry.tick
      }
      if entry.tick > last {
        last = entry.tick
      }
    }
    add_trace_kind_count(counts, entry.kind)
  }
  { entries, first_tick: first, last_tick: last, kind_counts: counts }
}

///|
fn add_trace_kind_count(counts : Array[TraceKindCount], kind : String) -> Unit {
  let mut i = 0
  while i < counts.length() {
    if counts[i].kind == kind {
      counts[i] = { kind, count: counts[i].count + 1 }
      return
    }
    i += 1
  }
  counts.push({ kind, count: 1 })
}

///|
pub fn TraceQueryResult::kind_count(
  self : TraceQueryResult,
  kind : String,
) -> Int {
  for item in self.kind_counts {
    if item.kind == kind {
      return item.count
    }
  }
  0
}

///|
pub fn TraceQueryResult::summary(self : TraceQueryResult) -> String {
  "entries=" +
  self.entries.length().to_string() +
  " first_tick=" +
  self.first_tick.to_string() +
  " last_tick=" +
  self.last_tick.to_string()
}

///|
pub fn expect_trace_kind_count(
  entries : Array[TraceEntry],
  kind : String,
  expected : Int,
) -> TraceExpectation {
  let actual = trace_query_result(entries).kind_count(kind)
  {
    passed: actual == expected,
    label: "kind_count:" + kind,
    expected: expected.to_string(),
    actual: actual.to_string(),
  }
}

///|
pub fn expect_trace_contains_kind(
  entries : Array[TraceEntry],
  kind : String,
) -> TraceExpectation {
  let count = trace_query_result(entries).kind_count(kind)
  {
    passed: count > 0,
    label: "contains_kind:" + kind,
    expected: "present",
    actual: if count > 0 {
      "present"
    } else {
      "missing"
    },
  }
}

///|
pub fn expect_trace_contains_detail(
  entries : Array[TraceEntry],
  detail : String,
) -> TraceExpectation {
  let found = trace_filter_detail(entries, detail).length() > 0
  {
    passed: found,
    label: "contains_detail",
    expected: detail,
    actual: if found {
      detail
    } else {
      ""
    },
  }
}

///|
pub fn expect_trace_order(
  entries : Array[TraceEntry],
  before_detail : String,
  after_detail : String,
) -> TraceExpectation {
  let before = trace_first_detail_index(entries, before_detail)
  let after = trace_first_detail_index(entries, after_detail)
  let passed = before >= 0 && after >= 0 && before < after
  {
    passed,
    label: "order",
    expected: before_detail + " before " + after_detail,
    actual: before.to_string() + " before " + after.to_string(),
  }
}

///|
fn trace_first_detail_index(
  entries : Array[TraceEntry],
  detail : String,
) -> Int {
  for i in 0..<entries.length() {
    if entries[i].detail.contains(detail) {
      return i
    }
  }
  -1
}

///|
pub fn expect_trace_monotonic_ticks(
  entries : Array[TraceEntry],
) -> TraceExpectation {
  let mut last = 0
  let mut seen = false
  for entry in entries {
    if seen && entry.tick < last {
      return {
        passed: false,
        label: "monotonic_ticks",
        expected: "nondecreasing",
        actual: entry.tick.to_string() + " after " + last.to_string(),
      }
    }
    last = entry.tick
    seen = true
  }
  {
    passed: true,
    label: "monotonic_ticks",
    expected: "nondecreasing",
    actual: "nondecreasing",
  }
}

///|
pub fn expect_trace_digest(
  entries : Array[TraceEntry],
  digest : UInt64,
) -> TraceExpectation {
  let actual = trace_digest(entries)
  {
    passed: actual == digest,
    label: "digest",
    expected: digest.to_string(),
    actual: actual.to_string(),
  }
}

///|
pub fn compare_traces(
  left : Array[TraceEntry],
  right : Array[TraceEntry],
) -> TraceComparison {
  let limit = if left.length() < right.length() {
    left.length()
  } else {
    right.length()
  }
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
pub fn replay_baseline(name : String, sim : Sim) -> ReplayBaseline {
  {
    name,
    digest: sim.digest(),
    entries: sim.trace(),
    counters: sim.metrics().snapshot(),
    gauges: sim.metrics().gauge_snapshot(),
  }
}

///|
pub fn compare_replay(baseline : ReplayBaseline, sim : Sim) -> ReplayComparison {
  let trace = compare_traces(baseline.entries, sim.trace())
  let counter_mismatches = compare_counter_samples(
    baseline.counters,
    sim.metrics().snapshot(),
  )
  let gauge_mismatches = compare_counter_samples(
    baseline.gauges,
    sim.metrics().gauge_snapshot(),
  )
  {
    name: baseline.name,
    matched: trace.matched && counter_mismatches == 0 && gauge_mismatches == 0,
    trace,
    counter_mismatches,
    gauge_mismatches,
  }
}

///|
fn compare_counter_samples(
  left : Array[CounterSample],
  right : Array[CounterSample],
) -> Int {
  let mut mismatches = 0
  for item in left {
    if find_counter_sample(right, item.name) != item.value {
      mismatches += 1
    }
  }
  for item in right {
    if !has_counter_sample(left, item.name) {
      mismatches += 1
    }
  }
  mismatches
}

///|
fn find_counter_sample(items : Array[CounterSample], name : String) -> Int {
  for item in items {
    if item.name == name {
      return item.value
    }
  }
  0
}

///|
fn has_counter_sample(items : Array[CounterSample], name : String) -> Bool {
  for item in items {
    if item.name == name {
      return true
    }
  }
  false
}

///|
pub fn ReplayComparison::summary(self : ReplayComparison) -> String {
  let status = if self.matched { "matched" } else { "mismatch" }
  status +
  " " +
  self.name +
  " trace=" +
  self.trace.summary() +
  " counters=" +
  self.counter_mismatches.to_string() +
  " gauges=" +
  self.gauge_mismatches.to_string()
}

///|
pub fn TraceComparison::summary(self : TraceComparison) -> String {
  if self.matched {
    "matched checked=" +
    self.checked.to_string() +
    " digest=" +
    self.left_digest.to_string()
  } else {
    match self.mismatch {
      None => "mismatch"
      Some(m) =>
        "mismatch index=" +
        m.index.to_string() +
        " reason=" +
        m.reason +
        " left=[" +
        m.left +
        "] right=[" +
        m.right +
        "]"
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
