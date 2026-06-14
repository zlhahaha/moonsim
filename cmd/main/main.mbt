///|
fn main {
  let sim = @moonsim.Sim::new(seed=2026UL)
  ignore(sim.schedule_after(0, "request:start"))
  ignore(sim.schedule_after(2, "request:fail"))
  ignore(sim.schedule_after(5, "retry:scheduled"))
  ignore(sim.schedule_after(8, "request:success"))
  sim.inc_counter("requests")
  sim.inc_counter("retries")
  ignore(sim.run_until_idle())

  println("moonsim demo")
  println("version=" + @moonsim.version())
  println("events_executed=" + sim.metrics().counter("events_executed").to_string())
  println("requests=" + sim.metrics().counter("requests").to_string())
  println("retries=" + sim.metrics().counter("retries").to_string())
  println("digest=" + sim.digest().to_string())
  println("trace:")
  for entry in sim.trace() {
    println("  " + entry.format())
  }
}
