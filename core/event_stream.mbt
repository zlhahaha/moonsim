///|
/// Built-in event categories for deterministic model traces.
pub enum EventKind {
  Message
  Task
  Timer
  StateTransition
  ExternalCall
}

///|
pub fn EventKind::label(self : EventKind) -> String {
  match self {
    Message => "message"
    Task => "task"
    Timer => "timer"
    StateTransition => "state_transition"
    ExternalCall => "external_call"
  }
}

///|
pub fn message_event_kind() -> EventKind {
  Message
}

///|
pub fn task_event_kind() -> EventKind {
  Task
}

///|
pub fn timer_event_kind() -> EventKind {
  Timer
}

///|
pub fn state_transition_event_kind() -> EventKind {
  StateTransition
}

///|
pub fn external_call_event_kind() -> EventKind {
  ExternalCall
}

///|
pub(all) struct EventRecord {
  id : Int
  kind : EventKind
  tick : Int
  priority : Int
  correlation_id : String
  source : String
  target : String
  label : String
  parent_id : Int
  payload : String
  dropped : Bool
  failed : Bool
}

///|
pub fn event_record(
  kind : EventKind,
  tick : Int,
  label : String,
  correlation_id? : String = "",
  source? : String = "",
  target? : String = "",
  parent_id? : Int = 0,
  payload? : String = "",
  priority? : Int = 0,
  dropped? : Bool = false,
  failed? : Bool = false,
) -> EventRecord {
  {
    id: 0,
    kind,
    tick,
    priority,
    correlation_id,
    source,
    target,
    label,
    parent_id,
    payload,
    dropped,
    failed,
  }
}

///|
pub(all) struct EventMutationPolicy {
  seed : UInt64
  max_delay : Int
  delay_percent : Int
  drop_percent : Int
  duplicate_percent : Int
  reorder_same_tick : Bool
  failure_percent : Int
}

///|
pub fn event_mutation_policy(
  seed? : UInt64 = 1UL,
  max_delay? : Int = 0,
  delay_percent? : Int = 0,
  drop_percent? : Int = 0,
  duplicate_percent? : Int = 0,
  reorder_same_tick? : Bool = false,
  failure_percent? : Int = 0,
) -> EventMutationPolicy {
  {
    seed,
    max_delay: if max_delay < 0 {
      0
    } else {
      max_delay
    },
    delay_percent: event_percent(delay_percent),
    drop_percent: event_percent(drop_percent),
    duplicate_percent: event_percent(duplicate_percent),
    reorder_same_tick,
    failure_percent: event_percent(failure_percent),
  }
}

///|
pub(all) struct EventStreamSnapshot {
  next_id : Int
  events : Array[EventRecord]
}

///|
pub(all) struct EventReplayResult {
  seed : UInt64
  digest : UInt64
  events : Array[EventRecord]
  scheduled : Int
  dropped : Int
  duplicated : Int
  failed : Int
}

///|
pub(all) struct EventFailureCase {
  seed : UInt64
  rule : String
  digest : UInt64
  events : Array[EventRecord]
  policy : EventMutationPolicy
  source_events : Array[EventRecord]
}

///|
pub(all) struct EventStream {
  mut next_id : Int
  mut events : Array[EventRecord]
}

///|
pub fn EventStream::new() -> EventStream {
  { next_id: 1, events: [] }
}

///|
pub fn EventStream::append(
  self : EventStream,
  event : EventRecord,
) -> EventRecord {
  let id = if event.id <= 0 { self.next_id } else { event.id }
  if id >= self.next_id {
    self.next_id = id + 1
  }
  let stored = {
    id,
    kind: event.kind,
    tick: event.tick,
    priority: event.priority,
    correlation_id: event.correlation_id,
    source: event.source,
    target: event.target,
    label: event.label,
    parent_id: event.parent_id,
    payload: event.payload,
    dropped: event.dropped,
    failed: event.failed,
  }
  self.events.push(stored)
  stored
}

///|
pub fn EventStream::record(
  self : EventStream,
  kind : EventKind,
  tick : Int,
  label : String,
  correlation_id? : String = "",
  source? : String = "",
  target? : String = "",
  parent_id? : Int = 0,
  payload? : String = "",
  priority? : Int = 0,
  dropped? : Bool = false,
  failed? : Bool = false,
) -> EventRecord {
  self.append(
    event_record(
      kind,
      tick,
      label,
      correlation_id~,
      source~,
      target~,
      parent_id~,
      payload~,
      priority~,
      dropped~,
      failed~,
    ),
  )
}

///|
pub fn EventStream::events(self : EventStream) -> Array[EventRecord] {
  self.events.copy()
}

///|
pub fn EventStream::ordered(self : EventStream) -> Array[EventRecord] {
  let ordered = self.events.copy()
  ordered.sort_by(fn(left, right) {
    if left.tick != right.tick {
      left.tick.compare(right.tick)
    } else if left.priority != right.priority {
      left.priority.compare(right.priority)
    } else {
      left.id.compare(right.id)
    }
  })
  ordered
}

///|
pub fn EventStream::snapshot(self : EventStream) -> EventStreamSnapshot {
  { next_id: self.next_id, events: self.events.copy() }
}

///|
pub fn EventStream::restore(
  self : EventStream,
  snapshot : EventStreamSnapshot,
) -> Unit {
  self.next_id = snapshot.next_id
  self.events = snapshot.events.copy()
}

///|
pub fn EventStream::digest(self : EventStream) -> UInt64 {
  event_records_digest(self.ordered())
}

///|
pub fn EventStream::invariants(self : EventStream) -> InvariantReport {
  event_records_invariants(self.ordered())
}

///|
pub fn EventStream::replay(
  self : EventStream,
  policy : EventMutationPolicy,
) -> EventReplayResult {
  let rng = Rng::new(policy.seed)
  let replayed = EventStream::new()
  let mut dropped = 0
  let mut duplicated = 0
  let mut failed = 0
  for event in self.ordered() {
    let delay = if policy.max_delay > 0 && event_roll(rng, policy.delay_percent) {
      rng.next_int(policy.max_delay + 1)
    } else {
      0
    }
    let is_dropped = event.dropped || event_roll(rng, policy.drop_percent)
    let is_failed = event.failed || event_roll(rng, policy.failure_percent)
    let priority = if policy.reorder_same_tick {
      -event.priority - event.id
    } else {
      event.priority
    }
    let replay_event = {
      id: event.id,
      kind: event.kind,
      tick: event.tick + delay,
      priority,
      correlation_id: event.correlation_id,
      source: event.source,
      target: event.target,
      label: event.label,
      parent_id: event.parent_id,
      payload: event.payload,
      dropped: is_dropped,
      failed: is_failed,
    }
    ignore(replayed.append(replay_event))
    if is_dropped {
      dropped += 1
    }
    if is_failed {
      failed += 1
    }
    if event_roll(rng, policy.duplicate_percent) {
      ignore(
        replayed.record(
          event.kind,
          event.tick + delay,
          event.label + ".duplicate",
          correlation_id=event.correlation_id,
          source=event.source,
          target=event.target,
          parent_id=event.id,
          payload=event.payload,
          priority~,
          dropped=is_dropped,
          failed=is_failed,
        ),
      )
      duplicated += 1
    }
  }
  let events = replayed.ordered()
  {
    seed: policy.seed,
    digest: event_records_digest(events),
    scheduled: events.length(),
    events,
    dropped,
    duplicated,
    failed,
  }
}

///|
pub fn EventReplayResult::invariants(
  self : EventReplayResult,
) -> InvariantReport {
  event_records_invariants(self.events)
}

///|
pub fn EventReplayResult::matches_digest(
  self : EventReplayResult,
  other : EventReplayResult,
) -> Bool {
  self.digest == other.digest
}

///|
pub fn event_failure_case(
  rule : String,
  source : EventStream,
  policy : EventMutationPolicy,
) -> EventFailureCase {
  let replay = source.replay(policy)
  {
    seed: replay.seed,
    rule,
    digest: replay.digest,
    events: replay.events,
    policy,
    source_events: source.events(),
  }
}

///|
pub fn EventFailureCase::replay(self : EventFailureCase) -> EventReplayResult {
  let stream = EventStream::new()
  for event in self.source_events {
    ignore(stream.append(event))
  }
  stream.replay(self.policy)
}

///|
fn event_percent(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 100 {
    100
  } else {
    value
  }
}

///|
fn event_roll(rng : Rng, percent : Int) -> Bool {
  percent > 0 && rng.next_int(100) < percent
}

///|
fn event_records_digest(events : Array[EventRecord]) -> UInt64 {
  let entries : Array[TraceEntry] = []
  for event in events {
    entries.push(
      trace_entry(
        event.tick,
        event.id,
        event.kind.label(),
        event.correlation_id +
        "|" +
        event.source +
        "|" +
        event.target +
        "|" +
        event.label +
        "|" +
        event.parent_id.to_string() +
        "|" +
        event.payload +
        "|" +
        event.dropped.to_string() +
        "|" +
        event.failed.to_string(),
      ),
    )
  }
  trace_digest(entries)
}

///|
fn event_records_invariants(events : Array[EventRecord]) -> InvariantReport {
  let report = InvariantReport::new("event-stream")
  let ids : Array[Int] = []
  let mut unique_ids = true
  let mut parent_exists = true
  let mut causal_tick_order = true
  for event in events {
    for known_id in ids {
      if known_id == event.id {
        unique_ids = false
      }
    }
    if event.parent_id > 0 {
      let mut found_parent = false
      for parent in events {
        if parent.id == event.parent_id {
          found_parent = true
          if parent.tick > event.tick {
            causal_tick_order = false
          }
        }
      }
      if !found_parent {
        parent_exists = false
      }
    }
    ids.push(event.id)
  }
  ignore(report.add(invariant_check("event_id_unique", unique_ids)))
  ignore(report.add(invariant_check("causal_parent_exists", parent_exists)))
  ignore(report.add(invariant_check("causal_tick_order", causal_tick_order)))
  report
}
