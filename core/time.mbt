///|
/// Virtual simulation tick.
pub(all) struct Tick {
  value : Int
} derive(Eq, Debug)

///|
/// Virtual simulation duration.
pub(all) struct Duration {
  value : Int
} derive(Eq, Debug)

///|
/// Stable simulation event identifier.
pub(all) struct EventId {
  value : Int
} derive(Eq, Debug)

///|
pub fn tick(value : Int) -> Tick {
  { value: if value < 0 { 0 } else { value } }
}

///|
pub fn duration(value : Int) -> Duration {
  { value: if value < 0 { 0 } else { value } }
}

///|
pub fn event_id(value : Int) -> EventId {
  { value, }
}

///|
pub fn Tick::to_int(self : Tick) -> Int {
  self.value
}

///|
pub fn Duration::to_int(self : Duration) -> Int {
  self.value
}

///|
pub fn EventId::to_int(self : EventId) -> Int {
  self.value
}

///|
pub fn Tick::plus(self : Tick, delta : Duration) -> Tick {
  tick(self.value + delta.value)
}

///|
pub fn Tick::diff(self : Tick, earlier : Tick) -> Duration {
  duration(self.value - earlier.value)
}

///|
pub fn Tick::compare(self : Tick, other : Tick) -> Int {
  self.value.compare(other.value)
}

///|
pub fn Duration::is_zero(self : Duration) -> Bool {
  self.value == 0
}

///|
pub fn Duration::scale(self : Duration, factor : Int) -> Duration {
  duration(self.value * factor)
}
