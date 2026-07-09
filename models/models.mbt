///|
pub fn queue_config(
  seed? : UInt64 = 1UL,
  customers? : Int = 5,
  max_arrival_gap? : Int = 4,
  service_time? : Int = 3,
) -> @moonsim.QueueConfig {
  @moonsim.queue_config(seed~, customers~, max_arrival_gap~, service_time~)
}

///|
pub fn run_queue_model(config : @moonsim.QueueConfig) -> @moonsim.QueueResult {
  @moonsim.run_queue_model(config)
}

///|
pub fn retry_config(
  seed? : UInt64 = 1UL,
  max_attempts? : Int = 4,
  fail_until? : Int = 2,
  initial_backoff? : Int = 3,
  jitter? : Int = 2,
) -> @moonsim.RetryConfig {
  @moonsim.retry_config(
    seed~,
    max_attempts~,
    fail_until~,
    initial_backoff~,
    jitter~,
  )
}

///|
pub fn run_retry_model(config : @moonsim.RetryConfig) -> @moonsim.RetryResult {
  @moonsim.run_retry_model(config)
}

///|
pub fn network_config(
  seed? : UInt64 = 1UL,
  messages? : Int = 6,
  latency_min? : Int = 1,
  latency_max? : Int = 6,
  drop_percent? : Int = 20,
  retry_delay? : Int = 3,
) -> @moonsim.NetworkConfig {
  @moonsim.network_config(
    seed~,
    messages~,
    latency_min~,
    latency_max~,
    drop_percent~,
    retry_delay~,
  )
}

///|
pub fn run_network_model(
  config : @moonsim.NetworkConfig,
) -> @moonsim.NetworkResult {
  @moonsim.run_network_model(config)
}

///|
pub fn load_balancer_config(
  seed? : UInt64 = 1UL,
  jobs? : Int = 12,
  workers? : Int = 3,
  max_arrival_gap? : Int = 3,
  min_service? : Int = 2,
  max_service? : Int = 7,
  strategy? : String = "least-queue",
) -> @moonsim.LoadBalancerConfig {
  @moonsim.load_balancer_config(
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
  config : @moonsim.LoadBalancerConfig,
) -> @moonsim.LoadBalancerResult {
  @moonsim.run_load_balancer_model(config)
}

///|
pub fn service_resilience_config(
  seed? : UInt64 = 2026UL,
  requests? : Int = 18,
  workers? : Int = 3,
  queue_limit? : Int = 5,
  timeout_ticks? : Int = 12,
  retry_limit? : Int = 2,
  base_latency? : Int = 4,
  jitter? : Int = 5,
  fail_percent? : Int = 20,
  drop_percent? : Int = 10,
  rate_limit_capacity? : Int = 6,
  rate_limit_refill? : Int = 3,
  rate_limit_interval? : Int = 8,
  min_success_percent? : Int = 60,
) -> @moonsim.ServiceResilienceConfig {
  @moonsim.service_resilience_config(
    seed~,
    requests~,
    workers~,
    queue_limit~,
    timeout_ticks~,
    retry_limit~,
    base_latency~,
    jitter~,
    fail_percent~,
    drop_percent~,
    rate_limit_capacity~,
    rate_limit_refill~,
    rate_limit_interval~,
    min_success_percent~,
  )
}

///|
pub fn run_default_service_resilience_suite() -> @moonsim.ServiceResilienceResult {
  @moonsim.run_service_resilience_suite()
}

///|
pub fn run_service_resilience_suite(
  config : @moonsim.ServiceResilienceConfig,
) -> @moonsim.ServiceResilienceResult {
  @moonsim.run_service_resilience_suite(config~)
}

///|
pub fn service_resilience_seed_matrix(
  seeds : Array[UInt64],
) -> @moonsim.SeedMatrix {
  @moonsim.service_resilience_seed_matrix(seeds)
}
