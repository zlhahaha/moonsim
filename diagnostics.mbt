///|
pub(all) struct QueueStats {
  pending : Int
  cancelled : Int
  earliest_tick : Int
  latest_tick : Int
}

///|
pub(all) struct TraceStats {
  entries : Int
  schedules : Int
  executions : Int
  cancellations : Int
  rng_draws : Int
  metrics : Int
  messages : Int
}

///|
pub(all) struct EventView {
  id : Int
  tick : Int
  priority : Int
  name : String
  status : String
}

///|
pub fn Sim::queue_stats(self : Sim) -> QueueStats {
  let mut pending = 0
  let mut cancelled = 0
  let mut earliest = 0
  let mut latest = 0
  let mut seen = false
  for event in self.events {
    if event.cancelled {
      cancelled += 1
    } else {
      pending += 1
      if !seen {
        earliest = event.tick
        latest = event.tick
        seen = true
      } else {
        if event.tick < earliest {
          earliest = event.tick
        }
        if event.tick > latest {
          latest = event.tick
        }
      }
    }
  }
  { pending, cancelled, earliest_tick: earliest, latest_tick: latest }
}

///|
pub fn Sim::event_views(self : Sim) -> Array[EventView] {
  let views : Array[EventView] = []
  for event in self.events {
    views.push({
      id: event.id,
      tick: event.tick,
      priority: event.priority,
      name: event.name,
      status: if event.cancelled {
        "cancelled"
      } else {
        "pending"
      },
    })
  }
  views.sort_by(fn(a, b) {
    let order = a.tick.compare(b.tick)
    if order != 0 {
      order
    } else {
      a.id.compare(b.id)
    }
  })
  views
}

///|
pub fn trace_stats(entries : Array[TraceEntry]) -> TraceStats {
  let mut schedules = 0
  let mut executions = 0
  let mut cancellations = 0
  let mut rng_draws = 0
  let mut metrics = 0
  let mut messages = 0
  for entry in entries {
    if entry.kind.contains("schedule") {
      schedules += 1
    }
    if entry.kind == "execute" {
      executions += 1
    }
    if entry.kind == "cancel" {
      cancellations += 1
    }
    if entry.kind.contains("rng.") {
      rng_draws += 1
    }
    if entry.kind.contains("metric.") {
      metrics += 1
    }
    if entry.kind.contains("message.") {
      messages += 1
    }
  }
  {
    entries: entries.length(),
    schedules,
    executions,
    cancellations,
    rng_draws,
    metrics,
    messages,
  }
}

///|
pub fn TraceStats::summary(self : TraceStats) -> String {
  "entries=" +
  self.entries.to_string() +
  " schedules=" +
  self.schedules.to_string() +
  " executions=" +
  self.executions.to_string() +
  " cancellations=" +
  self.cancellations.to_string() +
  " rng=" +
  self.rng_draws.to_string() +
  " metrics=" +
  self.metrics.to_string() +
  " messages=" +
  self.messages.to_string()
}

///|
pub fn Sim::trace_stats(self : Sim) -> TraceStats {
  trace_stats(self.trace_entries)
}

///|
pub fn Sim::timeline_text(self : Sim) -> String {
  let views = self.event_views()
  let buf = StringBuilder::new()
  for i in 0..<views.length() {
    if i > 0 {
      buf.write_string("\n")
    }
    let view = views[i]
    buf.write_string(
      view.tick.to_string() +
      ":" +
      view.id.to_string() +
      ":" +
      view.status +
      ":" +
      view.name,
    )
  }
  buf.to_string()
}
