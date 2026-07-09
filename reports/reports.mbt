///|
pub fn render_sim_report(
  sim : @moonsim.Sim,
  title? : String = "Simulation",
) -> String {
  @moonsim.render_sim_report(sim, title~)
}

///|
pub fn render_trace_report(
  entries : Array[@moonsim.TraceEntry],
  limit? : Int = 12,
) -> String {
  @moonsim.render_trace_report(entries, limit~)
}

///|
pub fn render_metrics_report(metrics : @moonsim.Metrics) -> String {
  @moonsim.render_metrics_report(metrics)
}

///|
pub fn render_service_resilience_report(
  result : @moonsim.ServiceResilienceResult,
) -> String {
  @moonsim.render_service_resilience_report(result)
}

///|
pub fn render_feature_matrix() -> String {
  @moonsim.render_feature_matrix()
}

///|
pub fn render_feature_coverage() -> String {
  @moonsim.render_feature_coverage()
}

///|
pub fn render_demo_catalog() -> String {
  @moonsim.render_demo_catalog()
}

///|
pub fn build_feature_matrix() -> @moonsim.FeatureMatrix {
  @moonsim.build_feature_matrix()
}

///|
pub fn demo_catalog() -> Array[@moonsim.DemoDescriptor] {
  @moonsim.demo_catalog()
}
