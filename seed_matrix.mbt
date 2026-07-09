///|
pub(all) struct SeedRun {
  seed : UInt64
  summary : ModelSummary
}

///|
pub(all) struct SeedMatrix {
  name : String
  runs : Array[SeedRun]
}

///|
pub(all) struct SeedMatrixComparison {
  left_name : String
  right_name : String
  same_digest : Bool
  same_count : Bool
  left_digest : UInt64
  right_digest : UInt64
  left_count : Int
  right_count : Int
}

///|
pub fn seed_run(seed : UInt64, summary : ModelSummary) -> SeedRun {
  { seed, summary }
}

///|
pub fn SeedMatrix::new(name : String) -> SeedMatrix {
  { name, runs: [] }
}

///|
pub fn SeedMatrix::add(self : SeedMatrix, run : SeedRun) -> SeedMatrix {
  self.runs.push(run)
  self
}

///|
pub fn SeedMatrix::count(self : SeedMatrix) -> Int {
  self.runs.length()
}

///|
pub fn SeedMatrix::is_empty(self : SeedMatrix) -> Bool {
  self.runs.length() == 0
}

///|
pub fn SeedMatrix::has_seed(self : SeedMatrix, seed : UInt64) -> Bool {
  for run in self.runs {
    if run.seed == seed {
      return true
    }
  }
  false
}

///|
pub fn SeedMatrix::combined_digest(self : SeedMatrix) -> UInt64 {
  let entries : Array[TraceEntry] = []
  for i in 0..<self.runs.length() {
    let run = self.runs[i]
    entries.push(
      trace_entry(
        i,
        i + 1,
        "seed.run",
        run.seed.to_string() + ":" + run.summary.line(),
      ),
    )
  }
  trace_digest(entries)
}

///|
pub fn SeedMatrix::max_final_tick(self : SeedMatrix) -> Int {
  let mut max = 0
  for run in self.runs {
    if run.summary.final_tick > max {
      max = run.summary.final_tick
    }
  }
  max
}

///|
pub fn SeedMatrix::total_events(self : SeedMatrix) -> Int {
  let mut total = 0
  for run in self.runs {
    total += run.summary.events
  }
  total
}

///|
pub fn SeedMatrix::slowest(self : SeedMatrix) -> SeedRun? {
  if self.runs.length() == 0 {
    None
  } else {
    let mut best = self.runs[0]
    for run in self.runs {
      if run.summary.final_tick > best.summary.final_tick {
        best = run
      }
    }
    Some(best)
  }
}

///|
pub fn SeedMatrix::fastest(self : SeedMatrix) -> SeedRun? {
  if self.runs.length() == 0 {
    None
  } else {
    let mut best = self.runs[0]
    for run in self.runs {
      if run.summary.final_tick < best.summary.final_tick {
        best = run
      }
    }
    Some(best)
  }
}

///|
pub fn SeedMatrix::unique_digests(self : SeedMatrix) -> Int {
  let digests : Array[UInt64] = []
  for run in self.runs {
    if !uint64_array_contains(digests, run.summary.digest) {
      digests.push(run.summary.digest)
    }
  }
  digests.length()
}

///|
fn uint64_array_contains(items : Array[UInt64], value : UInt64) -> Bool {
  for item in items {
    if item == value {
      return true
    }
  }
  false
}

///|
pub fn SeedMatrix::tick_span(self : SeedMatrix) -> Int {
  match (self.fastest(), self.slowest()) {
    (Some(fast), Some(slow)) =>
      slow.summary.final_tick - fast.summary.final_tick
    _ => 0
  }
}

///|
pub fn SeedMatrix::summary_line(self : SeedMatrix) -> String {
  self.name +
  " runs=" +
  self.count().to_string() +
  " unique_digests=" +
  self.unique_digests().to_string() +
  " max_tick=" +
  self.max_final_tick().to_string() +
  " tick_span=" +
  self.tick_span().to_string()
}

///|
pub fn SeedMatrix::lines(self : SeedMatrix) -> Array[String] {
  let lines : Array[String] = []
  for run in self.runs {
    lines.push("seed=" + run.seed.to_string() + " " + run.summary.line())
  }
  lines
}

///|
pub fn compare_seed_matrices(
  left : SeedMatrix,
  right : SeedMatrix,
) -> SeedMatrixComparison {
  {
    left_name: left.name,
    right_name: right.name,
    same_digest: left.combined_digest() == right.combined_digest(),
    same_count: left.count() == right.count(),
    left_digest: left.combined_digest(),
    right_digest: right.combined_digest(),
    left_count: left.count(),
    right_count: right.count(),
  }
}

///|
pub fn SeedMatrixComparison::matched(self : SeedMatrixComparison) -> Bool {
  self.same_digest && self.same_count
}

///|
pub fn SeedMatrixComparison::is_stable(self : SeedMatrixComparison) -> Bool {
  self.matched()
}

///|
pub fn SeedMatrixComparison::digest_changed(
  self : SeedMatrixComparison,
) -> Bool {
  !self.same_digest
}

///|
pub fn SeedMatrixComparison::count_changed(self : SeedMatrixComparison) -> Bool {
  !self.same_count
}

///|
pub fn SeedMatrixComparison::fully_changed(self : SeedMatrixComparison) -> Bool {
  self.digest_changed() && self.count_changed()
}

///|
pub fn SeedMatrixComparison::summary(self : SeedMatrixComparison) -> String {
  let status = if self.matched() { "matched" } else { "mismatch" }
  status +
  " left=" +
  self.left_name +
  " right=" +
  self.right_name +
  " left_count=" +
  self.left_count.to_string() +
  " right_count=" +
  self.right_count.to_string() +
  " left_digest=" +
  self.left_digest.to_string() +
  " right_digest=" +
  self.right_digest.to_string()
}

///|
pub fn SeedMatrix::render(self : SeedMatrix) -> String {
  let buf = StringBuilder::new()
  buf.write_string("# Seed Matrix " + self.name + "\n")
  buf.write_string(self.summary_line() + "\n")
  buf.write_string("events=" + self.total_events().to_string() + "\n")
  buf.write_string("digest=" + self.combined_digest().to_string() + "\n")
  for line in self.lines() {
    buf.write_string("- " + line + "\n")
  }
  match self.fastest() {
    None => ()
    Some(run) => buf.write_string("fastest_seed=" + run.seed.to_string() + "\n")
  }
  match self.slowest() {
    None => ()
    Some(run) => buf.write_string("slowest_seed=" + run.seed.to_string() + "\n")
  }
  buf.to_string()
}

///|
pub fn retry_seed_matrix(seeds : Array[UInt64]) -> SeedMatrix {
  let matrix = SeedMatrix::new("retry")
  for seed in seeds {
    ignore(
      matrix.add(
        seed_run(seed, retry_summary(run_retry_model(retry_config(seed~)))),
      ),
    )
  }
  matrix
}

///|
pub fn network_seed_matrix(seeds : Array[UInt64]) -> SeedMatrix {
  let matrix = SeedMatrix::new("network")
  for seed in seeds {
    ignore(
      matrix.add(
        seed_run(
          seed,
          network_summary(run_network_model(network_config(seed~))),
        ),
      ),
    )
  }
  matrix
}

///|
pub fn load_balancer_seed_matrix(
  seeds : Array[UInt64],
  strategy? : String = "least_queue",
) -> SeedMatrix {
  let matrix = SeedMatrix::new("load_balancer:" + strategy)
  for seed in seeds {
    ignore(
      matrix.add(
        seed_run(
          seed,
          load_balancer_summary(
            run_load_balancer_model(load_balancer_config(seed~, strategy~)),
          ),
        ),
      ),
    )
  }
  matrix
}
