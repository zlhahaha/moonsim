///|
fn main {
  let sim = @moonsim.Sim::new(seed=909UL)
  let bus = @moonsim.MessageBus::new()
  let heartbeat = @moonsim.timer_plan("heartbeat", interval=3, times=4)
  ignore(sim.install_timer(heartbeat))
  let first = bus.send(sim, "client", "server", "hello", delay=2)
  ignore(bus.send(sim, "server", "client", "ack", delay=5))
  ignore(bus.drop(sim, first))
  ignore(bus.send(sim, "client", "server", "retry-hello", delay=6))
  ignore(sim.run_until_tick(10))
  ignore(bus.deliver_due(sim))

  println("message protocol simulation")
  println("messages=" + bus.messages().length().to_string())
  println("pending_messages=" + bus.pending(sim).to_string())
  println(
    "delivered=" + sim.metrics().counter("messages_delivered").to_string(),
  )
  println("dropped=" + sim.metrics().counter("messages_dropped").to_string())
  println("digest=" + sim.digest().to_string())
}
