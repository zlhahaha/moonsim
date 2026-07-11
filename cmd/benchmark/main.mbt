///|
fn run_case(events : Int) -> Unit {
  let sim = @moonsim.Sim::new(seed=2026UL)
  let started = @bench.monotonic_clock_start()
  let mut index = 0
  while index < events {
    ignore(sim.schedule_at(index % 997, "benchmark event", priority=index % 5))
    index = index + 1
  }
  let executed = sim.run_until_idle()
  let elapsed_us = @bench.monotonic_clock_end(started)
  let throughput = if elapsed_us <= 0.0 {
    0.0
  } else {
    events.to_double() * 1_000_000.0 / elapsed_us
  }
  println(
    "events=" +
    events.to_string() +
    " executed=" +
    executed.to_string() +
    " elapsed_us=" +
    elapsed_us.to_string() +
    " throughput_events_per_second=" +
    throughput.to_string() +
    " digest=" +
    sim.digest().to_string(),
  )
}

///|
fn main {
  println("moonsim scheduler benchmark")
  println(
    "测量包含事件入队和执行；不同机器的耗时不可直接比较。",
  )
  run_case(1_000)
  run_case(10_000)
  run_case(100_000)
}
