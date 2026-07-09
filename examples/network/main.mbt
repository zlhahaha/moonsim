///|
fn main {
  let result = @moonsim.run_network_model(
    @moonsim.network_config(
      seed=707UL,
      messages=8,
      drop_percent=25,
      retry_delay=3,
    ),
  )

  println("network simulation")
  println("messages=" + result.messages.to_string())
  println("delivered=" + result.delivered.to_string())
  println("dropped=" + result.dropped.to_string())
  println("retries=" + result.retries.to_string())
  println("pending=" + result.pending.to_string())
  println("final_tick=" + result.final_tick.to_string())
  println("digest=" + result.digest.to_string())
}
