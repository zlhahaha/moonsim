///|
pub(all) struct FeatureCell {
  demo : String
  feature : String
  supported : Bool
}

///|
pub(all) struct FeatureMatrix {
  demos : Array[String]
  features : Array[String]
  cells : Array[FeatureCell]
}

///|
pub fn default_features() -> Array[String] {
  [
    "scheduler",
    "rng",
    "trace",
    "metrics",
    "timer",
    "snapshot",
    "message",
    "state-machine",
    "digest",
  ]
}

///|
pub fn build_feature_matrix() -> FeatureMatrix {
  let demos = demo_catalog()
  let features = default_features()
  let cells : Array[FeatureCell] = []
  let names : Array[String] = []
  for demo in demos {
    names.push(demo.name)
    for feature in features {
      cells.push({
        demo: demo.name,
        feature,
        supported: demo.has_feature(feature),
      })
    }
  }
  { demos: names, features, cells }
}

///|
pub fn FeatureMatrix::supports(self : FeatureMatrix, demo : String, feature : String) -> Bool {
  for cell in self.cells {
    if cell.demo == demo && cell.feature == feature {
      return cell.supported
    }
  }
  false
}

///|
pub fn FeatureMatrix::feature_count(self : FeatureMatrix, demo : String) -> Int {
  let mut count = 0
  for cell in self.cells {
    if cell.demo == demo && cell.supported {
      count += 1
    }
  }
  count
}

///|
pub fn FeatureMatrix::demo_count_for_feature(self : FeatureMatrix, feature : String) -> Int {
  let mut count = 0
  for cell in self.cells {
    if cell.feature == feature && cell.supported {
      count += 1
    }
  }
  count
}

///|
pub fn FeatureMatrix::render(self : FeatureMatrix) -> String {
  let buf = StringBuilder::new()
  buf.write_string("# Feature Matrix\n")
  for demo in self.demos {
    buf.write_string("- " + demo + ": ")
    let mut first = true
    for feature in self.features {
      if self.supports(demo, feature) {
        if !first {
          buf.write_string(", ")
        }
        buf.write_string(feature)
        first = false
      }
    }
    buf.write_string("\n")
  }
  buf.to_string()
}

///|
pub(all) struct FeatureCoverage {
  demo_count : Int
  feature_count : Int
  supported_cells : Int
  total_cells : Int
}

///|
pub fn FeatureCoverage::percent(self : FeatureCoverage) -> Int {
  if self.total_cells == 0 {
    0
  } else {
    self.supported_cells * 100 / self.total_cells
  }
}

///|
pub fn FeatureCoverage::line(self : FeatureCoverage) -> String {
  "demos=" + self.demo_count.to_string() +
  " features=" + self.feature_count.to_string() +
  " supported=" + self.supported_cells.to_string() +
  "/" + self.total_cells.to_string() +
  " coverage=" + self.percent().to_string() + "%"
}

///|
pub fn FeatureMatrix::coverage(self : FeatureMatrix) -> FeatureCoverage {
  let mut supported = 0
  for cell in self.cells {
    if cell.supported {
      supported += 1
    }
  }
  {
    demo_count: self.demos.length(),
    feature_count: self.features.length(),
    supported_cells: supported,
    total_cells: self.cells.length(),
  }
}

///|
pub fn render_feature_coverage() -> String {
  build_feature_matrix().coverage().line()
}

///|
pub fn render_feature_matrix() -> String {
  build_feature_matrix().render()
}
