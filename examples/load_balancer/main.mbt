///|
fn main {
  let least = @moonsim.run_load_balancer_model(@moonsim.load_balancer_config(
    seed=808UL,
    strategy="least_queue",
  ))
  let random = @moonsim.run_load_balancer_model(@moonsim.load_balancer_config(
    seed=808UL,
    strategy="random",
  ))

  println("load balancer simulation")
  println("least_queue_jobs=" + least.jobs.to_string())
  println("least_queue_final_tick=" + least.final_tick.to_string())
  println("least_queue_total_wait=" + least.total_wait.to_string())
  println("least_queue_digest=" + least.digest.to_string())
  println("random_final_tick=" + random.final_tick.to_string())
  println("random_total_wait=" + random.total_wait.to_string())
  println("random_digest=" + random.digest.to_string())
}
