///|
pub(all) struct ReliabilityConfig {
  seed : UInt64
  operations : Int
  fail_percent : Int
  retry_limit : Int
  backoff : Int
}

///|
pub(all) struct ReliabilityResult {
  operations : Int
  successes : Int
  failures : Int
  retries : Int
  exhausted : Int
  final_tick : Int
  digest : UInt64
  trace : Array[TraceEntry]
}

///|
pub fn reliability_config(
  seed? : UInt64 = 9090UL,
  operations? : Int = 10,
  fail_percent? : Int = 30,
  retry_limit? : Int = 2,
  backoff? : Int = 2
) -> ReliabilityConfig {
  {
    seed,
    operations: if operations < 0 { 0 } else { operations },
    fail_percent: clamp_percent(fail_percent),
    retry_limit: if retry_limit < 0 { 0 } else { retry_limit },
    backoff: if backoff < 0 { 0 } else { backoff },
  }
}

///|
pub fn run_reliability_model(config : ReliabilityConfig) -> ReliabilityResult {
  let sim = Sim::new(seed=config.seed)
  for operation in 0..<config.operations {
    run_reliability_operation(sim, config, operation)
  }
  ignore(sim.run_until_idle())
  {
    operations: config.operations,
    successes: sim.metrics().counter("reliability_success"),
    failures: sim.metrics().counter("reliability_failure"),
    retries: sim.metrics().counter("reliability_retry"),
    exhausted: sim.metrics().counter("reliability_exhausted"),
    final_tick: sim.time(),
    digest: sim.digest(),
    trace: sim.trace(),
  }
}

///|
fn run_reliability_operation(sim : Sim, config : ReliabilityConfig, operation : Int) -> Unit {
  let mut attempt = 0
  let mut tick = operation
  let mut done = false
  while attempt <= config.retry_limit && !done {
    let name = "op:" + operation.to_string() + ":attempt:" + attempt.to_string()
    ignore(sim.schedule_at(tick, name))
    let failed = sim.next_int(100) < config.fail_percent
    if failed {
      sim.inc_counter("reliability_failure")
      if attempt < config.retry_limit {
        sim.inc_counter("reliability_retry")
        tick += config.backoff * (attempt + 1)
      } else {
        sim.inc_counter("reliability_exhausted")
        done = true
      }
    } else {
      sim.inc_counter("reliability_success")
      done = true
    }
    attempt += 1
  }
}

///|
pub fn ReliabilityResult::success_rate_percent(self : ReliabilityResult) -> Int {
  if self.operations == 0 {
    0
  } else {
    self.successes * 100 / self.operations
  }
}

///|
pub fn ReliabilityResult::summary(self : ReliabilityResult) -> ModelSummary {
  {
    name: "reliability",
    digest: self.digest,
    final_tick: self.final_tick,
    events: self.successes + self.failures + self.retries,
  }
}

///|
pub fn ReliabilityResult::line(self : ReliabilityResult) -> String {
  "operations=" + self.operations.to_string() +
  " success_rate=" + self.success_rate_percent().to_string() + "%" +
  " retries=" + self.retries.to_string() +
  " exhausted=" + self.exhausted.to_string() +
  " digest=" + self.digest.to_string()
}
