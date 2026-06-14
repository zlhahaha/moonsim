///|
fn main {
  let circuit = @moonsim.run_circuit_breaker_model(seed=606UL, calls=12)
  let bucket = @moonsim.run_token_bucket_model(seed=7070UL, requests=14)

  println("resilience simulation")
  println("circuit_state=" + circuit.state)
  println("circuit_allowed=" + circuit.allowed.to_string())
  println("circuit_rejected=" + circuit.rejected.to_string())
  println("circuit_digest=" + circuit.digest.to_string())
  println("bucket_allowed=" + bucket.allowed.to_string())
  println("bucket_rejected=" + bucket.rejected.to_string())
  println("bucket_tokens=" + bucket.final_tokens.to_string())
  println("bucket_digest=" + bucket.digest.to_string())
}
