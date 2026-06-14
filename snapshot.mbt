///|
pub(all) struct SimSnapshot {
  name : String
  time : Int
  next_id : Int
  rng_state : UInt64
  digest : UInt64
  events : Array[ScheduledEvent]
  counters : Array[CounterSample]
  gauges : Array[CounterSample]
  samples : Array[CounterSample]
}

///|
pub(all) struct ForkComparison {
  left_name : String
  right_name : String
  left_digest : UInt64
  right_digest : UInt64
  same_digest : Bool
  left_events : Int
  right_events : Int
}

///|
pub fn Sim::snapshot(self : Sim, name? : String = "snapshot") -> SimSnapshot {
  self.record(0, "snapshot", name)
  {
    name,
    time: self.now,
    next_id: self.next_id,
    rng_state: self.rng.state(),
    digest: self.digest(),
    events: self.events.copy(),
    counters: self.metrics.snapshot(),
    gauges: self.metrics.gauge_snapshot(),
    samples: self.metrics.sample_snapshot(),
  }
}

///|
pub fn Sim::restore(snapshot : SimSnapshot) -> Sim {
  let sim = Sim::new(seed=snapshot.rng_state)
  sim.now = snapshot.time
  sim.next_id = snapshot.next_id
  sim.events = snapshot.events.copy()
  for counter in snapshot.counters {
    sim.metrics.inc(counter.name, delta=counter.value)
  }
  for gauge in snapshot.gauges {
    sim.metrics.set_gauge(gauge.name, gauge.value)
  }
  for sample in snapshot.samples {
    sim.metrics.sample(sample.name, sample.value)
  }
  sim.record(0, "restore", snapshot.name)
  sim
}

///|
pub fn SimSnapshot::fork(self : SimSnapshot, name : String) -> Sim {
  let sim = Sim::restore(self)
  sim.record(0, "fork", name)
  sim
}

///|
pub fn compare_forks(left_name : String, left : Sim, right_name : String, right : Sim) -> ForkComparison {
  {
    left_name,
    right_name,
    left_digest: left.digest(),
    right_digest: right.digest(),
    same_digest: left.digest() == right.digest(),
    left_events: left.metrics().counter("events_executed"),
    right_events: right.metrics().counter("events_executed"),
  }
}

///|
pub fn ForkComparison::summary(self : ForkComparison) -> String {
  let status = if self.same_digest { "same" } else { "different" }
  "forks " + status + " left=" + self.left_name + " right=" + self.right_name +
  " left_events=" + self.left_events.to_string() +
  " right_events=" + self.right_events.to_string()
}
