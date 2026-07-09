///|
pub fn render_metrics_report(metrics : Metrics) -> String {
  let buf = StringBuilder::new()
  buf.write_string("# Metrics\n")
  let counters = metrics.snapshot()
  for counter in counters {
    buf.write_string(
      "- counter " + counter.name + " = " + counter.value.to_string() + "\n",
    )
  }
  let gauges = metrics.gauge_snapshot()
  for gauge in gauges {
    buf.write_string(
      "- gauge " + gauge.name + " = " + gauge.value.to_string() + "\n",
    )
  }
  let samples = metrics.sample_snapshot()
  if samples.length() > 0 {
    buf.write_string("- samples = " + samples.length().to_string() + "\n")
  }
  buf.to_string()
}

///|
pub fn render_metric_diff(diff : MetricDiff) -> String {
  let buf = StringBuilder::new()
  buf.write_string("# Metric Diff\n")
  buf.write_string(diff.summary() + "\n")
  for delta in diff.counters {
    buf.write_string(
      "- counter " +
      delta.name +
      " before=" +
      delta.before.to_string() +
      " after=" +
      delta.after.to_string() +
      " delta=" +
      delta.delta.to_string() +
      "\n",
    )
  }
  for delta in diff.gauges {
    buf.write_string(
      "- gauge " +
      delta.name +
      " before=" +
      delta.before.to_string() +
      " after=" +
      delta.after.to_string() +
      " delta=" +
      delta.delta.to_string() +
      "\n",
    )
  }
  buf.to_string()
}

///|
pub fn render_sample_distribution(metrics : Metrics, name : String) -> String {
  let dist = metrics.distribution(name)
  "sample " +
  name +
  " count=" +
  dist.count.to_string() +
  " min=" +
  dist.min.to_string() +
  " max=" +
  dist.max.to_string() +
  " median=" +
  dist.median.to_string() +
  " p90=" +
  dist.p90.to_string()
}

///|
pub fn render_trace_report(
  entries : Array[TraceEntry],
  limit? : Int = 20,
) -> String {
  let buf = StringBuilder::new()
  let stats = trace_stats(entries)
  buf.write_string("# Trace\n")
  buf.write_string(stats.summary() + "\n")
  let max = if limit < entries.length() { limit } else { entries.length() }
  for i in 0..<max {
    buf.write_string("- " + entries[i].format() + "\n")
  }
  if entries.length() > max {
    buf.write_string(
      "- ... " + (entries.length() - max).to_string() + " more\n",
    )
  }
  buf.to_string()
}

///|
pub fn render_replay_comparison(comparison : ReplayComparison) -> String {
  let buf = StringBuilder::new()
  buf.write_string("# Replay " + comparison.name + "\n")
  buf.write_string(comparison.summary() + "\n")
  if !comparison.matched {
    buf.write_string(comparison.trace.summary() + "\n")
  }
  buf.to_string()
}

///|
pub fn render_sim_report(sim : Sim, title? : String = "Simulation") -> String {
  let buf = StringBuilder::new()
  buf.write_string("# " + title + "\n")
  buf.write_string("tick: " + sim.time().to_string() + "\n")
  buf.write_string("pending: " + sim.pending_count().to_string() + "\n")
  buf.write_string("digest: " + sim.digest().to_string() + "\n")
  buf.write_string("validation: " + sim.validate().summary() + "\n")
  buf.write_string("\n")
  buf.write_string(render_metrics_report(sim.metrics()))
  buf.write_string("\n")
  buf.write_string(render_trace_report(sim.trace(), limit=10))
  buf.to_string()
}

///|
pub fn render_scenario_report(report : ScenarioReport) -> String {
  let buf = StringBuilder::new()
  buf.write_string("# Scenario " + report.name + "\n")
  buf.write_string(report.summary() + "\n")
  if !report.passed {
    buf.write_string(report.failure_text() + "\n")
  }
  buf.to_string()
}

///|
pub fn render_scenario_suite_report(report : ScenarioSuiteReport) -> String {
  "# Scenario Suite " + report.name + "\n" + report.render()
}

///|
pub fn render_model_summaries(summaries : Array[ModelSummary]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("# Model Summaries\n")
  for summary in summaries {
    buf.write_string("- " + summary.line() + "\n")
  }
  buf.to_string()
}

///|
pub fn render_experiment_report(report : ExperimentReport) -> String {
  report.render()
}
