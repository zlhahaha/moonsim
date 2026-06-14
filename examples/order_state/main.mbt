///|
fn main {
  let sim = @moonsim.Sim::new(seed=515UL)
  let order = @moonsim.StateMachine::new("order", "created")
    .add(@moonsim.transition("created", "pay", "paid", action="charge"))
    .add(@moonsim.transition("paid", "ship", "shipped", action="notify"))
    .add(@moonsim.transition("shipped", "deliver", "delivered"))

  let events = ["pay", "ship", "refund", "deliver"]
  for i in 0..<events.length() {
    ignore(sim.schedule_at(i, "order:" + events[i]))
    let result = order.send(events[i])
    sim.record_transition(order, result)
  }
  ignore(sim.run_until_idle())

  println("order state simulation")
  println("state=" + order.state())
  println("accepted=" + sim.metrics().counter("state.accepted").to_string())
  println("rejected=" + sim.metrics().counter("state.rejected").to_string())
  println("history=" + order.history().length().to_string())
  println("digest=" + sim.digest().to_string())
}
