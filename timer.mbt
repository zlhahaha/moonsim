///|
pub(all) struct Backoff {
  initial : Int
  factor : Int
  max_delay : Int
  jitter : Int
  mut current : Int
}

///|
pub fn Backoff::new(
  initial? : Int = 1,
  factor? : Int = 2,
  max_delay? : Int = 1024,
  jitter? : Int = 0,
) -> Backoff {
  let safe_initial = if initial < 1 { 1 } else { initial }
  {
    initial: safe_initial,
    factor: if factor < 1 {
      1
    } else {
      factor
    },
    max_delay: if max_delay < safe_initial {
      safe_initial
    } else {
      max_delay
    },
    jitter: if jitter < 0 {
      0
    } else {
      jitter
    },
    current: safe_initial,
  }
}

///|
pub fn Backoff::reset(self : Backoff) -> Unit {
  self.current = self.initial
}

///|
pub fn Backoff::next_delay(self : Backoff, rng : Rng) -> Int {
  let noise = if self.jitter == 0 { 0 } else { rng.next_int(self.jitter + 1) }
  let delay = self.current + noise
  let next = self.current * self.factor
  self.current = if next > self.max_delay { self.max_delay } else { next }
  if delay > self.max_delay {
    self.max_delay
  } else {
    delay
  }
}

///|
pub(all) struct TimerPlan {
  name : String
  start_after : Int
  interval : Int
  times : Int
  priority : Int
}

///|
pub fn timer_plan(
  name : String,
  start_after? : Int = 0,
  interval? : Int = 1,
  times? : Int = 1,
  priority? : Int = 0,
) -> TimerPlan {
  {
    name,
    start_after: if start_after < 0 {
      0
    } else {
      start_after
    },
    interval: if interval < 1 {
      1
    } else {
      interval
    },
    times: if times < 1 {
      1
    } else {
      times
    },
    priority,
  }
}

///|
pub fn Sim::install_timer(self : Sim, plan : TimerPlan) -> Int {
  self.schedule_repeating(
    plan.start_after,
    plan.interval,
    plan.times,
    plan.name,
    priority=plan.priority,
  )
}

///|
pub fn Sim::schedule_timeout(self : Sim, after : Int, name : String) -> Int {
  self.schedule_after(after, "timeout:" + name, priority=-100)
}

///|
pub fn Sim::schedule_backoff(
  self : Sim,
  backoff : Backoff,
  name : String,
) -> Int {
  let delay = backoff.next_delay(self.rng)
  self.record(0, "timer.backoff", name + "=" + delay.to_string())
  self.schedule_after(delay, name)
}
