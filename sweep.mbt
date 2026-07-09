///|
pub(all) struct SweepPoint {
  name : String
  summary : ModelSummary
  score : Int
}

///|
pub(all) struct SweepReport {
  name : String
  mut points : Array[SweepPoint]
}

///|
pub fn sweep_point(
  name : String,
  summary : ModelSummary,
  score? : Int = 0,
) -> SweepPoint {
  { name, summary, score }
}

///|
pub fn SweepReport::new(name : String) -> SweepReport {
  { name, points: [] }
}

///|
pub fn SweepReport::add(self : SweepReport, point : SweepPoint) -> SweepReport {
  self.points.push(point)
  self
}

///|
pub fn SweepReport::count(self : SweepReport) -> Int {
  self.points.length()
}

///|
pub fn SweepReport::best_by_score(self : SweepReport) -> SweepPoint? {
  if self.points.length() == 0 {
    None
  } else {
    let mut best = self.points[0]
    for point in self.points {
      if point.score < best.score {
        best = point
      }
    }
    Some(best)
  }
}

///|
pub fn SweepReport::best_by_final_tick(self : SweepReport) -> SweepPoint? {
  if self.points.length() == 0 {
    None
  } else {
    let mut best = self.points[0]
    for point in self.points {
      if point.summary.final_tick < best.summary.final_tick {
        best = point
      }
    }
    Some(best)
  }
}

///|
pub fn SweepReport::combined_digest(self : SweepReport) -> UInt64 {
  let entries : Array[TraceEntry] = []
  for i in 0..<self.points.length() {
    let point = self.points[i]
    entries.push(
      trace_entry(
        i,
        i + 1,
        "sweep.point",
        point.name + ":" + point.summary.line(),
      ),
    )
  }
  trace_digest(entries)
}

///|
pub fn SweepReport::render(self : SweepReport) -> String {
  let buf = StringBuilder::new()
  buf.write_string("# Sweep " + self.name + "\n")
  buf.write_string("points=" + self.count().to_string() + "\n")
  buf.write_string("digest=" + self.combined_digest().to_string() + "\n")
  for point in self.points {
    buf.write_string(
      "- " +
      point.name +
      " score=" +
      point.score.to_string() +
      " " +
      point.summary.line() +
      "\n",
    )
  }
  match self.best_by_score() {
    None => ()
    Some(best) => buf.write_string("best_score=" + best.name + "\n")
  }
  buf.to_string()
}

///|
pub fn sweep_load_balancer_strategies(
  seed? : UInt64 = 808UL,
  jobs? : Int = 12,
) -> SweepReport {
  let least = run_load_balancer_model(
    load_balancer_config(seed~, jobs~, strategy="least_queue"),
  )
  let random = run_load_balancer_model(
    load_balancer_config(seed~, jobs~, strategy="random"),
  )
  let round = run_load_balancer_model(
    load_balancer_config(seed~, jobs~, strategy="round_robin"),
  )
  SweepReport::new("load_balancer")
  .add(
    sweep_point(
      "least_queue",
      load_balancer_summary(least),
      score=least.total_wait,
    ),
  )
  .add(
    sweep_point(
      "random",
      load_balancer_summary(random),
      score=random.total_wait,
    ),
  )
  .add(
    sweep_point(
      "round_robin",
      load_balancer_summary(round),
      score=round.total_wait,
    ),
  )
}

///|
pub fn sweep_reliability_failure_rates(seed? : UInt64 = 9090UL) -> SweepReport {
  let low = run_reliability_model(reliability_config(seed~, fail_percent=10))
  let mid = run_reliability_model(reliability_config(seed~, fail_percent=35))
  let high = run_reliability_model(reliability_config(seed~, fail_percent=70))
  SweepReport::new("reliability")
  .add(
    sweep_point(
      "fail_10",
      low.summary(),
      score=low.exhausted * 100 + low.retries,
    ),
  )
  .add(
    sweep_point(
      "fail_35",
      mid.summary(),
      score=mid.exhausted * 100 + mid.retries,
    ),
  )
  .add(
    sweep_point(
      "fail_70",
      high.summary(),
      score=high.exhausted * 100 + high.retries,
    ),
  )
}
