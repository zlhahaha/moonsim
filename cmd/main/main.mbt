///|
fn main {
  println("moonsim showcase")
  println("")
  println(
    "Problem: retry and timeout failures are hard to reproduce with wall-clock tests.",
  )
  println(
    "moonsim turns them into seeded model runs with replayable digests and invariants.",
  )
  println("")
  let config = @moonsim.service_resilience_config(
    seed=2026UL,
    requests=32,
    fail_percent=6,
    drop_percent=2,
    min_success_percent=70,
  )
  let service = @moonsim.run_service_resilience_suite(config~)
  let replay = @moonsim.run_service_resilience_suite(config~)
  println("1. Service resilience scenario")
  println(
    "seed=" +
    config.seed.to_string() +
    " requests=" +
    config.requests.to_string(),
  )
  println(
    "success_rate=" +
    service.success_percent().to_string() +
    "% retries=" +
    service.retried.to_string() +
    " timeouts=" +
    service.timed_out.to_string() +
    " failed=" +
    service.failed.to_string(),
  )
  println("digest=" + service.digest.to_string())
  let invariant_status = if service.invariants.passed() {
    "pass"
  } else {
    "fail"
  }
  println("invariants=" + invariant_status)
  println(service.invariants.render())
  println("")
  println("2. Deterministic replay")
  println("first_digest=" + service.digest.to_string())
  println("replay_digest=" + replay.digest.to_string())
  let same_digest = if service.digest == replay.digest { "yes" } else { "no" }
  println("same_digest=" + same_digest)
  println("")
  println("3. Seed matrix")
  let matrix = @moonsim.service_resilience_seed_matrix([2024UL, 2025UL, 2026UL])
  println(matrix.render())
  println("")
  println("4. Full service report")
  println(@moonsim.render_service_resilience_report(service))
  println("")
  println("5. Minimal retry trace")
  let sim = @moonsim.Sim::new(seed=2026UL)
  ignore(sim.schedule_after(0, "request:start"))
  ignore(sim.schedule_after(2, "request:fail"))
  ignore(sim.schedule_after(5, "retry:scheduled"))
  ignore(sim.schedule_after(8, "request:success"))
  sim.inc_counter("requests")
  sim.inc_counter("retries")
  ignore(sim.run_until_idle())

  println("version=" + @moonsim.version())
  println(
    "events_executed=" + sim.metrics().counter("events_executed").to_string(),
  )
  println("requests=" + sim.metrics().counter("requests").to_string())
  println("retries=" + sim.metrics().counter("retries").to_string())
  println("digest=" + sim.digest().to_string())
  println("trace:")
  for entry in sim.trace() {
    println("  " + entry.format())
  }
  println("")
  println("6. Capability summary")
  println(@moonsim.render_feature_matrix())
}
