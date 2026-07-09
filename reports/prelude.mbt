///|
pub type Sim = @core.Sim

///|
pub type Metrics = @core.Metrics

///|
pub type MetricDiff = @core.MetricDiff

///|
pub type TraceEntry = @core.TraceEntry

///|
pub type TraceComparison = @core.TraceComparison

///|
pub type ReplayComparison = @core.ReplayComparison

///|
pub type ScenarioReport = @core.ScenarioReport

///|
pub type ScenarioSuiteReport = @core.ScenarioSuiteReport

///|
pub type ModelSummary = @models.ModelSummary

///|
pub type QueueConfig = @models.QueueConfig

///|
pub type QueueResult = @models.QueueResult

///|
pub type RetryConfig = @models.RetryConfig

///|
pub type RetryResult = @models.RetryResult

///|
pub type TrafficConfig = @models.TrafficConfig

///|
pub type TrafficResult = @models.TrafficResult

///|
pub type NetworkConfig = @models.NetworkConfig

///|
pub type NetworkResult = @models.NetworkResult

///|
pub type LoadBalancerConfig = @models.LoadBalancerConfig

///|
pub type LoadBalancerResult = @models.LoadBalancerResult

///|
pub type ReliabilityConfig = @models.ReliabilityConfig

///|
pub type ReliabilityResult = @models.ReliabilityResult

///|
pub type CircuitBreakerResult = @models.CircuitBreakerResult

///|
pub type TokenBucketResult = @models.TokenBucketResult

///|
pub type ServiceResilienceResult = @models.ServiceResilienceResult

///|
pub fn trace_entry(
  tick : Int,
  event_id : Int,
  kind : String,
  detail : String,
) -> TraceEntry {
  @core.trace_entry(tick, event_id, kind, detail)
}

///|
pub fn trace_digest(entries : Array[TraceEntry]) -> UInt64 {
  @core.trace_digest(entries)
}

///|
pub fn trace_stats(entries : Array[TraceEntry]) -> @core.TraceStats {
  @core.trace_stats(entries)
}

///|
pub fn compare_traces(
  left : Array[TraceEntry],
  right : Array[TraceEntry],
) -> TraceComparison {
  @core.compare_traces(left, right)
}

///|
pub fn queue_config(
  seed? : UInt64 = 42UL,
  customers? : Int = 8,
  max_arrival_gap? : Int = 3,
  service_time? : Int = 3,
) -> QueueConfig {
  @models.queue_config(seed~, customers~, max_arrival_gap~, service_time~)
}

///|
pub fn run_queue_model(config : QueueConfig) -> QueueResult {
  @models.run_queue_model(config)
}

///|
pub fn queue_summary(result : QueueResult) -> ModelSummary {
  @models.queue_summary(result)
}

///|
pub fn retry_config(
  seed? : UInt64 = 2026UL,
  max_attempts? : Int = 4,
  fail_until? : Int = 2,
  initial_backoff? : Int = 1,
  jitter? : Int = 1,
) -> RetryConfig {
  @models.retry_config(
    seed~,
    max_attempts~,
    fail_until~,
    initial_backoff~,
    jitter~,
  )
}

///|
pub fn run_retry_model(config : RetryConfig) -> RetryResult {
  @models.run_retry_model(config)
}

///|
pub fn retry_summary(result : RetryResult) -> ModelSummary {
  @models.retry_summary(result)
}

///|
pub fn traffic_config(
  seed? : UInt64 = 300UL,
  cycles? : Int = 8,
  cars? : Int = 12,
  cycle_ticks? : Int = 5,
) -> TrafficConfig {
  @models.traffic_config(seed~, cycles~, cars~, cycle_ticks~)
}

///|
pub fn run_traffic_model(config : TrafficConfig) -> TrafficResult {
  @models.run_traffic_model(config)
}

///|
pub fn traffic_summary(result : TrafficResult) -> ModelSummary {
  @models.traffic_summary(result)
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
  @models.network_config(
    seed~,
    messages~,
    latency_min~,
    latency_max~,
    drop_percent~,
    retry_delay~,
  )
}

///|
pub fn run_network_model(config : NetworkConfig) -> NetworkResult {
  @models.run_network_model(config)
}

///|
pub fn network_summary(result : NetworkResult) -> ModelSummary {
  @models.network_summary(result)
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
  @models.load_balancer_config(
    seed~,
    jobs~,
    workers~,
    max_arrival_gap~,
    min_service~,
    max_service~,
    strategy~,
  )
}

///|
pub fn run_load_balancer_model(
  config : LoadBalancerConfig,
) -> LoadBalancerResult {
  @models.run_load_balancer_model(config)
}

///|
pub fn load_balancer_summary(result : LoadBalancerResult) -> ModelSummary {
  @models.load_balancer_summary(result)
}

///|
pub fn reliability_config(
  seed? : UInt64 = 9090UL,
  operations? : Int = 10,
  fail_percent? : Int = 30,
  retry_limit? : Int = 2,
  backoff? : Int = 2,
) -> ReliabilityConfig {
  @models.reliability_config(
    seed~,
    operations~,
    fail_percent~,
    retry_limit~,
    backoff~,
  )
}

///|
pub fn run_reliability_model(config : ReliabilityConfig) -> ReliabilityResult {
  @models.run_reliability_model(config)
}

///|
pub fn run_circuit_breaker_model(
  seed? : UInt64 = 606UL,
  calls? : Int = 12,
) -> CircuitBreakerResult {
  @models.run_circuit_breaker_model(seed~, calls~)
}

///|
pub fn run_token_bucket_model(
  seed? : UInt64 = 7070UL,
  requests? : Int = 14,
) -> TokenBucketResult {
  @models.run_token_bucket_model(seed~, requests~)
}
