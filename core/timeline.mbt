///|
pub(all) struct TimelineBucket {
  start_tick : Int
  end_tick : Int
  mut events : Int
  mut executions : Int
  mut metrics : Int
  mut messages : Int
}

///|
pub(all) struct TimelineView {
  bucket_size : Int
  buckets : Array[TimelineBucket]
}

///|
pub fn build_timeline(
  entries : Array[TraceEntry],
  bucket_size? : Int = 5,
) -> TimelineView {
  let size = if bucket_size < 1 { 1 } else { bucket_size }
  let buckets : Array[TimelineBucket] = []
  for entry in entries {
    let start = entry.tick / size * size
    let end = start + size - 1
    let index = find_timeline_bucket(buckets, start, end)
    if index < 0 {
      buckets.push(empty_timeline_bucket(start, end))
      add_entry_to_bucket(buckets[buckets.length() - 1], entry)
    } else {
      add_entry_to_bucket(buckets[index], entry)
    }
  }
  buckets.sort_by(fn(a, b) { a.start_tick.compare(b.start_tick) })
  { bucket_size: size, buckets }
}

///|
fn empty_timeline_bucket(start : Int, end : Int) -> TimelineBucket {
  {
    start_tick: start,
    end_tick: end,
    events: 0,
    executions: 0,
    metrics: 0,
    messages: 0,
  }
}

///|
fn find_timeline_bucket(
  buckets : Array[TimelineBucket],
  start : Int,
  end : Int,
) -> Int {
  for i in 0..<buckets.length() {
    if buckets[i].start_tick == start && buckets[i].end_tick == end {
      return i
    }
  }
  -1
}

///|
fn add_entry_to_bucket(bucket : TimelineBucket, entry : TraceEntry) -> Unit {
  bucket.events += 1
  if entry.kind == "execute" {
    bucket.executions += 1
  }
  if entry.kind.contains("metric.") {
    bucket.metrics += 1
  }
  if entry.kind.contains("message.") {
    bucket.messages += 1
  }
}

///|
pub fn TimelineView::bucket_count(self : TimelineView) -> Int {
  self.buckets.length()
}

///|
pub fn TimelineView::total_events(self : TimelineView) -> Int {
  let mut total = 0
  for bucket in self.buckets {
    total += bucket.events
  }
  total
}

///|
pub fn TimelineView::peak_bucket(self : TimelineView) -> TimelineBucket {
  if self.buckets.length() == 0 {
    empty_timeline_bucket(0, 0)
  } else {
    let mut best = self.buckets[0]
    for bucket in self.buckets {
      if bucket.events > best.events {
        best = bucket
      }
    }
    best
  }
}

///|
pub fn TimelineBucket::line(self : TimelineBucket) -> String {
  self.start_tick.to_string() +
  ".." +
  self.end_tick.to_string() +
  " events=" +
  self.events.to_string() +
  " executions=" +
  self.executions.to_string() +
  " metrics=" +
  self.metrics.to_string() +
  " messages=" +
  self.messages.to_string()
}

///|
pub fn TimelineView::render(self : TimelineView) -> String {
  let buf = StringBuilder::new()
  buf.write_string("# Timeline bucket=" + self.bucket_size.to_string() + "\n")
  for bucket in self.buckets {
    buf.write_string("- " + bucket.line() + "\n")
  }
  buf.to_string()
}

///|
pub fn Sim::timeline(self : Sim, bucket_size? : Int = 5) -> TimelineView {
  build_timeline(self.trace(), bucket_size~)
}
