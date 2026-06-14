///|
fn main {
  let sim = @moonsim.Sim::new(seed=777UL)
  ignore(sim.install_timer(@moonsim.timer_plan("game:tick", interval=1, times=10)))
  let mut hp = 20
  for turn in 0..<10 {
    let damage = sim.next_range(1, 5)
    hp -= damage
    if hp < 0 {
      hp = 0
    }
    sim.sample("damage", damage)
    sim.set_gauge("hp", hp)
    ignore(sim.schedule_at(turn, "turn:" + turn.to_string() + ":damage:" + damage.to_string()))
  }
  let checkpoint = sim.snapshot(name="after_planning")
  let aggressive = checkpoint.fork("aggressive")
  let defensive = checkpoint.fork("defensive")
  aggressive.inc_counter("strategy_aggressive")
  defensive.inc_counter("strategy_defensive")
  ignore(aggressive.schedule_after(1, "strategy:attack"))
  ignore(defensive.schedule_after(1, "strategy:block"))
  ignore(aggressive.run_until_idle())
  ignore(defensive.run_until_idle())
  let comparison = @moonsim.compare_forks("aggressive", aggressive, "defensive", defensive)

  println("game loop simulation")
  println("hp=" + sim.metrics().gauge("hp").to_string())
  println("damage_samples=" + sim.metrics().sample_count("damage").to_string())
  println(comparison.summary())
}
