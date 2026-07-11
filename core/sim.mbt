///|
/// Deterministic simulation state.
pub(all) struct Sim {
  mut now : Int
  mut next_id : Int
  mut events : Array[ScheduledEvent]
  mut trace_entries : Array[TraceEntry]
  rng : Rng
  metrics : Metrics
}

///|
pub(all) enum RunStep {
  Executed(ScheduledEvent)
  Idle
}

///|
pub(all) enum RunStopReason {
  Idle
  StepLimit
  TickLimit
}

///|
pub(all) struct RunReport {
  steps : Int
  final_tick : Int
  pending : Int
  reason : RunStopReason
}

///|
pub fn Sim::new(seed? : UInt64 = 1UL) -> Sim {
  {
    now: 0,
    next_id: 1,
    events: [],
    trace_entries: [],
    rng: Rng::new(seed),
    metrics: Metrics::new(),
  }
}

///|
pub fn Sim::time(self : Sim) -> Int {
  self.now
}

///|
pub fn Sim::tick(self : Sim) -> Tick {
  tick(self.now)
}

///|
pub fn Sim::pending_count(self : Sim) -> Int {
  self.events.length()
}

///|
pub fn Sim::schedule_at_tick(
  self : Sim,
  at : Tick,
  name : String,
  priority? : Int = 0,
) -> EventId {
  event_id(self.schedule_at(at.to_int(), name, priority~))
}

///|
pub fn Sim::schedule_at(
  self : Sim,
  tick : Int,
  name : String,
  priority? : Int = 0,
) -> Int {
  let scheduled_tick = if tick < self.now { self.now } else { tick }
  let id = self.next_id
  self.next_id += 1
  self.push_event(ScheduledEvent::new(id, scheduled_tick, name, priority~))
  self.record(id, "schedule", name)
  id
}

///|
pub fn Sim::schedule_after_duration(
  self : Sim,
  delay : Duration,
  name : String,
  priority? : Int = 0,
) -> EventId {
  event_id(self.schedule_after(delay.to_int(), name, priority~))
}

///|
pub fn Sim::schedule_after(
  self : Sim,
  delay : Int,
  name : String,
  priority? : Int = 0,
) -> Int {
  let normalized_delay = if delay < 0 { 0 } else { delay }
  self.schedule_at(self.now + normalized_delay, name, priority~)
}

///|
pub fn Sim::schedule_repeating(
  self : Sim,
  start_after : Int,
  every : Int,
  times : Int,
  name : String,
  priority? : Int = 0,
) -> Int {
  let start = self.now + (if start_after < 0 { 0 } else { start_after })
  let id = self.next_id
  self.next_id += 1
  self.push_event(
    ScheduledEvent::repeating(id, start, name, every, times, priority~),
  )
  self.record(id, "schedule.repeat", name)
  id
}

///|
pub fn Sim::cancel(self : Sim, event_id : Int) -> Bool {
  let mut i = 0
  while i < self.events.length() {
    if self.events[i].id == event_id && !self.events[i].cancelled {
      let event = self.events.remove(i)
      self.rebuild_event_heap()
      self.record(event_id, "cancel", event.name)
      return true
    }
    i += 1
  }
  false
}

///|
pub fn Sim::run_next(self : Sim) -> ScheduledEvent? {
  match self.pop_next_event() {
    None => None
    Some(event) => {
      self.now = event.tick
      self.record(event.id, "execute", event.name)
      self.metrics.inc("events_executed")
      if event.is_repeating() {
        let next = event.next_repeat()
        self.push_event(next)
        self.record(next.id, "reschedule.repeat", next.name)
      }
      Some(event)
    }
  }
}

///|
pub fn Sim::step(self : Sim) -> RunStep {
  match self.run_next() {
    Some(event) => Executed(event)
    None => Idle
  }
}

///|
pub fn Sim::run_until_idle(self : Sim, max_steps? : Int = 100000) -> Int {
  let mut steps = 0
  while steps < max_steps {
    match self.run_next() {
      None => return steps
      Some(_) => steps += 1
    }
  }
  steps
}

///|
pub fn Sim::run_report_until_idle(
  self : Sim,
  max_steps? : Int = 100000,
) -> RunReport {
  let steps = self.run_until_idle(max_steps~)
  {
    steps,
    final_tick: self.now,
    pending: self.pending_count(),
    reason: if self.pending_count() == 0 {
      RunStopReason::Idle
    } else {
      StepLimit
    },
  }
}

///|
pub fn Sim::run_until_tick(
  self : Sim,
  tick_limit : Int,
  max_steps? : Int = 100000,
) -> RunReport {
  let mut steps = 0
  while steps < max_steps {
    match self.peek_next_event() {
      None =>
        return {
          steps,
          final_tick: self.now,
          pending: self.pending_count(),
          reason: RunStopReason::Idle,
        }
      Some(event) =>
        if event.tick > tick_limit {
          return {
            steps,
            final_tick: self.now,
            pending: self.pending_count(),
            reason: RunStopReason::TickLimit,
          }
        } else {
          ignore(self.run_next())
          steps += 1
        }
    }
  }
  {
    steps,
    final_tick: self.now,
    pending: self.pending_count(),
    reason: StepLimit,
  }
}

///|
pub fn Sim::next_int(self : Sim, bound : Int) -> Int {
  let value = self.rng.next_int(bound)
  self.record(0, "rng.int", value.to_string())
  value
}

///|
pub fn Sim::next_range(self : Sim, low : Int, high : Int) -> Int {
  let value = self.rng.next_range(low, high)
  self.record(
    0,
    "rng.range",
    low.to_string() + ".." + high.to_string() + "=" + value.to_string(),
  )
  value
}

///|
pub fn[T] Sim::choose(self : Sim, label : String, items : Array[T]) -> T? {
  let index = if items.length() == 0 {
    -1
  } else {
    self.rng.next_int(items.length())
  }
  self.record(0, "rng.choose", label + "=" + index.to_string())
  if index < 0 {
    None
  } else {
    Some(items[index])
  }
}

///|
pub fn[T] Sim::shuffle(
  self : Sim,
  label : String,
  items : Array[T],
) -> Array[T] {
  let result = self.rng.shuffle(items)
  self.record(0, "rng.shuffle", label + "#" + items.length().to_string())
  result
}

///|
pub fn Sim::choose_weighted(
  self : Sim,
  label : String,
  choices : Array[WeightedChoice],
) -> String? {
  let value = self.rng.choose_weighted(choices)
  match value {
    None => self.record(0, "rng.weighted", label + "=None")
    Some(v) => self.record(0, "rng.weighted", label + "=" + v)
  }
  value
}

///|
pub fn Sim::trace(self : Sim) -> Array[TraceEntry] {
  self.trace_entries.copy()
}

///|
pub fn Sim::trace_text(self : Sim) -> String {
  trace_to_text(self.trace_entries)
}

///|
pub fn Sim::digest(self : Sim) -> UInt64 {
  trace_digest(self.trace_entries)
}

///|
pub fn Sim::metrics(self : Sim) -> Metrics {
  self.metrics
}

///|
pub fn Sim::inc_counter(self : Sim, name : String, delta? : Int = 1) -> Unit {
  self.metrics.inc(name, delta~)
  self.record(0, "metric.counter", name + "+=" + delta.to_string())
}

///|
pub fn Sim::set_gauge(self : Sim, name : String, value : Int) -> Unit {
  self.metrics.set_gauge(name, value)
  self.record(0, "metric.gauge", name + "=" + value.to_string())
}

///|
pub fn Sim::sample(self : Sim, name : String, value : Int) -> Unit {
  self.metrics.sample(name, value)
  self.record(0, "metric.sample", name + "=" + value.to_string())
}

///|
pub fn Sim::record(
  self : Sim,
  event_id : Int,
  kind : String,
  detail : String,
) -> Unit {
  self.trace_entries.push(trace_entry(self.now, event_id, kind, detail))
}

///|
fn Sim::push_event(self : Sim, event : ScheduledEvent) -> Unit {
  self.events.push(event)
  let mut index = self.events.length() - 1
  let mut bubbling = true
  while index > 0 && bubbling {
    let parent = (index - 1) / 2
    if compare_event(self.events[index], self.events[parent]) < 0 {
      let current = self.events[index]
      self.events[index] = self.events[parent]
      self.events[parent] = current
      index = parent
    } else {
      bubbling = false
    }
  }
}

///|
/// Removes the heap root without observing cancellation. Cancellation remains
/// a stable marker so snapshots preserve both pending work and cancel state.
fn Sim::pop_heap_root(self : Sim) -> ScheduledEvent? {
  if self.events.length() == 0 {
    return None
  }
  let root = self.events[0]
  let last = self.events.remove(self.events.length() - 1)
  if self.events.length() > 0 {
    self.events[0] = last
    let mut index = 0
    let mut settling = true
    while settling {
      let left = index * 2 + 1
      if left >= self.events.length() {
        settling = false
      } else {
        let right = left + 1
        let child = if right < self.events.length() &&
          compare_event(self.events[right], self.events[left]) < 0 {
          right
        } else {
          left
        }
        if compare_event(self.events[child], self.events[index]) < 0 {
          let current = self.events[index]
          self.events[index] = self.events[child]
          self.events[child] = current
          index = child
        } else {
          settling = false
        }
      }
    }
  }
  Some(root)
}

///|
fn Sim::peek_next_event(self : Sim) -> ScheduledEvent? {
  if self.events.length() == 0 {
    None
  } else {
    Some(self.events[0])
  }
}

///|
fn Sim::pop_next_event(self : Sim) -> ScheduledEvent? {
  match self.peek_next_event() {
    None => None
    Some(_) => self.pop_heap_root()
  }
}

///|
fn Sim::rebuild_event_heap(self : Sim) -> Unit {
  let mut parent = self.events.length() / 2
  while parent > 0 {
    parent -= 1
    self.sift_down_event(parent)
  }
}

///|
fn Sim::sift_down_event(self : Sim, start : Int) -> Unit {
  let mut index = start
  let mut settling = true
  while settling {
    let left = index * 2 + 1
    if left >= self.events.length() {
      settling = false
    } else {
      let right = left + 1
      let mut child = left
      if right < self.events.length() &&
        compare_event(self.events[right], self.events[left]) < 0 {
        child = right
      }
      if compare_event(self.events[child], self.events[index]) < 0 {
        let current = self.events[index]
        self.events[index] = self.events[child]
        self.events[child] = current
        index = child
      } else {
        settling = false
      }
    }
  }
}
