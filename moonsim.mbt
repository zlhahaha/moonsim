///|
pub type Tick = @core.Tick

///|
pub type Duration = @core.Duration

///|
pub type EventId = @core.EventId

///|
pub type ScheduledEvent = @core.ScheduledEvent

///|
pub type Rng = @core.Rng

///|
pub type WeightedChoice = @core.WeightedChoice

///|
pub type CounterSample = @core.CounterSample

///|
pub type Metrics = @core.Metrics

///|
pub type SampleSummary = @core.SampleSummary

///|
pub type SampleDistribution = @core.SampleDistribution

///|
pub type MetricSnapshot = @core.MetricSnapshot

///|
pub type MetricDelta = @core.MetricDelta

///|
pub type MetricDiff = @core.MetricDiff

///|
pub type TraceEntry = @core.TraceEntry

///|
pub type TraceMismatch = @core.TraceMismatch

///|
pub type TraceComparison = @core.TraceComparison

///|
pub type TraceQuery = @core.TraceQuery

///|
pub type TraceKindCount = @core.TraceKindCount

///|
pub type TraceQueryResult = @core.TraceQueryResult

///|
pub type TraceExpectation = @core.TraceExpectation

///|
pub type ReplayBaseline = @core.ReplayBaseline

///|
pub type ReplayComparison = @core.ReplayComparison

///|
pub type Sim = @core.Sim

///|
pub type RunStep = @core.RunStep

///|
pub type RunStopReason = @core.RunStopReason

///|
pub type RunReport = @core.RunReport

///|
pub type SimSnapshot = @core.SimSnapshot

///|
pub type ForkComparison = @core.ForkComparison

///|
pub type ScenarioExpectation = @core.ScenarioExpectation

///|
pub type ScenarioFailure = @core.ScenarioFailure

///|
pub type ScenarioReport = @core.ScenarioReport

///|
pub type Scenario = @core.Scenario

///|
pub type ScenarioCase = @core.ScenarioCase

///|
pub type ScenarioSuite = @core.ScenarioSuite

///|
pub type ScenarioSuiteReport = @core.ScenarioSuiteReport

///|
pub type IntRange = @core.IntRange

///|
pub type InvariantCheck = @core.InvariantCheck

///|
pub type InvariantReport = @core.InvariantReport

///|
pub type ValidationIssue = @core.ValidationIssue

///|
pub type ValidationReport = @core.ValidationReport

///|
pub type QueueStats = @core.QueueStats

///|
pub type TraceStats = @core.TraceStats

///|
pub type EventView = @core.EventView

///|
pub type Backoff = @core.Backoff

///|
pub type TimerPlan = @core.TimerPlan

///|
pub type TimelineBucket = @core.TimelineBucket

///|
pub type TimelineView = @core.TimelineView

///|
pub type Message = @core.Message

///|
pub type MessageBus = @core.MessageBus

///|
pub type Transition = @core.Transition

///|
pub type TransitionResult = @core.TransitionResult

///|
pub type StateMachine = @core.StateMachine

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
pub type ModelSummary = @models.ModelSummary

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
pub type CircuitBreakerConfig = @models.CircuitBreakerConfig

///|
pub type CircuitBreaker = @models.CircuitBreaker

///|
pub type CircuitBreakerResult = @models.CircuitBreakerResult

///|
pub type TokenBucket = @models.TokenBucket

///|
pub type TokenBucketResult = @models.TokenBucketResult

///|
pub type WorkflowTask = @models.WorkflowTask

///|
pub type WorkflowPlan = @models.WorkflowPlan

///|
pub type WorkflowTaskRun = @models.WorkflowTaskRun

///|
pub type WorkflowResult = @models.WorkflowResult

///|
pub type SeedRun = @models.SeedRun

///|
pub type SeedMatrix = @models.SeedMatrix

///|
pub type SeedMatrixComparison = @models.SeedMatrixComparison

///|
pub type ServiceResilienceConfig = @models.ServiceResilienceConfig

///|
pub type ServiceResilienceResult = @models.ServiceResilienceResult

///|
pub fn version() -> String {
  "0.1.0"
}

///|
pub fn tick(value : Int) -> Tick {
  @core.tick(value)
}

///|
pub fn duration(value : Int) -> Duration {
  @core.duration(value)
}

///|
pub fn event_id(value : Int) -> EventId {
  @core.event_id(value)
}

///|
pub fn weighted_choice(label : String, weight : Int) -> WeightedChoice {
  @core.weighted_choice(label, weight)
}

///|
pub fn compare_event(a : ScheduledEvent, b : ScheduledEvent) -> Int {
  @core.compare_event(a, b)
}

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
pub fn trace_to_text(entries : Array[TraceEntry]) -> String {
  @core.trace_to_text(entries)
}

///|
pub fn trace_query(
  kind? : String = "",
  detail? : String = "",
  min_tick? : Int = -1,
  max_tick? : Int = -1,
) -> TraceQuery {
  @core.trace_query(kind~, detail~, min_tick~, max_tick~)
}

///|
pub fn query_trace(
  entries : Array[TraceEntry],
  query : TraceQuery,
) -> TraceQueryResult {
  @core.query_trace(entries, query)
}

///|
pub fn trace_filter_kind(
  entries : Array[TraceEntry],
  kind : String,
) -> Array[TraceEntry] {
  @core.trace_filter_kind(entries, kind)
}

///|
pub fn trace_filter_detail(
  entries : Array[TraceEntry],
  needle : String,
) -> Array[TraceEntry] {
  @core.trace_filter_detail(entries, needle)
}

///|
pub fn trace_filter_tick_range(
  entries : Array[TraceEntry],
  min_tick : Int,
  max_tick : Int,
) -> Array[TraceEntry] {
  @core.trace_filter_tick_range(entries, min_tick, max_tick)
}

///|
pub fn trace_query_result(entries : Array[TraceEntry]) -> TraceQueryResult {
  @core.trace_query_result(entries)
}

///|
pub fn expect_trace_kind_count(
  entries : Array[TraceEntry],
  kind : String,
  expected : Int,
) -> TraceExpectation {
  @core.expect_trace_kind_count(entries, kind, expected)
}

///|
pub fn expect_trace_contains_kind(
  entries : Array[TraceEntry],
  kind : String,
) -> TraceExpectation {
  @core.expect_trace_contains_kind(entries, kind)
}

///|
pub fn expect_trace_contains_detail(
  entries : Array[TraceEntry],
  detail : String,
) -> TraceExpectation {
  @core.expect_trace_contains_detail(entries, detail)
}

///|
pub fn expect_trace_order(
  entries : Array[TraceEntry],
  before : String,
  after : String,
) -> TraceExpectation {
  @core.expect_trace_order(entries, before, after)
}

///|
pub fn expect_trace_monotonic_ticks(
  entries : Array[TraceEntry],
) -> TraceExpectation {
  @core.expect_trace_monotonic_ticks(entries)
}

///|
pub fn expect_trace_digest(
  entries : Array[TraceEntry],
  expected : UInt64,
) -> TraceExpectation {
  @core.expect_trace_digest(entries, expected)
}

///|
pub fn compare_traces(
  expected : Array[TraceEntry],
  actual : Array[TraceEntry],
) -> TraceComparison {
  @core.compare_traces(expected, actual)
}

///|
pub fn replay_baseline(name : String, sim : Sim) -> ReplayBaseline {
  @core.replay_baseline(name, sim)
}

///|
pub fn compare_replay(baseline : ReplayBaseline, sim : Sim) -> ReplayComparison {
  @core.compare_replay(baseline, sim)
}

///|
pub fn trace_digest(entries : Array[TraceEntry]) -> UInt64 {
  @core.trace_digest(entries)
}

///|
pub fn diff_metrics(
  before : MetricSnapshot,
  after : MetricSnapshot,
) -> MetricDiff {
  @core.diff_metrics(before, after)
}

///|
pub fn metrics_counter_delta(
  left : Metrics,
  right : Metrics,
  name : String,
) -> Int {
  @core.metrics_counter_delta(left, right, name)
}

///|
pub fn compare_forks(
  left_name : String,
  left : Sim,
  right_name : String,
  right : Sim,
) -> ForkComparison {
  @core.compare_forks(left_name, left, right_name, right)
}

///|
pub fn invariant_check(
  name : String,
  passed : Bool,
  detail? : String = "",
) -> InvariantCheck {
  @core.invariant_check(name, passed, detail~)
}

///|
pub fn check_sim_invariants(sim : Sim) -> InvariantReport {
  @core.check_sim_invariants(sim)
}

///|
pub fn check_counter_at_least(
  sim : Sim,
  name : String,
  expected : Int,
) -> InvariantCheck {
  @core.check_counter_at_least(sim, name, expected)
}

///|
pub fn check_no_pending(sim : Sim) -> InvariantCheck {
  @core.check_no_pending(sim)
}

///|
pub fn validation_issue(
  code : String,
  message : String,
  severity? : String = "error",
) -> ValidationIssue {
  @core.validation_issue(code, message, severity~)
}

///|
pub fn validate_sim(sim : Sim) -> ValidationReport {
  @core.validate_sim(sim)
}

///|
pub fn validate_trace(entries : Array[TraceEntry]) -> ValidationReport {
  @core.validate_trace(entries)
}

///|
pub fn validate_metrics(metrics : Metrics) -> ValidationReport {
  @core.validate_metrics(metrics)
}

///|
pub fn trace_stats(entries : Array[TraceEntry]) -> TraceStats {
  @core.trace_stats(entries)
}

///|
pub fn build_timeline(
  entries : Array[TraceEntry],
  bucket_size? : Int = 5,
) -> TimelineView {
  @core.build_timeline(entries, bucket_size~)
}

///|
pub fn timer_plan(
  name : String,
  start_after? : Int = 0,
  interval? : Int = 1,
  times? : Int = 1,
  priority? : Int = 0,
) -> TimerPlan {
  @core.timer_plan(name, start_after~, interval~, times~, priority~)
}

///|
pub fn transition(
  from : String,
  event : String,
  to : String,
  action? : String = "",
) -> Transition {
  @core.transition(from, event, to, action~)
}

///|
pub fn queue_config(
  seed? : UInt64 = 4096UL,
  customers? : Int = 5,
  max_arrival_gap? : Int = 4,
  service_time? : Int = 3,
) -> QueueConfig {
  @models.queue_config(seed~, customers~, max_arrival_gap~, service_time~)
}

///|
pub fn run_queue_model(config : QueueConfig) -> QueueResult {
  @models.run_queue_model(config)
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
pub fn queue_summary(result : QueueResult) -> ModelSummary {
  @models.queue_summary(result)
}

///|
pub fn retry_summary(result : RetryResult) -> ModelSummary {
  @models.retry_summary(result)
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
pub fn circuit_breaker_config(
  failure_threshold? : Int = 3,
  reset_timeout? : Int = 5,
  half_open_successes? : Int = 2,
) -> CircuitBreakerConfig {
  @models.circuit_breaker_config(
    failure_threshold~,
    reset_timeout~,
    half_open_successes~,
  )
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

///|
pub fn run_workflow_model(
  plan : WorkflowPlan,
  seed? : UInt64 = 515UL,
) -> WorkflowResult {
  @models.run_workflow_model(plan, seed~)
}

///|
pub fn workflow_critical_path(plan : WorkflowPlan) -> Int {
  @models.workflow_critical_path(plan)
}

///|
pub fn seed_run(seed : UInt64, summary : ModelSummary) -> SeedRun {
  @models.seed_run(seed, summary)
}

///|
pub fn compare_seed_matrices(
  left : SeedMatrix,
  right : SeedMatrix,
) -> SeedMatrixComparison {
  @models.compare_seed_matrices(left, right)
}

///|
pub fn retry_seed_matrix(seeds : Array[UInt64]) -> SeedMatrix {
  @models.retry_seed_matrix(seeds)
}

///|
pub fn network_seed_matrix(seeds : Array[UInt64]) -> SeedMatrix {
  @models.network_seed_matrix(seeds)
}

///|
pub fn load_balancer_seed_matrix(
  seeds : Array[UInt64],
  strategy? : String = "least_queue",
) -> SeedMatrix {
  @models.load_balancer_seed_matrix(seeds, strategy~)
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
  @models.service_resilience_config(
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
pub fn run_service_resilience_suite(
  config? : ServiceResilienceConfig = service_resilience_config(),
) -> ServiceResilienceResult {
  @models.run_service_resilience_suite(config~)
}

///|
pub fn render_service_resilience_report(
  result : ServiceResilienceResult,
) -> String {
  @models.render_service_resilience_report(result)
}

///|
pub fn service_resilience_seed_matrix(seeds : Array[UInt64]) -> SeedMatrix {
  @models.service_resilience_seed_matrix(seeds)
}

///|
pub type DemoDescriptor = @reports.DemoDescriptor

///|
pub type FeatureCell = @reports.FeatureCell

///|
pub type FeatureMatrix = @reports.FeatureMatrix

///|
pub type FeatureCoverage = @reports.FeatureCoverage

///|
pub type ExperimentCase = @reports.ExperimentCase

///|
pub type ExperimentReport = @reports.ExperimentReport

///|
pub type SweepPoint = @reports.SweepPoint

///|
pub type SweepReport = @reports.SweepReport

///|
pub fn demo_descriptor(
  name : String,
  command : String,
  purpose : String,
  features : Array[String],
) -> DemoDescriptor {
  @reports.demo_descriptor(name, command, purpose, features)
}

///|
pub fn demo_catalog() -> Array[DemoDescriptor] {
  @reports.demo_catalog()
}

///|
pub fn demo_names() -> Array[String] {
  @reports.demo_names()
}

///|
pub fn find_demo(name : String) -> DemoDescriptor? {
  @reports.find_demo(name)
}

///|
pub fn render_demo_catalog() -> String {
  @reports.render_demo_catalog()
}

///|
pub fn default_features() -> Array[String] {
  @reports.default_features()
}

///|
pub fn build_feature_matrix() -> FeatureMatrix {
  @reports.build_feature_matrix()
}

///|
pub fn render_feature_coverage() -> String {
  @reports.render_feature_coverage()
}

///|
pub fn render_feature_matrix() -> String {
  @reports.render_feature_matrix()
}

///|
pub fn experiment_case(
  name : String,
  summary : ModelSummary,
  notes? : String = "",
) -> ExperimentCase {
  @reports.experiment_case(name, summary, notes~)
}

///|
pub fn demo_experiment() -> ExperimentReport {
  @reports.demo_experiment()
}

///|
pub fn compare_experiments(
  left : ExperimentReport,
  right : ExperimentReport,
) -> TraceComparison {
  @reports.compare_experiments(left, right)
}

///|
pub fn sweep_point(
  name : String,
  summary : ModelSummary,
  score? : Int = 0,
) -> SweepPoint {
  @reports.sweep_point(name, summary, score~)
}

///|
pub fn sweep_load_balancer_strategies(
  seed? : UInt64 = 808UL,
  jobs? : Int = 12,
) -> SweepReport {
  @reports.sweep_load_balancer_strategies(seed~, jobs~)
}

///|
pub fn sweep_reliability_failure_rates(seed? : UInt64 = 9090UL) -> SweepReport {
  @reports.sweep_reliability_failure_rates(seed~)
}

///|
pub fn render_metrics_report(metrics : Metrics) -> String {
  @reports.render_metrics_report(metrics)
}

///|
pub fn render_metric_diff(diff : MetricDiff) -> String {
  @reports.render_metric_diff(diff)
}

///|
pub fn render_sample_distribution(metrics : Metrics, name : String) -> String {
  @reports.render_sample_distribution(metrics, name)
}

///|
pub fn render_trace_report(
  entries : Array[TraceEntry],
  limit? : Int = 20,
) -> String {
  @reports.render_trace_report(entries, limit~)
}

///|
pub fn render_replay_comparison(comparison : ReplayComparison) -> String {
  @reports.render_replay_comparison(comparison)
}

///|
pub fn render_sim_report(sim : Sim, title? : String = "Simulation") -> String {
  @reports.render_sim_report(sim, title~)
}

///|
pub fn render_scenario_report(report : ScenarioReport) -> String {
  @reports.render_scenario_report(report)
}

///|
pub fn render_scenario_suite_report(report : ScenarioSuiteReport) -> String {
  @reports.render_scenario_suite_report(report)
}

///|
pub fn render_model_summaries(summaries : Array[ModelSummary]) -> String {
  @reports.render_model_summaries(summaries)
}

///|
pub fn render_experiment_report(report : ExperimentReport) -> String {
  @reports.render_experiment_report(report)
}
