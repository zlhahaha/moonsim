///|
pub(all) struct QueueConfig {
  seed : UInt64
  customers : Int
  max_arrival_gap : Int
  service_time : Int
}

///|
pub(all) struct QueueResult {
  customers : Int
  events_executed : Int
  final_tick : Int
  min_arrival : Int
  max_arrival : Int
  digest : UInt64
  trace : Array[TraceEntry]
}

///|
pub fn queue_config(
  seed? : UInt64 = 4096UL,
  customers? : Int = 5,
  max_arrival_gap? : Int = 4,
  service_time? : Int = 3
) -> QueueConfig {
  {
    seed,
    customers: if customers < 0 { 0 } else { customers },
    max_arrival_gap: if max_arrival_gap < 1 { 1 } else { max_arrival_gap },
    service_time: if service_time < 1 { 1 } else { service_time },
  }
}

///|
pub fn run_queue_model(config : QueueConfig) -> QueueResult {
  let sim = Sim::new(seed=config.seed)
  let mut current_tick = 0
  let mut last_finish = 0
  for customer in 0..<config.customers {
    let gap = sim.next_range(1, config.max_arrival_gap + 1)
    current_tick += gap
    ignore(sim.schedule_at(current_tick, "customer:" + customer.to_string() + ":arrive"))
    let start = if current_tick > last_finish { current_tick } else { last_finish }
    let finish = start + config.service_time
    last_finish = finish
    ignore(sim.schedule_at(finish, "customer:" + customer.to_string() + ":finish"))
    sim.inc_counter("customers")
    sim.sample("arrival_tick", current_tick)
    sim.sample("finish_tick", finish)
  }
  ignore(sim.run_until_idle())
  let arrivals = sim.metrics().summary("arrival_tick")
  {
    customers: sim.metrics().counter("customers"),
    events_executed: sim.metrics().counter("events_executed"),
    final_tick: sim.time(),
    min_arrival: arrivals.min,
    max_arrival: arrivals.max,
    digest: sim.digest(),
    trace: sim.trace(),
  }
}

///|
pub(all) struct RetryConfig {
  seed : UInt64
  max_attempts : Int
  fail_until : Int
  initial_backoff : Int
  jitter : Int
}

///|
pub(all) struct RetryResult {
  attempts : Int
  retries : Int
  success : Bool
  final_tick : Int
  digest : UInt64
  trace : Array[TraceEntry]
}

///|
pub fn retry_config(
  seed? : UInt64 = 2026UL,
  max_attempts? : Int = 4,
  fail_until? : Int = 2,
  initial_backoff? : Int = 1,
  jitter? : Int = 1
) -> RetryConfig {
  {
    seed,
    max_attempts: if max_attempts < 1 { 1 } else { max_attempts },
    fail_until: if fail_until < 0 { 0 } else { fail_until },
    initial_backoff: if initial_backoff < 1 { 1 } else { initial_backoff },
    jitter: if jitter < 0 { 0 } else { jitter },
  }
}

///|
pub fn run_retry_model(config : RetryConfig) -> RetryResult {
  let sim = Sim::new(seed=config.seed)
  let backoff = Backoff::new(initial=config.initial_backoff, jitter=config.jitter)
  let mut tick = 0
  let mut success = false
  for attempt in 1..=config.max_attempts {
    ignore(sim.schedule_at(tick, "attempt:" + attempt.to_string()))
    sim.inc_counter("attempts")
    if attempt <= config.fail_until {
      ignore(sim.schedule_at(tick, "attempt:" + attempt.to_string() + ":failed"))
      tick += backoff.next_delay(sim.rng)
      sim.inc_counter("retries")
    } else {
      ignore(sim.schedule_at(tick, "attempt:" + attempt.to_string() + ":succeeded"))
      sim.inc_counter("success")
      success = true
      break
    }
  }
  ignore(sim.run_until_idle())
  {
    attempts: sim.metrics().counter("attempts"),
    retries: sim.metrics().counter("retries"),
    success,
    final_tick: sim.time(),
    digest: sim.digest(),
    trace: sim.trace(),
  }
}

///|
pub(all) struct TrafficConfig {
  seed : UInt64
  cycles : Int
  cars : Int
  cycle_ticks : Int
}

///|
pub(all) struct TrafficResult {
  cars : Int
  green_phases : Int
  red_phases : Int
  events_executed : Int
  final_tick : Int
  digest : UInt64
}

///|
pub fn traffic_config(
  seed? : UInt64 = 300UL,
  cycles? : Int = 8,
  cars? : Int = 12,
  cycle_ticks? : Int = 5
) -> TrafficConfig {
  {
    seed,
    cycles: if cycles < 1 { 1 } else { cycles },
    cars: if cars < 0 { 0 } else { cars },
    cycle_ticks: if cycle_ticks < 1 { 1 } else { cycle_ticks },
  }
}

///|
pub fn run_traffic_model(config : TrafficConfig) -> TrafficResult {
  let sim = Sim::new(seed=config.seed)
  let states = ["green", "yellow", "red", "red"]
  ignore(sim.install_timer(timer_plan("light:cycle", interval=config.cycle_ticks, times=config.cycles)))
  for i in 0..<config.cycles {
    let state = states[i % states.length()]
    ignore(sim.schedule_at(i * config.cycle_ticks, "light:" + state))
    if state == "green" {
      sim.inc_counter("green_phases")
    } else if state == "red" {
      sim.inc_counter("red_phases")
    }
  }
  for car in 0..<config.cars {
    let arrive = sim.next_range(0, config.cycles * config.cycle_ticks)
    ignore(sim.schedule_at(arrive, "car:" + car.to_string() + ":arrive"))
    sim.inc_counter("cars")
  }
  ignore(sim.run_until_idle())
  {
    cars: sim.metrics().counter("cars"),
    green_phases: sim.metrics().counter("green_phases"),
    red_phases: sim.metrics().counter("red_phases"),
    events_executed: sim.metrics().counter("events_executed"),
    final_tick: sim.time(),
    digest: sim.digest(),
  }
}

///|
pub(all) struct ModelSummary {
  name : String
  digest : UInt64
  final_tick : Int
  events : Int
}

///|
pub fn queue_summary(result : QueueResult) -> ModelSummary {
  {
    name: "queue",
    digest: result.digest,
    final_tick: result.final_tick,
    events: result.events_executed,
  }
}

///|
pub fn retry_summary(result : RetryResult) -> ModelSummary {
  {
    name: "retry",
    digest: result.digest,
    final_tick: result.final_tick,
    events: result.attempts + result.retries,
  }
}

///|
pub fn traffic_summary(result : TrafficResult) -> ModelSummary {
  {
    name: "traffic",
    digest: result.digest,
    final_tick: result.final_tick,
    events: result.events_executed,
  }
}

///|
pub fn ModelSummary::line(self : ModelSummary) -> String {
  self.name + " tick=" + self.final_tick.to_string() +
  " events=" + self.events.to_string() + " digest=" + self.digest.to_string()
}
