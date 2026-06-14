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
}

///|
pub fn ScheduledEvent::new(
  id : Int,
  tick : Int,
  name : String,
  priority? : Int = 0
) -> ScheduledEvent {
  { id, tick, priority, name, cancelled: false }
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
