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
  let mut count = 0
  for event in self.events {
    if !event.cancelled {
      count += 1
    }
  }
  count
}

///|
pub fn Sim::schedule_at_tick(
  self : Sim,
  at : Tick,
  name : String,
  priority? : Int = 0
) -> EventId {
  event_id(self.schedule_at(at.to_int(), name, priority~))
}

///|
pub fn Sim::schedule_at(
  self : Sim,
  tick : Int,
  name : String,
  priority? : Int = 0
) -> Int {
  let scheduled_tick = if tick < self.now { self.now } else { tick }
  let id = self.next_id
  self.next_id += 1
  self.events.push(ScheduledEvent::new(id, scheduled_tick, name, priority~))
  self.record(id, "schedule", name)
  id
}

///|
pub fn Sim::schedule_after_duration(
  self : Sim,
  delay : Duration,
  name : String,
  priority? : Int = 0
) -> EventId {
  event_id(self.schedule_after(delay.to_int(), name, priority~))
}

///|
pub fn Sim::schedule_after(
  self : Sim,
  delay : Int,
  name : String,
  priority? : Int = 0
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
  priority? : Int = 0
) -> Int {
  let start = self.now + (if start_after < 0 { 0 } else { start_after })
  let id = self.next_id
  self.next_id += 1
  self.events.push(ScheduledEvent::repeating(id, start, name, every, times, priority~))
  self.record(id, "schedule.repeat", name)
  id
}

///|
pub fn Sim::cancel(self : Sim, event_id : Int) -> Bool {
  let mut i = 0
  while i < self.events.length() {
    if self.events[i].id == event_id && !self.events[i].cancelled {
      self.events[i].cancel()
      self.record(event_id, "cancel", self.events[i].name)
      return true
    }
    i += 1
  }
  false
}

///|
pub fn Sim::run_next(self : Sim) -> ScheduledEvent? {
  let index = self.next_event_index()
  match index {
    None => None
    Some(i) => {
      let event = self.events.remove(i)
      self.now = event.tick
      self.record(event.id, "execute", event.name)
      self.metrics.inc("events_executed")
      if event.is_repeating() {
        let next = event.next_repeat()
        self.events.push(next)
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
pub fn Sim::run_report_until_idle(self : Sim, max_steps? : Int = 100000) -> RunReport {
  let steps = self.run_until_idle(max_steps~)
  {
    steps,
    final_tick: self.now,
    pending: self.pending_count(),
    reason: if self.pending_count() == 0 { RunStopReason::Idle } else { StepLimit },
  }
}

///|
pub fn Sim::run_until_tick(self : Sim, tick_limit : Int, max_steps? : Int = 100000) -> RunReport {
  let mut steps = 0
  while steps < max_steps {
    let index = self.next_event_index()
    match index {
      None =>
        return {
          steps,
          final_tick: self.now,
          pending: self.pending_count(),
          reason: RunStopReason::Idle,
        }
      Some(i) =>
        if self.events[i].tick > tick_limit {
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
  { steps, final_tick: self.now, pending: self.pending_count(), reason: StepLimit }
}

///|
pub fn Sim::next_int(self : Sim, bound : Int) -> Int {
  let value = self.rng.next_int(bound)
  self.record(0, "rng.int", value.to_string())
  value
}

///|
pub fn Sim::trace(self : Sim) -> Array[TraceEntry] {
  self.trace_entries.copy()
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
fn Sim::record(self : Sim, event_id : Int, kind : String, detail : String) -> Unit {
  self.trace_entries.push(trace_entry(self.now, event_id, kind, detail))
}

///|
fn Sim::next_event_index(self : Sim) -> Int? {
  let mut best : Int? = None
  let mut i = 0
  while i < self.events.length() {
    if !self.events[i].cancelled {
      match best {
        None => best = Some(i)
        Some(j) =>
          if compare_event(self.events[i], self.events[j]) < 0 {
            best = Some(i)
          }
      }
    }
    i += 1
  }
  best
}
