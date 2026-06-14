///|
/// Deterministic simulation state.
pub(all) struct Sim {
  mut now : Int
  mut next_id : Int
  mut events : Array[ScheduledEvent]
  rng : Rng
}

///|
pub fn Sim::new(seed? : UInt64 = 1UL) -> Sim {
  { now: 0, next_id: 1, events: [], rng: Rng::new(seed) }
}

///|
pub fn Sim::time(self : Sim) -> Int {
  self.now
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
  id
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
pub fn Sim::run_next(self : Sim) -> ScheduledEvent? {
  let index = self.next_event_index()
  match index {
    None => None
    Some(i) => {
      let event = self.events.remove(i)
      self.now = event.tick
      Some(event)
    }
  }
}

///|
pub fn Sim::next_int(self : Sim, bound : Int) -> Int {
  self.rng.next_int(bound)
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
