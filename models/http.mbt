///|
/// The request metadata captured by an external HTTP integration test.
pub(all) struct HttpRequest {
  id : String
  http_method : String
  path : String
  attempt : Int
}

///|
/// A compact response summary. Bodies are deliberately not retained by default.
pub(all) struct HttpResponse {
  status : Int
  body_summary : String
}

///|
/// The externally observed terminal result of an HTTP exchange.
pub(all) enum HttpOutcome {
  Response(HttpResponse)
  ConnectionFailure(String)
  Cancelled
}

///|
/// One HTTP exchange recorded outside the simulator.
pub(all) struct RecordedHttpExchange {
  request : HttpRequest
  outcome : HttpOutcome
  started_tick : Int
  latency_ticks : Int
}

///|
/// Retry and reliability rules evaluated during a deterministic replay.
pub(all) struct HttpReliabilityPolicy {
  seed : UInt64
  timeout_ticks : Int
  retry_limit : Int
  backoff_ticks : Int
  rate_limit_per_tick : Int
  circuit_failure_threshold : Int
  circuit_reset_ticks : Int
  deadline_ticks : Int
  accept_late_success : Bool
}

///|
/// Optional deterministic changes applied to a recorded transport.
pub(all) struct HttpReplayOptions {
  latency_jitter : Int
  injected_failure_percent : Int
  reverse_same_tick_order : Bool
}

///|
/// A pure replay transport. It never opens a socket or invokes a real service.
pub(all) struct RecordedHttpTransport {
  scenario : String
  exchanges : Array[RecordedHttpExchange]
  options : HttpReplayOptions
}

///|
/// Aggregate result and evidence from a recorded HTTP replay.
pub(all) struct HttpReplayResult {
  policy : HttpReliabilityPolicy
  http_successes : Int
  on_time_successes : Int
  late_successes : Int
  late_success_accepted : Int
  failed : Int
  timed_out : Int
  connection_failures : Int
  cancelled : Int
  duplicate_processed : Int
  retry_limit_violations : Int
  rate_limited : Int
  circuit_rejected : Int
  deadline_misses : Int
  digest : UInt64
  invariants : InvariantReport
  trace : Array[TraceEntry]
}

///|
/// A reproducible failing sample that can be checked after a policy change.
pub(all) struct HttpFailureCase {
  scenario : String
  policy : HttpReliabilityPolicy
  seed : UInt64
  failed_rule : String
  digest : UInt64
  exchanges : Array[RecordedHttpExchange]
  options : HttpReplayOptions
}

///|
/// Build a recorded request. Attempts start at one.
pub fn http_request(
  id : String,
  http_method? : String = "GET",
  path? : String = "/",
  attempt? : Int = 1,
) -> HttpRequest {
  { id, http_method, path, attempt }
}

///|
/// Build a response summary suitable for deterministic replay.
pub fn http_response(status : Int, body_summary? : String = "") -> HttpResponse {
  { status, body_summary }
}

///|
/// Build an externally recorded exchange.
pub fn recorded_http_exchange(
  request : HttpRequest,
  outcome : HttpOutcome,
  started_tick? : Int = 0,
  latency_ticks? : Int = 0,
) -> RecordedHttpExchange {
  { request, outcome, started_tick, latency_ticks }
}

///|
/// Build a replay policy. A zero rate limit disables rate limiting.
pub fn http_reliability_policy(
  seed? : UInt64 = 2026UL,
  timeout_ticks? : Int = 5,
  retry_limit? : Int = 1,
  backoff_ticks? : Int = 1,
  rate_limit_per_tick? : Int = 0,
  circuit_failure_threshold? : Int = 3,
  circuit_reset_ticks? : Int = 10,
  deadline_ticks? : Int = 8,
  accept_late_success? : Bool = false,
) -> HttpReliabilityPolicy {
  {
    seed,
    timeout_ticks,
    retry_limit,
    backoff_ticks,
    rate_limit_per_tick,
    circuit_failure_threshold,
    circuit_reset_ticks,
    deadline_ticks,
    accept_late_success,
  }
}

///|
fn policy_with_seed(
  policy : HttpReliabilityPolicy,
  seed : UInt64,
) -> HttpReliabilityPolicy {
  {
    seed,
    timeout_ticks: policy.timeout_ticks,
    retry_limit: policy.retry_limit,
    backoff_ticks: policy.backoff_ticks,
    rate_limit_per_tick: policy.rate_limit_per_tick,
    circuit_failure_threshold: policy.circuit_failure_threshold,
    circuit_reset_ticks: policy.circuit_reset_ticks,
    deadline_ticks: policy.deadline_ticks,
    accept_late_success: policy.accept_late_success,
  }
}

///|
/// Build deterministic variation settings for a recorded transport.
pub fn http_replay_options(
  latency_jitter? : Int = 0,
  injected_failure_percent? : Int = 0,
  reverse_same_tick_order? : Bool = false,
) -> HttpReplayOptions {
  { latency_jitter, injected_failure_percent, reverse_same_tick_order }
}

///|
/// Create a transport from HTTP exchanges captured by an external test.
pub fn recorded_http_transport(
  scenario : String,
  exchanges : Array[RecordedHttpExchange],
  options? : HttpReplayOptions = http_replay_options(),
) -> RecordedHttpTransport {
  { scenario, exchanges, options }
}

///|
/// Replay the recording with virtual time and a deterministic seed.
pub fn RecordedHttpTransport::replay(
  self : RecordedHttpTransport,
  policy? : HttpReliabilityPolicy = http_reliability_policy(),
) -> HttpReplayResult {
  let sim = Sim::new(seed=policy.seed)
  let effective_latencies : Array[Int] = []
  let mut index = 0
  while index < self.exchanges.length() {
    let exchange = self.exchanges[index]
    let jitter = if self.options.latency_jitter <= 0 {
      0
    } else {
      sim.next_int(self.options.latency_jitter * 2 + 1) -
      self.options.latency_jitter
    }
    let latency = max_int(0, exchange.latency_ticks + jitter)
    effective_latencies.push(latency)
    let priority = if self.options.reverse_same_tick_order {
      -index
    } else {
      index
    }
    ignore(
      sim.schedule_at(
        exchange.started_tick + latency,
        "http.complete:" +
        exchange.request.id +
        ":" +
        exchange.request.attempt.to_string(),
        priority~,
      ),
    )
    index += 1
  }
  ignore(sim.run_until_idle())

  let order = replay_order(
    self.exchanges,
    effective_latencies,
    self.options.reverse_same_tick_order,
  )
  let mut http_successes = 0
  let mut on_time_successes = 0
  let mut late_successes = 0
  let mut late_success_accepted = 0
  let mut failed = 0
  let mut timed_out = 0
  let mut connection_failures = 0
  let mut cancelled = 0
  let mut duplicate_processed = 0
  let mut retry_limit_violations = 0
  let mut rate_limited = 0
  let mut circuit_rejected = 0
  let mut deadline_misses = 0
  let mut consecutive_failures = 0
  let mut circuit_open_until = -1
  let finalized : Array[String] = []

  for exchange_index in order {
    let exchange = self.exchanges[exchange_index]
    let latency = effective_latencies[exchange_index]
    let finish_tick = exchange.started_tick + latency
    if exchange.request.attempt > policy.retry_limit + 1 {
      retry_limit_violations += 1
      continue
    }
    if policy.rate_limit_per_tick > 0 &&
      started_at_count(self.exchanges, exchange_index) >
      policy.rate_limit_per_tick {
      rate_limited += 1
      continue
    }
    if exchange.started_tick < circuit_open_until {
      circuit_rejected += 1
      continue
    }
    let timed_out_now = latency > policy.timeout_ticks
    let deadline_missed = finish_tick >
      exchange.started_tick + policy.deadline_ticks
    if timed_out_now {
      timed_out += 1
    }
    if deadline_missed {
      deadline_misses += 1
    }
    let injected_failure = self.options.injected_failure_percent > 0 &&
      deterministic_percent(policy.seed, exchange_index) <
      self.options.injected_failure_percent
    let success = outcome_is_success(exchange.outcome) && !injected_failure
    if !success {
      failed += 1
      consecutive_failures += 1
      match exchange.outcome {
        ConnectionFailure(_) => connection_failures += 1
        Cancelled => cancelled += 1
        Response(_) => ()
      }
      if policy.circuit_failure_threshold > 0 &&
        consecutive_failures >= policy.circuit_failure_threshold {
        circuit_open_until = finish_tick + policy.circuit_reset_ticks
      }
      continue
    }
    http_successes += 1
    consecutive_failures = 0
    let late = timed_out_now || deadline_missed
    if late {
      late_successes += 1
      if policy.accept_late_success {
        late_success_accepted += 1
      } else {
        continue
      }
    } else {
      on_time_successes += 1
    }
    if string_exists(finalized, exchange.request.id) {
      duplicate_processed += 1
    } else {
      finalized.push(exchange.request.id)
    }
  }

  let trace = sim.trace()
  let report = InvariantReport::new("http replay")
    .add(
      invariant_check(
        "http_request_finalized_once",
        duplicate_processed == 0,
        detail="duplicate_processed=" + duplicate_processed.to_string(),
      ),
    )
    .add(
      invariant_check(
        "late_success_not_accepted",
        late_success_accepted == 0,
        detail="late_success_accepted=" + late_success_accepted.to_string(),
      ),
    )
    .add(
      invariant_check(
        "retry_limit_enforced",
        retry_limit_violations == 0,
        detail="retry_limit_violations=" + retry_limit_violations.to_string(),
      ),
    )
    .add(
      invariant_check(
        "trace_is_present",
        trace.length() >= self.exchanges.length(),
        detail="trace_events=" + trace.length().to_string(),
      ),
    )
  {
    policy,
    http_successes,
    on_time_successes,
    late_successes,
    late_success_accepted,
    failed,
    timed_out,
    connection_failures,
    cancelled,
    duplicate_processed,
    retry_limit_violations,
    rate_limited,
    circuit_rejected,
    deadline_misses,
    digest: trace_digest(trace),
    invariants: report,
    trace,
  }
}

///|
/// Return the first failed invariant as replayable evidence, if any.
pub fn RecordedHttpTransport::failure_case(
  self : RecordedHttpTransport,
  policy? : HttpReliabilityPolicy = http_reliability_policy(),
) -> HttpFailureCase? {
  let result = self.replay(policy~)
  for check in result.invariants.checks {
    if !check.passed {
      return Some({
        scenario: self.scenario,
        policy,
        seed: policy.seed,
        failed_rule: check.name,
        digest: result.digest,
        exchanges: self.exchanges,
        options: self.options,
      })
    }
  }
  None
}

///|
/// Replay the exact recording, seed, policy, and variation settings.
pub fn HttpFailureCase::replay(self : HttpFailureCase) -> HttpReplayResult {
  recorded_http_transport(self.scenario, self.exchanges, options=self.options).replay(
    policy=self.policy,
  )
}

///|
/// Recheck a failing recording with a revised policy and the original seed.
pub fn HttpFailureCase::verify_fixed_policy(
  self : HttpFailureCase,
  policy : HttpReliabilityPolicy,
) -> HttpReplayResult {
  let same_seed_policy = policy_with_seed(policy, self.seed)
  recorded_http_transport(self.scenario, self.exchanges, options=self.options).replay(
    policy=same_seed_policy,
  )
}

///|
/// Emit stable JSON evidence. This encoder only serializes the compact model types.
pub fn RecordedHttpTransport::to_json(
  self : RecordedHttpTransport,
  policy? : HttpReliabilityPolicy = http_reliability_policy(),
) -> String {
  let result = self.replay(policy~)
  let failed_rule = match self.failure_case(policy~) {
    Some(case) => case.failed_rule
    None => ""
  }
  let parts : Array[String] = []
  for exchange in self.exchanges {
    parts.push(
      "{\"id\":\"" +
      json_escape(exchange.request.id) +
      "\",\"method\":\"" +
      json_escape(exchange.request.http_method) +
      "\",\"path\":\"" +
      json_escape(exchange.request.path) +
      "\",\"attempt\":" +
      exchange.request.attempt.to_string() +
      ",\"started_tick\":" +
      exchange.started_tick.to_string() +
      ",\"latency_ticks\":" +
      exchange.latency_ticks.to_string() +
      ",\"outcome\":\"" +
      json_escape(outcome_summary(exchange.outcome)) +
      "\"}",
    )
  }
  "{\"scenario\":\"" +
  json_escape(self.scenario) +
  "\",\"seed\":" +
  policy.seed.to_string() +
  ",\"policy\":{\"timeout_ticks\":" +
  policy.timeout_ticks.to_string() +
  ",\"retry_limit\":" +
  policy.retry_limit.to_string() +
  ",\"deadline_ticks\":" +
  policy.deadline_ticks.to_string() +
  ",\"accept_late_success\":" +
  policy.accept_late_success.to_string() +
  "},\"exchanges\":[" +
  parts.join(",") +
  "],\"failed_rule\":\"" +
  json_escape(failed_rule) +
  "\",\"trace_digest\":\"" +
  result.digest.to_string() +
  "\"}"
}

///|
/// A small fixture showing a retry whose original request succeeds after its deadline.
pub fn retry_timeout_recording() -> RecordedHttpTransport {
  let first = http_request(
    "payment-42",
    http_method="POST",
    path="/payments",
    attempt=1,
  )
  let retry = http_request(
    "payment-42",
    http_method="POST",
    path="/payments",
    attempt=2,
  )
  recorded_http_transport("retry timeout late success", [
    recorded_http_exchange(
      first,
      Response(http_response(200, body_summary="late original success")),
      started_tick=0,
      latency_ticks=12,
    ),
    recorded_http_exchange(
      retry,
      Response(http_response(200, body_summary="retry success")),
      started_tick=6,
      latency_ticks=2,
    ),
  ])
}

///|
/// A deliberately unsafe policy used to demonstrate a detected invariant failure.
pub fn retry_timeout_fault_policy() -> HttpReliabilityPolicy {
  http_reliability_policy(
    seed=4242UL,
    timeout_ticks=5,
    retry_limit=1,
    deadline_ticks=8,
    accept_late_success=true,
  )
}

///|
/// The corrected policy rejects an original success that arrived after its deadline.
pub fn retry_timeout_fixed_policy() -> HttpReliabilityPolicy {
  http_reliability_policy(
    seed=4242UL,
    timeout_ticks=5,
    retry_limit=1,
    deadline_ticks=8,
    accept_late_success=false,
  )
}

///|
fn outcome_is_success(outcome : HttpOutcome) -> Bool {
  match outcome {
    Response(response) => response.status >= 200 && response.status < 300
    ConnectionFailure(_) | Cancelled => false
  }
}

///|
fn outcome_summary(outcome : HttpOutcome) -> String {
  match outcome {
    Response(response) =>
      "response:" + response.status.to_string() + ":" + response.body_summary
    ConnectionFailure(detail) => "connection_failure:" + detail
    Cancelled => "cancelled"
  }
}

///|
/// Projects recorded calls into the common external-call event representation.
pub fn RecordedHttpTransport::event_stream(
  self : RecordedHttpTransport,
) -> EventStream {
  let stream = EventStream::new()
  for exchange in self.exchanges {
    let correlation_id = "http:" + exchange.request.id
    let request_event = stream.record(
      @core.external_call_event_kind(),
      exchange.started_tick,
      "external.request",
      correlation_id~,
      source=exchange.request.http_method,
      target=exchange.request.path,
      payload="attempt=" + exchange.request.attempt.to_string(),
    )
    ignore(
      stream.record(
        @core.external_call_event_kind(),
        exchange.started_tick + exchange.latency_ticks,
        "external.response",
        correlation_id~,
        source="external",
        target=exchange.request.path,
        parent_id=request_event.id,
        payload=outcome_summary(exchange.outcome),
        failed=!outcome_is_success(exchange.outcome),
      ),
    )
  }
  stream
}

///|
fn started_at_count(
  exchanges : Array[RecordedHttpExchange],
  index : Int,
) -> Int {
  let mut count = 0
  let tick = exchanges[index].started_tick
  for exchange in exchanges {
    if exchange.started_tick == tick {
      count += 1
    }
  }
  count
}

///|
fn replay_order(
  exchanges : Array[RecordedHttpExchange],
  latencies : Array[Int],
  reverse_same_tick_order : Bool,
) -> Array[Int] {
  let remaining : Array[Int] = []
  for index in 0..<exchanges.length() {
    remaining.push(index)
  }
  let ordered : Array[Int] = []
  while remaining.length() > 0 {
    let mut best = 0
    let mut candidate = 1
    while candidate < remaining.length() {
      let current_index = remaining[candidate]
      let best_index = remaining[best]
      let current_tick = exchanges[current_index].started_tick +
        latencies[current_index]
      let best_tick = exchanges[best_index].started_tick + latencies[best_index]
      let same_tick_precedes = if reverse_same_tick_order {
        current_index > best_index
      } else {
        current_index < best_index
      }
      let earlier = current_tick < best_tick ||
        (current_tick == best_tick && same_tick_precedes)
      if earlier {
        best = candidate
      }
      candidate += 1
    }
    ordered.push(remaining[best])
    ignore(remaining.remove(best))
  }
  ordered
}

///|
fn deterministic_percent(seed : UInt64, index : Int) -> Int {
  let mixed = seed ^ (index.to_uint64() * 1103515245UL + 12345UL)
  (mixed % 100UL).to_int()
}

///|
fn string_exists(values : Array[String], target : String) -> Bool {
  for value in values {
    if value == target {
      return true
    }
  }
  false
}

///|
fn max_int(left : Int, right : Int) -> Int {
  if left > right {
    left
  } else {
    right
  }
}

///|
fn json_escape(value : String) -> String {
  value
  .replace_all(old="\\", new="\\\\")
  .replace_all(old="\"", new="\\\"")
  .replace_all(old="\n", new="\\n")
  .replace_all(old="\r", new="\\r")
  .replace_all(old="\t", new="\\t")
}
