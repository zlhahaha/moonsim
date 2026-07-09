///|
fn main {
  let result = @moonsim.run_service_resilience_suite(
    config=@moonsim.service_resilience_config(
      seed=2026UL,
      requests=32,
      fail_percent=6,
      drop_percent=2,
      min_success_percent=70,
    ),
  )
  println(@moonsim.render_service_resilience_report(result))
  let matrix = @moonsim.service_resilience_seed_matrix([2024UL, 2025UL, 2026UL])
  println(matrix.render())
}
