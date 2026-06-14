///|
pub(all) struct CounterSample {
  name : String
  value : Int
}

///|
pub(all) struct Metrics {
  mut counters : Array[CounterSample]
  mut gauges : Array[CounterSample]
  mut samples : Array[CounterSample]
}

///|
pub fn Metrics::new() -> Metrics {
  { counters: [], gauges: [], samples: [] }
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
pub fn Metrics::set_gauge(self : Metrics, name : String, value : Int) -> Unit {
  set_named_value(self.gauges, name, value)
}

///|
pub fn Metrics::gauge(self : Metrics, name : String) -> Int {
  get_named_value(self.gauges, name)
}

///|
pub fn Metrics::sample(self : Metrics, name : String, value : Int) -> Unit {
  self.samples.push({ name, value })
}

///|
pub fn Metrics::sample_count(self : Metrics, name : String) -> Int {
  let mut count = 0
  for sample in self.samples {
    if sample.name == name {
      count += 1
    }
  }
  count
}

///|
pub(all) struct SampleSummary {
  name : String
  count : Int
  min : Int
  max : Int
  sum : Int
}

///|
pub fn SampleSummary::average(self : SampleSummary) -> Double {
  if self.count == 0 {
    0.0
  } else {
    self.sum.to_double() / self.count.to_double()
  }
}

///|
pub fn Metrics::summary(self : Metrics, name : String) -> SampleSummary {
  let mut count = 0
  let mut min = 0
  let mut max = 0
  let mut sum = 0
  for sample in self.samples {
    if sample.name == name {
      if count == 0 {
        min = sample.value
        max = sample.value
      } else {
        if sample.value < min {
          min = sample.value
        }
        if sample.value > max {
          max = sample.value
        }
      }
      count += 1
      sum += sample.value
    }
  }
  { name, count, min, max, sum }
}

///|
pub fn Metrics::snapshot(self : Metrics) -> Array[CounterSample] {
  self.counters.copy()
}

///|
pub fn Metrics::gauge_snapshot(self : Metrics) -> Array[CounterSample] {
  self.gauges.copy()
}

///|
pub fn Metrics::sample_snapshot(self : Metrics) -> Array[CounterSample] {
  self.samples.copy()
}

///|
pub fn metrics_counter_delta(left : Metrics, right : Metrics, name : String) -> Int {
  right.counter(name) - left.counter(name)
}

///|
fn set_named_value(items : Array[CounterSample], name : String, value : Int) -> Unit {
  let mut i = 0
  while i < items.length() {
    if items[i].name == name {
      items[i] = { name, value }
      return
    }
    i += 1
  }
  items.push({ name, value })
}

///|
fn get_named_value(items : Array[CounterSample], name : String) -> Int {
  for item in items {
    if item.name == name {
      return item.value
    }
  }
  0
}
