///|
fn main {
  let sim = @moonsim.Sim::new(seed=300UL)
  let states = ["green", "yellow", "red", "red"]
  ignore(sim.install_timer(@moonsim.timer_plan("light:cycle", start_after=0, interval=5, times=8)))

  for i in 0..<8 {
    let state = states[i % states.length()]
    ignore(sim.schedule_at(i * 5, "light:" + state))
    sim.set_gauge("phase_index", i)
    if state == "green" {
      sim.inc_counter("green_phases")
    } else if state == "red" {
      sim.inc_counter("red_phases")
    }
  }

  for car in 0..<12 {
    let arrive = sim.next_range(0, 40)
    ignore(sim.schedule_at(arrive, "car:" + car.to_string() + ":arrive"))
    sim.inc_counter("cars")
    sim.sample("arrival_tick", arrive)
  }

  ignore(sim.run_until_idle())
  let arrivals = sim.metrics().summary("arrival_tick")
  println("traffic simulation")
  println("cars=" + sim.metrics().counter("cars").to_string())
  println("green_phases=" + sim.metrics().counter("green_phases").to_string())
  println("red_phases=" + sim.metrics().counter("red_phases").to_string())
  println("arrival_min=" + arrivals.min.to_string())
  println("arrival_max=" + arrivals.max.to_string())
  println("events_executed=" + sim.metrics().counter("events_executed").to_string())
  println("digest=" + sim.digest().to_string())
}
