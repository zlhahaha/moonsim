///|
pub(all) struct ServiceResilienceConfig {
  seed : UInt64
  requests : Int
  workers : Int
  queue_limit : Int
  timeout_ticks : Int
  retry_limit : Int
  base_latency : Int
  jitter : Int
  fail_percent : Int
  drop_percent : Int
  rate_limit_capacity : Int
  rate_limit_refill : Int
  rate_limit_interval : Int
  min_success_percent : Int
}

///|
pub(all) struct ServiceResilienceResult {
  config : ServiceResilienceConfig
  accepted : Int
  rejected : Int
  completed : Int
  failed : Int
  timed_out : Int
  late_successes : Int
  retried : Int
  rate_limited : Int
  circuit_rejected : Int
  max_queue_depth : Int
  final_tick : Int
  slo_passed : Bool
  latency_count : Int
  latency_min : Int
  latency_max : Int
  latency_sum : Int
  digest : UInt64
  invariants : InvariantReport
  trace : Array[TraceEntry]
}

///|
pub fn service_resilience_config(
  seed? : UInt64 = 2026UL,
  requests? : Int = 36,
  workers? : Int = 4,
  queue_limit? : Int = 8,
  timeout_ticks? : Int = 16,
  retry_limit? : Int = 2,
  base_latency? : Int = 2,
  jitter? : Int = 5,
  fail_percent? : Int = 18,
  drop_percent? : Int = 8,
  rate_limit_capacity? : Int = 9,
  rate_limit_refill? : Int = 4,
  rate_limit_interval? : Int = 5,
  min_success_percent? : Int = 65,
) -> ServiceResilienceConfig {
  {
    seed,
    requests: clamp_min(requests, 0),
    workers: clamp_min(workers, 1),
    queue_limit: clamp_min(queue_limit, 0),
    timeout_ticks: clamp_min(timeout_ticks, 1),
    retry_limit: clamp_min(retry_limit, 0),
    base_latency: clamp_min(base_latency, 1),
    jitter: clamp_min(jitter, 0),
    fail_percent: clamp_service_percent(fail_percent),
    drop_percent: clamp_service_percent(drop_percent),
    rate_limit_capacity: clamp_min(rate_limit_capacity, 1),
    rate_limit_refill: clamp_min(rate_limit_refill, 1),
    rate_limit_interval: clamp_min(rate_limit_interval, 1),
    min_success_percent: clamp_service_percent(min_success_percent),
  }
}

///|
pub fn run_service_resilience_suite(
  config? : ServiceResilienceConfig = service_resilience_config(),
) -> ServiceResilienceResult {
  let sim = Sim::new(seed=config.seed)
  let bucket = TokenBucket::new(
    "frontend",
    capacity=config.rate_limit_capacity,
    refill=config.rate_limit_refill,
    interval=config.rate_limit_interval,
  )
  let breaker = CircuitBreaker::new(
    "payments",
    config=circuit_breaker_config(
      failure_threshold=4,
      reset_timeout=6,
      half_open_successes=2,
    ),
  )
  let worker_ready : Array[Int] = []
  for _ in 0..<config.workers {
    worker_ready.push(0)
  }
  let mut accepted = 0
  let mut rejected = 0
  let mut completed = 0
  let mut failed = 0
  let mut timed_out = 0
  let mut late_successes = 0
  let mut retried = 0
  let mut rate_limited = 0
  let mut circuit_rejected = 0
  let mut max_queue_depth = 0
  let mut latency_count = 0
  let mut latency_min = 0
  let mut latency_max = 0
  let mut latency_sum = 0
  for request in 0..<config.requests {
    let arrival = request + sim.next_int(3)
    ignore(
      sim.schedule_at(arrival, "request:" + request.to_string() + ":arrive"),
    )
    ignore(sim.run_until_tick(arrival))
    bucket.refill_to(arrival)
    if !bucket.allow(sim) {
      rejected += 1
      rate_limited += 1
      sim.inc_counter("service.rate_limited")
      continue
    }
    if !breaker.allow(sim) {
      rejected += 1
      circuit_rejected += 1
      sim.inc_counter("service.circuit_rejected")
      continue
    }
    let busy = busy_workers(worker_ready, arrival)
    if busy > max_queue_depth {
      max_queue_depth = busy
    }
    if busy > config.queue_limit {
      rejected += 1
      sim.inc_counter("service.queue_rejected")
      continue
    }
    accepted += 1
    let worker = earliest_worker(worker_ready)
    let mut start = worker_ready[worker]
    if start < arrival {
      start = arrival
    }
    let mut finish = start
    let mut success = false
    let mut attempts = 0
    while attempts <= config.retry_limit && !success {
      attempts += 1
      ignore(
        sim.schedule_at(
          finish,
          "request:" + request.to_string() + ":attempt:" + attempts.to_string(),
        ),
      )
      let latency = config.base_latency + sim.next_int(config.jitter + 1)
      finish += latency
      let dropped = sim.next_int(100) < config.drop_percent
      let failed_attempt = sim.next_int(100) < config.fail_percent
      if dropped || failed_attempt {
        breaker.record_failure(sim)
        if attempts <= config.retry_limit {
          retried += 1
          sim.inc_counter("service.retried")
          finish += attempts
        }
      } else {
        success = true
        breaker.record_success(sim)
      }
    }
    worker_ready[worker] = finish
    let observed_latency = finish - arrival
    if latency_count == 0 || observed_latency < latency_min {
      latency_min = observed_latency
    }
    if observed_latency > latency_max {
      latency_max = observed_latency
    }
    latency_count += 1
    latency_sum += observed_latency
    sim.sample("service.latency", observed_latency)
    sim.sample("service.queue_depth", busy)
    if success && observed_latency <= config.timeout_ticks {
      completed += 1
      sim.inc_counter("service.completed")
      ignore(
        sim.schedule_at(finish, "request:" + request.to_string() + ":complete"),
      )
    } else if observed_latency > config.timeout_ticks {
      timed_out += 1
      if success {
        late_successes += 1
      }
      failed += 1
      sim.inc_counter("service.timed_out")
      ignore(
        sim.schedule_at(finish, "request:" + request.to_string() + ":timeout"),
      )
    } else {
      failed += 1
      sim.inc_counter("service.failed")
      ignore(
        sim.schedule_at(finish, "request:" + request.to_string() + ":failed"),
      )
    }
  }
  ignore(sim.run_until_idle())
  let slo_passed = if config.requests == 0 {
    true
  } else {
    completed * 100 >= config.requests * config.min_success_percent
  }
  let invariants = service_resilience_invariants(
    config, sim, accepted, rejected, completed, failed, timed_out, late_successes,
    max_queue_depth, slo_passed,
  )
  {
    config,
    accepted,
    rejected,
    completed,
    failed,
    timed_out,
    late_successes,
    retried,
    rate_limited,
    circuit_rejected,
    max_queue_depth,
    final_tick: sim.time(),
    slo_passed,
    latency_count,
    latency_min,
    latency_max,
    latency_sum,
    digest: sim.digest(),
    invariants,
    trace: sim.trace(),
  }
}

///|
pub fn ServiceResilienceResult::success_percent(
  self : ServiceResilienceResult,
) -> Int {
  if self.config.requests == 0 {
    100
  } else {
    self.completed * 100 / self.config.requests
  }
}

///|
pub fn ServiceResilienceResult::average_latency(
  self : ServiceResilienceResult,
) -> Int {
  if self.latency_count == 0 {
    0
  } else {
    self.latency_sum / self.latency_count
  }
}

///|
pub fn ServiceResilienceResult::summary(
  self : ServiceResilienceResult,
) -> ModelSummary {
  {
    name: "service_resilience",
    digest: self.digest,
    final_tick: self.final_tick,
    events: self.trace.length(),
  }
}

///|
pub fn ServiceResilienceResult::line(self : ServiceResilienceResult) -> String {
  "service_resilience seed=" +
  self.config.seed.to_string() +
  " requests=" +
  self.config.requests.to_string() +
  " completed=" +
  self.completed.to_string() +
  " rejected=" +
  self.rejected.to_string() +
  " failed=" +
  self.failed.to_string() +
  " timed_out=" +
  self.timed_out.to_string() +
  " late_successes=" +
  self.late_successes.to_string() +
  " success=" +
  self.success_percent().to_string() +
  "% slo=" +
  (if self.slo_passed { "pass" } else { "fail" }) +
  " digest=" +
  self.digest.to_string()
}

///|
pub fn render_service_resilience_report(
  result : ServiceResilienceResult,
) -> String {
  let buf = StringBuilder::new()
  buf.write_string("# Service Resilience\n")
  buf.write_string(result.line() + "\n")
  buf.write_string(
    "retries=" +
    result.retried.to_string() +
    " timed_out=" +
    result.timed_out.to_string() +
    " late_successes=" +
    result.late_successes.to_string() +
    " rate_limited=" +
    result.rate_limited.to_string() +
    " circuit_rejected=" +
    result.circuit_rejected.to_string() +
    " max_queue_depth=" +
    result.max_queue_depth.to_string() +
    "\n",
  )
  buf.write_string(
    "latency=count=" +
    result.latency_count.to_string() +
    " min=" +
    result.latency_min.to_string() +
    " max=" +
    result.latency_max.to_string() +
    " avg=" +
    result.average_latency().to_string() +
    "\n",
  )
  buf.write_string(result.invariants.render() + "\n")
  buf.to_string()
}

///|
pub fn service_resilience_seed_matrix(seeds : Array[UInt64]) -> SeedMatrix {
  let matrix = SeedMatrix::new("service_resilience")
  for seed in seeds {
    let result = run_service_resilience_suite(
      config=service_resilience_config(seed~, requests=28),
    )
    ignore(matrix.add(seed_run(seed, result.summary())))
  }
  matrix
}

///|
fn service_resilience_invariants(
  config : ServiceResilienceConfig,
  sim : Sim,
  accepted : Int,
  rejected : Int,
  completed : Int,
  failed : Int,
  timed_out : Int,
  late_successes : Int,
  max_queue_depth : Int,
  slo_passed : Bool,
) -> InvariantReport {
  check_sim_invariants(sim).merge(
    InvariantReport::new("service_resilience")
    .add(
      invariant_check(
        "request_conservation",
        accepted + rejected == config.requests,
        detail=(accepted + rejected).to_string() +
          "/" +
          config.requests.to_string(),
      ),
    )
    .add(
      invariant_check(
        "outcome_conservation",
        completed + failed <= accepted,
        detail=(completed + failed).to_string() + "<=" + accepted.to_string(),
      ),
    )
    .add(
      invariant_check(
        "bounded_queue_depth",
        max_queue_depth <= config.queue_limit,
        detail=max_queue_depth.to_string() +
          "<=" +
          config.queue_limit.to_string(),
      ),
    )
    .add(
      invariant_check(
        "slo_min_success_percent",
        slo_passed,
        detail=completed.to_string() +
          "/" +
          config.requests.to_string() +
          " target=" +
          config.min_success_percent.to_string() +
          "%",
      ),
    )
    .add(
      invariant_check(
        "timeouts_counted_as_failures",
        timed_out <= failed,
        detail=timed_out.to_string() + "<=" + failed.to_string(),
      ),
    )
    .add(
      invariant_check(
        "late_successes_are_timeouts",
        late_successes <= timed_out,
        detail=late_successes.to_string() + "<=" + timed_out.to_string(),
      ),
    ),
  )
}

///|
fn earliest_worker(workers : Array[Int]) -> Int {
  let mut best = 0
  let mut i = 1
  while i < workers.length() {
    if workers[i] < workers[best] {
      best = i
    }
    i += 1
  }
  best
}

///|
fn busy_workers(workers : Array[Int], tick : Int) -> Int {
  let mut busy = 0
  for worker in workers {
    if worker > tick {
      busy += 1
    }
  }
  busy
}

///|
fn clamp_min(value : Int, minimum : Int) -> Int {
  if value < minimum {
    minimum
  } else {
    value
  }
}

///|
fn clamp_service_percent(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 100 {
    100
  } else {
    value
  }
}
