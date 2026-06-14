///|
pub(all) struct CounterSample {
  name : String
  value : Int
}

///|
pub(all) struct Metrics {
  mut counters : Array[CounterSample]
}

///|
pub fn Metrics::new() -> Metrics {
  { counters: [] }
}

///|
pub fn Metrics::inc(self : Metrics, name : String, delta? : Int = 1) -> Unit {
  let mut i = 0
  while i < self.counters.length() {
    if self.counters[i].name == name {
      self.counters[i] = {
        name,
        value: self.counters[i].value + delta,
      }
      return
    }
    i += 1
  }
  self.counters.push({ name, value: delta })
}

///|
pub fn Metrics::counter(self : Metrics, name : String) -> Int {
  for sample in self.counters {
    if sample.name == name {
      return sample.value
    }
  }
  0
}

///|
pub fn Metrics::snapshot(self : Metrics) -> Array[CounterSample] {
  self.counters.copy()
}
