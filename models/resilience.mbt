///|
pub(all) struct CircuitBreakerConfig {
  failure_threshold : Int
  reset_timeout : Int
  half_open_successes : Int
}

///|
pub(all) struct CircuitBreaker {
  name : String
  config : CircuitBreakerConfig
  mut state : String
  mut failures : Int
  mut opened_tick : Int
  mut trial_successes : Int
}

///|
pub(all) struct CircuitBreakerResult {
  state : String
  allowed : Int
  rejected : Int
  successes : Int
  failures : Int
  final_tick : Int
  digest : UInt64
}

///|
pub fn circuit_breaker_config(
  failure_threshold? : Int = 3,
  reset_timeout? : Int = 5,
  half_open_successes? : Int = 2,
) -> CircuitBreakerConfig {
  {
    failure_threshold: if failure_threshold < 1 {
      1
    } else {
      failure_threshold
    },
    reset_timeout: if reset_timeout < 1 {
      1
    } else {
      reset_timeout
    },
    half_open_successes: if half_open_successes < 1 {
      1
    } else {
      half_open_successes
    },
  }
}

///|
pub fn CircuitBreaker::new(
  name : String,
  config? : CircuitBreakerConfig = circuit_breaker_config(),
) -> CircuitBreaker {
  {
    name,
    config,
    state: "closed",
    failures: 0,
    opened_tick: -1,
    trial_successes: 0,
  }
}

///|
pub fn CircuitBreaker::state(self : CircuitBreaker) -> String {
  self.state
}

///|
pub fn CircuitBreaker::allow(self : CircuitBreaker, sim : Sim) -> Bool {
  if self.state == "open" &&
    sim.time() - self.opened_tick >= self.config.reset_timeout {
    self.state = "half_open"
    self.trial_successes = 0
    sim.record(0, "circuit.transition", self.name + ":open->half_open")
  }
  if self.state == "open" {
    sim.inc_counter("circuit_rejected")
    sim.record(0, "circuit.reject", self.name)
    false
  } else {
    sim.inc_counter("circuit_allowed")
    true
  }
}

///|
pub fn CircuitBreaker::record_success(self : CircuitBreaker, sim : Sim) -> Unit {
  sim.inc_counter("circuit_success")
  if self.state == "half_open" {
    self.trial_successes += 1
    if self.trial_successes >= self.config.half_open_successes {
      self.state = "closed"
      self.failures = 0
      self.opened_tick = -1
      sim.record(0, "circuit.transition", self.name + ":half_open->closed")
    }
  } else {
    self.failures = 0
  }
}

///|
pub fn CircuitBreaker::record_failure(self : CircuitBreaker, sim : Sim) -> Unit {
  sim.inc_counter("circuit_failure")
  self.failures += 1
  if self.state == "half_open" {
    self.open(sim)
  } else if self.failures >= self.config.failure_threshold {
    self.open(sim)
  }
}

///|
fn CircuitBreaker::open(self : CircuitBreaker, sim : Sim) -> Unit {
  self.state = "open"
  self.opened_tick = sim.time()
  self.trial_successes = 0
  sim.record(0, "circuit.transition", self.name + ":open")
}

///|
pub fn run_circuit_breaker_model(
  seed? : UInt64 = 606UL,
  calls? : Int = 12,
) -> CircuitBreakerResult {
  let sim = Sim::new(seed~)
  let breaker = CircuitBreaker::new("service")
  for call in 0..<calls {
    ignore(sim.schedule_at(call, "call:" + call.to_string()))
    ignore(sim.run_until_tick(call))
    if breaker.allow(sim) {
      if sim.next_int(100) < 45 {
        breaker.record_failure(sim)
      } else {
        breaker.record_success(sim)
      }
    }
  }
  ignore(sim.run_until_idle())
  {
    state: breaker.state(),
    allowed: sim.metrics().counter("circuit_allowed"),
    rejected: sim.metrics().counter("circuit_rejected"),
    successes: sim.metrics().counter("circuit_success"),
    failures: sim.metrics().counter("circuit_failure"),
    final_tick: sim.time(),
    digest: sim.digest(),
  }
}

///|
pub(all) struct TokenBucket {
  name : String
  capacity : Int
  refill : Int
  interval : Int
  mut tokens : Int
  mut last_refill_tick : Int
}

///|
pub(all) struct TokenBucketResult {
  allowed : Int
  rejected : Int
  final_tokens : Int
  final_tick : Int
  digest : UInt64
}

///|
pub fn TokenBucket::new(
  name : String,
  capacity? : Int = 5,
  refill? : Int = 1,
  interval? : Int = 1,
) -> TokenBucket {
  let cap = if capacity < 1 { 1 } else { capacity }
  {
    name,
    capacity: cap,
    refill: if refill < 1 {
      1
    } else {
      refill
    },
    interval: if interval < 1 {
      1
    } else {
      interval
    },
    tokens: cap,
    last_refill_tick: 0,
  }
}

///|
pub fn TokenBucket::allow(
  self : TokenBucket,
  sim : Sim,
  cost? : Int = 1,
) -> Bool {
  self.refill_to(sim.time())
  let normalized_cost = if cost < 1 { 1 } else { cost }
  if self.tokens >= normalized_cost {
    self.tokens -= normalized_cost
    sim.inc_counter("bucket_allowed")
    sim.record(0, "bucket.allow", self.name + ":" + self.tokens.to_string())
    true
  } else {
    sim.inc_counter("bucket_rejected")
    sim.record(0, "bucket.reject", self.name + ":" + self.tokens.to_string())
    false
  }
}

///|
pub fn TokenBucket::refill_to(self : TokenBucket, tick : Int) -> Unit {
  if tick <= self.last_refill_tick {
    return
  }
  let elapsed = tick - self.last_refill_tick
  let periods = elapsed / self.interval
  if periods > 0 {
    self.tokens = min_int(self.capacity, self.tokens + periods * self.refill)
    self.last_refill_tick += periods * self.interval
  }
}

///|
fn min_int(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
pub fn run_token_bucket_model(
  seed? : UInt64 = 7070UL,
  requests? : Int = 14,
) -> TokenBucketResult {
  let sim = Sim::new(seed~)
  let bucket = TokenBucket::new("api", capacity=4, refill=2, interval=3)
  for request in 0..<requests {
    let tick = request + sim.next_int(2)
    ignore(sim.schedule_at(tick, "request:" + request.to_string()))
    ignore(sim.run_until_tick(tick))
    ignore(bucket.allow(sim))
  }
  ignore(sim.run_until_idle())
  {
    allowed: sim.metrics().counter("bucket_allowed"),
    rejected: sim.metrics().counter("bucket_rejected"),
    final_tokens: bucket.tokens,
    final_tick: sim.time(),
    digest: sim.digest(),
  }
}

///|
pub fn CircuitBreakerResult::summary(
  self : CircuitBreakerResult,
) -> ModelSummary {
  {
    name: "circuit_breaker",
    digest: self.digest,
    final_tick: self.final_tick,
    events: self.allowed + self.rejected,
  }
}

///|
pub fn TokenBucketResult::summary(self : TokenBucketResult) -> ModelSummary {
  {
    name: "token_bucket",
    digest: self.digest,
    final_tick: self.final_tick,
    events: self.allowed + self.rejected,
  }
}
