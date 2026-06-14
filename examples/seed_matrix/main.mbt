///|
fn main {
  let seeds = [1UL, 2UL, 3UL, 4UL]
  let retry = @moonsim.retry_seed_matrix(seeds)
  let network = @moonsim.network_seed_matrix(seeds)

  println("seed matrix simulation")
  println("retry_runs=" + retry.count().to_string())
  println("retry_digest=" + retry.combined_digest().to_string())
  println("network_runs=" + network.count().to_string())
  println("network_digest=" + network.combined_digest().to_string())
}
