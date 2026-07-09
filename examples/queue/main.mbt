///|
fn main {
  let sim = @moonsim.Sim::new(seed=4096UL)
  let mut current_tick = 0
  let service_time = 3
  let mut last_finish = 0

  for customer in 0..<5 {
    let gap = sim.next_int(4) + 1
    current_tick += gap
    ignore(
      sim.schedule_at(
        current_tick,
        "customer:" + customer.to_string() + ":arrive",
      ),
    )
    let start = if current_tick > last_finish {
      current_tick
    } else {
      last_finish
    }
    let finish = start + service_time
    last_finish = finish
    ignore(
      sim.schedule_at(finish, "customer:" + customer.to_string() + ":finish"),
    )
    sim.inc_counter("customers")
  }

  ignore(sim.run_until_idle())
  println("queue simulation")
  println("customers=" + sim.metrics().counter("customers").to_string())
  println(
    "events_executed=" + sim.metrics().counter("events_executed").to_string(),
  )
  println("final_tick=" + sim.time().to_string())
  println("digest=" + sim.digest().to_string())
}
