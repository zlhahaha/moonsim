///|
pub(all) struct DemoDescriptor {
  name : String
  command : String
  purpose : String
  features : Array[String]
}

///|
pub fn demo_descriptor(
  name : String,
  command : String,
  purpose : String,
  features : Array[String]
) -> DemoDescriptor {
  { name, command, purpose, features }
}

///|
pub fn demo_catalog() -> Array[DemoDescriptor] {
  [
    demo_descriptor(
      "cli",
      "moon run cmd/main",
      "retry-style trace and digest demo",
      ["scheduler", "trace", "metrics"],
    ),
    demo_descriptor(
      "queue",
      "moon run examples/queue",
      "single-server queue simulation",
      ["rng", "metrics", "digest"],
    ),
    demo_descriptor(
      "retry",
      "moon run examples/retry",
      "deterministic retry and backoff simulation",
      ["backoff", "rng", "trace"],
    ),
    demo_descriptor(
      "traffic",
      "moon run examples/traffic",
      "traffic light and vehicle arrival simulation",
      ["timer", "samples", "digest"],
    ),
    demo_descriptor(
      "game_loop",
      "moon run examples/game_loop",
      "fixed-tick game loop with snapshot forks",
      ["snapshot", "fork", "metrics"],
    ),
    demo_descriptor(
      "protocol",
      "moon run examples/protocol",
      "message delivery, drop, retry, and timer simulation",
      ["message", "timer", "metrics"],
    ),
    demo_descriptor(
      "order_state",
      "moon run examples/order_state",
      "state-machine transition validation",
      ["state-machine", "trace", "metrics"],
    ),
  ]
}

///|
pub fn demo_names() -> Array[String] {
  let names : Array[String] = []
  for demo in demo_catalog() {
    names.push(demo.name)
  }
  names
}

///|
pub fn find_demo(name : String) -> DemoDescriptor? {
  for demo in demo_catalog() {
    if demo.name == name {
      return Some(demo)
    }
  }
  None
}

///|
pub fn render_demo_catalog() -> String {
  let buf = StringBuilder::new()
  buf.write_string("# moonsim demos\n")
  for demo in demo_catalog() {
    buf.write_string("- " + demo.name + ": " + demo.command + "\n")
    buf.write_string("  " + demo.purpose + "\n")
    buf.write_string("  features: " + join_features(demo.features) + "\n")
  }
  buf.to_string()
}

///|
fn join_features(features : Array[String]) -> String {
  let buf = StringBuilder::new()
  for i in 0..<features.length() {
    if i > 0 {
      buf.write_string(", ")
    }
    buf.write_string(features[i])
  }
  buf.to_string()
}

///|
pub fn DemoDescriptor::has_feature(self : DemoDescriptor, feature : String) -> Bool {
  for item in self.features {
    if item == feature {
      return true
    }
  }
  false
}
