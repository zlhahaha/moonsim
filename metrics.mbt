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
pub(all) struct SampleDistribution {
  name : String
  count : Int
  min : Int
  max : Int
  median : Int
  p90 : Int
}

///|
pub(all) struct MetricSnapshot {
  counters : Array[CounterSample]
  gauges : Array[CounterSample]
  samples : Array[CounterSample]
}

///|
pub(all) struct MetricDelta {
  name : String
  before : Int
  after : Int
  delta : Int
}

///|
pub(all) struct MetricDiff {
  counters : Array[MetricDelta]
  gauges : Array[MetricDelta]
  sample_delta : Int
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
pub fn Metrics::distribution(self : Metrics, name : String) -> SampleDistribution {
  let values = self.sample_values(name)
  values.sort()
  if values.length() == 0 {
    { name, count: 0, min: 0, max: 0, median: 0, p90: 0 }
  } else {
    let median_index = values.length() / 2
    let p90_index = percentile_index(values.length(), 90)
    {
      name,
      count: values.length(),
      min: values[0],
      max: values[values.length() - 1],
      median: values[median_index],
      p90: values[p90_index],
    }
  }
}

///|
pub fn Metrics::sample_values(self : Metrics, name : String) -> Array[Int] {
  let values : Array[Int] = []
  for sample in self.samples {
    if sample.name == name {
      values.push(sample.value)
    }
  }
  values
}

///|
fn percentile_index(length : Int, percentile : Int) -> Int {
  if length <= 1 {
    0
  } else {
    let raw = (length - 1) * percentile / 100
    if raw < 0 {
      0
    } else if raw >= length {
      length - 1
    } else {
      raw
    }
  }
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
pub fn Metrics::metric_snapshot(self : Metrics) -> MetricSnapshot {
  {
    counters: self.snapshot(),
    gauges: self.gauge_snapshot(),
    samples: self.sample_snapshot(),
  }
}

///|
pub fn diff_metrics(before : MetricSnapshot, after : MetricSnapshot) -> MetricDiff {
  {
    counters: diff_counter_samples(before.counters, after.counters),
    gauges: diff_counter_samples(before.gauges, after.gauges),
    sample_delta: after.samples.length() - before.samples.length(),
  }
}

///|
pub fn Metrics::diff_from(self : Metrics, before : MetricSnapshot) -> MetricDiff {
  diff_metrics(before, self.metric_snapshot())
}

///|
fn diff_counter_samples(before : Array[CounterSample], after : Array[CounterSample]) -> Array[MetricDelta] {
  let deltas : Array[MetricDelta] = []
  for item in after {
    let start = counter_sample_value(before, item.name)
    deltas.push({
      name: item.name,
      before: start,
      after: item.value,
      delta: item.value - start,
    })
  }
  for item in before {
    if !counter_sample_has(after, item.name) {
      deltas.push({
        name: item.name,
        before: item.value,
        after: 0,
        delta: 0 - item.value,
      })
    }
  }
  deltas
}

///|
fn counter_sample_value(items : Array[CounterSample], name : String) -> Int {
  for item in items {
    if item.name == name {
      return item.value
    }
  }
  0
}

///|
fn counter_sample_has(items : Array[CounterSample], name : String) -> Bool {
  for item in items {
    if item.name == name {
      return true
    }
  }
  false
}

///|
pub fn MetricDiff::summary(self : MetricDiff) -> String {
  "counters=" + self.counters.length().to_string() +
  " gauges=" + self.gauges.length().to_string() +
  " sample_delta=" + self.sample_delta.to_string()
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
