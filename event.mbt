///|
/// A scheduled simulation event.
///
/// Events are ordered by tick, priority, then id. The id tie-breaker makes
/// same-tick execution stable and replayable.
pub(all) struct ScheduledEvent {
  id : Int
  tick : Int
  priority : Int
  name : String
  mut cancelled : Bool
  repeat_every : Int
  remaining_runs : Int
}

///|
pub fn ScheduledEvent::new(
  id : Int,
  tick : Int,
  name : String,
  priority? : Int = 0
) -> ScheduledEvent {
  {
    id,
    tick,
    priority,
    name,
    cancelled: false,
    repeat_every: 0,
    remaining_runs: 1,
  }
}

///|
pub fn ScheduledEvent::repeating(
  id : Int,
  tick : Int,
  name : String,
  every : Int,
  times : Int,
  priority? : Int = 0
) -> ScheduledEvent {
  {
    id,
    tick,
    priority,
    name,
    cancelled: false,
    repeat_every: if every < 1 { 1 } else { every },
    remaining_runs: if times < 1 { 1 } else { times },
  }
}

///|
pub fn ScheduledEvent::is_cancelled(self : ScheduledEvent) -> Bool {
  self.cancelled
}

///|
pub fn ScheduledEvent::cancel(self : ScheduledEvent) -> Unit {
  self.cancelled = true
}

///|
pub fn ScheduledEvent::is_repeating(self : ScheduledEvent) -> Bool {
  self.repeat_every > 0 && self.remaining_runs > 1
}

///|
pub fn ScheduledEvent::next_repeat(self : ScheduledEvent) -> ScheduledEvent {
  {
    id: self.id,
    tick: self.tick + self.repeat_every,
    priority: self.priority,
    name: self.name,
    cancelled: false,
    repeat_every: self.repeat_every,
    remaining_runs: self.remaining_runs - 1,
  }
}

///|
pub fn compare_event(a : ScheduledEvent, b : ScheduledEvent) -> Int {
  let tick_order = a.tick.compare(b.tick)
  if tick_order != 0 {
    tick_order
  } else {
    let priority_order = a.priority.compare(b.priority)
    if priority_order != 0 {
      priority_order
    } else {
      a.id.compare(b.id)
    }
  }
}
