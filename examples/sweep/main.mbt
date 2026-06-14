///|
fn main {
  let lb = @moonsim.sweep_load_balancer_strategies(seed=808UL, jobs=12)
  let reliability = @moonsim.sweep_reliability_failure_rates(seed=9090UL)

  println("sweep simulation")
  println("load_balancer_points=" + lb.count().to_string())
  println("load_balancer_digest=" + lb.combined_digest().to_string())
  println("reliability_points=" + reliability.count().to_string())
  println("reliability_digest=" + reliability.combined_digest().to_string())
}
