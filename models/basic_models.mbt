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
  service_time? : Int = 3,
) -> QueueConfig {
  {
    seed,
    customers: if customers < 0 {
      0
    } else {
      customers
    },
    max_arrival_gap: if max_arrival_gap < 1 {
      1
    } else {
      max_arrival_gap
    },
    service_time: if service_time < 1 {
      1
    } else {
      service_time
    },
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
    ignore(
      sim.schedule_at(
        current_tick,
        "customer:" + customer.to_string() + ":arrive",
      ),
    )
    let start = if current_tick > last_finish {
      current_tick
    } else {
      last_finish
    }
    let finish = start + config.service_time
    last_finish = finish
    ignore(
      sim.schedule_at(finish, "customer:" + customer.to_string() + ":finish"),
    )
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
/// Projects queue arrivals and completions into the shared message event stream.
pub fn QueueResult::event_stream(self : QueueResult) -> EventStream {
  let stream = EventStream::new()
  for entry in self.trace {
    ignore(
      stream.record(
        @core.message_event_kind(),
        entry.tick,
        entry.kind,
        correlation_id=entry.event_id.to_string(),
        source="queue",
        target="worker",
        payload=entry.detail,
      ),
    )
  }
  stream
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
  jitter? : Int = 1,
) -> RetryConfig {
  {
    seed,
    max_attempts: if max_attempts < 1 {
      1
    } else {
      max_attempts
    },
    fail_until: if fail_until < 0 {
      0
    } else {
      fail_until
    },
    initial_backoff: if initial_backoff < 1 {
      1
    } else {
      initial_backoff
    },
    jitter: if jitter < 0 {
      0
    } else {
      jitter
    },
  }
}

///|
pub fn run_retry_model(config : RetryConfig) -> RetryResult {
  let sim = Sim::new(seed=config.seed)
  let backoff = Backoff::new(
    initial=config.initial_backoff,
    jitter=config.jitter,
  )
  let mut tick = 0
  let mut success = false
  for attempt in 1..<=config.max_attempts {
    ignore(sim.schedule_at(tick, "attempt:" + attempt.to_string()))
    sim.inc_counter("attempts")
    if attempt <= config.fail_until {
      ignore(
        sim.schedule_at(tick, "attempt:" + attempt.to_string() + ":failed"),
      )
      tick += backoff.next_delay(sim.rng)
      sim.inc_counter("retries")
    } else {
      ignore(
        sim.schedule_at(tick, "attempt:" + attempt.to_string() + ":succeeded"),
      )
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
  cycle_ticks? : Int = 5,
) -> TrafficConfig {
  {
    seed,
    cycles: if cycles < 1 {
      1
    } else {
      cycles
    },
    cars: if cars < 0 {
      0
    } else {
      cars
    },
    cycle_ticks: if cycle_ticks < 1 {
      1
    } else {
      cycle_ticks
    },
  }
}

///|
pub fn run_traffic_model(config : TrafficConfig) -> TrafficResult {
  let sim = Sim::new(seed=config.seed)
  let states = ["green", "yellow", "red", "red"]
  ignore(
    sim.install_timer(
      timer_plan(
        "light:cycle",
        interval=config.cycle_ticks,
        times=config.cycles,
      ),
    ),
  )
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
  self.name +
  " tick=" +
  self.final_tick.to_string() +
  " events=" +
  self.events.to_string() +
  " digest=" +
  self.digest.to_string()
}

///|
pub(all) struct NetworkConfig {
  seed : UInt64
  messages : Int
  latency_min : Int
  latency_max : Int
  drop_percent : Int
  retry_delay : Int
}

///|
pub(all) struct NetworkResult {
  messages : Int
  delivered : Int
  dropped : Int
  retries : Int
  pending : Int
  final_tick : Int
  digest : UInt64
  trace : Array[TraceEntry]
}

///|
pub fn network_config(
  seed? : UInt64 = 707UL,
  messages? : Int = 8,
  latency_min? : Int = 1,
  latency_max? : Int = 5,
  drop_percent? : Int = 20,
  retry_delay? : Int = 3,
) -> NetworkConfig {
  {
    seed,
    messages: if messages < 0 {
      0
    } else {
      messages
    },
    latency_min: if latency_min < 0 {
      0
    } else {
      latency_min
    },
    latency_max: if latency_max <= latency_min {
      latency_min + 1
    } else {
      latency_max
    },
    drop_percent: clamp_percent(drop_percent),
    retry_delay: if retry_delay < 0 {
      0
    } else {
      retry_delay
    },
  }
}

///|
fn clamp_percent(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 100 {
    100
  } else {
    value
  }
}

///|
pub fn run_network_model(config : NetworkConfig) -> NetworkResult {
  let sim = Sim::new(seed=config.seed)
  let bus = MessageBus::new()
  for i in 0..<config.messages {
    let latency = sim.next_range(config.latency_min, config.latency_max + 1)
    let id = bus.send(
      sim,
      "node:" + (i % 3).to_string(),
      "node:" + ((i + 1) % 3).to_string(),
      "payload:" + i.to_string(),
      delay=latency,
    )
    sim.inc_counter("network_messages")
    sim.sample("network_latency", latency)
    if sim.next_int(100) < config.drop_percent {
      ignore(bus.drop(sim, id))
      sim.inc_counter("network_retries")
      let retry_latency = latency + config.retry_delay
      ignore(
        bus.send(
          sim,
          "node:" + (i % 3).to_string(),
          "node:" + ((i + 1) % 3).to_string(),
          "retry:" + i.to_string(),
          delay=retry_latency,
        ),
      )
    }
  }
  ignore(sim.run_until_idle())
  ignore(bus.deliver_due(sim))
  {
    messages: sim.metrics().counter("network_messages"),
    delivered: sim.metrics().counter("messages_delivered"),
    dropped: sim.metrics().counter("messages_dropped"),
    retries: sim.metrics().counter("network_retries"),
    pending: bus.pending(sim),
    final_tick: sim.time(),
    digest: sim.digest(),
    trace: sim.trace(),
  }
}

///|
pub fn network_summary(result : NetworkResult) -> ModelSummary {
  {
    name: "network",
    digest: result.digest,
    final_tick: result.final_tick,
    events: result.delivered + result.dropped + result.retries,
  }
}

///|
pub(all) struct LoadBalancerConfig {
  seed : UInt64
  jobs : Int
  workers : Int
  max_arrival_gap : Int
  min_service : Int
  max_service : Int
  strategy : String
}

///|
pub(all) struct LoadBalancerResult {
  jobs : Int
  workers : Int
  strategy : String
  final_tick : Int
  max_queue_depth : Int
  total_wait : Int
  events_executed : Int
  digest : UInt64
}

///|
pub fn load_balancer_config(
  seed? : UInt64 = 808UL,
  jobs? : Int = 12,
  workers? : Int = 3,
  max_arrival_gap? : Int = 3,
  min_service? : Int = 2,
  max_service? : Int = 6,
  strategy? : String = "least_queue",
) -> LoadBalancerConfig {
  let normalized_min_service = if min_service < 1 { 1 } else { min_service }
  {
    seed,
    jobs: if jobs < 0 {
      0
    } else {
      jobs
    },
    workers: if workers < 1 {
      1
    } else {
      workers
    },
    max_arrival_gap: if max_arrival_gap < 1 {
      1
    } else {
      max_arrival_gap
    },
    min_service: normalized_min_service,
    max_service: if max_service <= normalized_min_service {
      normalized_min_service + 1
    } else {
      max_service
    },
    strategy,
  }
}

///|
pub fn run_load_balancer_model(
  config : LoadBalancerConfig,
) -> LoadBalancerResult {
  let sim = Sim::new(seed=config.seed)
  let available : Array[Int] = []
  let assigned : Array[Int] = []
  for _ in 0..<config.workers {
    available.push(0)
    assigned.push(0)
  }
  let mut arrival = 0
  let mut max_queue_depth = 0
  let mut total_wait = 0
  for job in 0..<config.jobs {
    arrival += sim.next_range(1, config.max_arrival_gap + 1)
    let worker = choose_worker(sim, available, assigned, config.strategy)
    let start = if available[worker] > arrival {
      available[worker]
    } else {
      arrival
    }
    let wait = start - arrival
    let service = sim.next_range(config.min_service, config.max_service + 1)
    let finish = start + service
    available[worker] = finish
    assigned[worker] = assigned[worker] + 1
    total_wait += wait
    if wait > max_queue_depth {
      max_queue_depth = wait
    }
    ignore(sim.schedule_at(arrival, "job:" + job.to_string() + ":arrive"))
    ignore(
      sim.schedule_at(
        start,
        "job:" + job.to_string() + ":worker:" + worker.to_string() + ":start",
      ),
    )
    ignore(sim.schedule_at(finish, "job:" + job.to_string() + ":finish"))
    sim.inc_counter("jobs")
    sim.inc_counter("worker:" + worker.to_string() + ":jobs")
    sim.sample("job_wait", wait)
    sim.sample("job_service", service)
  }
  ignore(sim.run_until_idle())
  {
    jobs: sim.metrics().counter("jobs"),
    workers: config.workers,
    strategy: config.strategy,
    final_tick: sim.time(),
    max_queue_depth,
    total_wait,
    events_executed: sim.metrics().counter("events_executed"),
    digest: sim.digest(),
  }
}

///|
fn choose_worker(
  sim : Sim,
  available : Array[Int],
  assigned : Array[Int],
  strategy : String,
) -> Int {
  if strategy == "random" {
    sim.next_int(available.length())
  } else if strategy == "round_robin" {
    let mut total = 0
    for count in assigned {
      total += count
    }
    total % available.length()
  } else {
    let mut best = 0
    let mut i = 1
    while i < available.length() {
      if available[i] < available[best] {
        best = i
      } else if available[i] == available[best] && assigned[i] < assigned[best] {
        best = i
      }
      i += 1
    }
    best
  }
}

///|
pub fn load_balancer_summary(result : LoadBalancerResult) -> ModelSummary {
  {
    name: "load_balancer:" + result.strategy,
    digest: result.digest,
    final_tick: result.final_tick,
    events: result.events_executed,
  }
}
