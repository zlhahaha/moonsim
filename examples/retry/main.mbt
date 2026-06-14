///|
fn main {
  let sim = @moonsim.Sim::new(seed=2026UL)
  let mut tick = 0
  let mut backoff = 1

  for attempt in 1..=4 {
    ignore(sim.schedule_at(tick, "attempt:" + attempt.to_string()))
    sim.inc_counter("attempts")
    let jitter = sim.next_int(2)
    if attempt < 3 {
      ignore(sim.schedule_at(tick, "attempt:" + attempt.to_string() + ":failed"))
      tick += backoff + jitter
      backoff = backoff * 2
      sim.inc_counter("retries")
    } else {
      ignore(sim.schedule_at(tick, "attempt:" + attempt.to_string() + ":succeeded"))
      sim.inc_counter("success")
      break
    }
  }

  ignore(sim.run_until_idle())
  println("retry simulation")
  println("attempts=" + sim.metrics().counter("attempts").to_string())
  println("retries=" + sim.metrics().counter("retries").to_string())
  println("success=" + sim.metrics().counter("success").to_string())
  println("events_executed=" + sim.metrics().counter("events_executed").to_string())
  println("final_tick=" + sim.time().to_string())
  println("digest=" + sim.digest().to_string())
}
