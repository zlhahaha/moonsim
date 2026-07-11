///|
pub(all) struct Transition {
  from : String
  event : String
  to : String
  action : String
}

///|
pub(all) struct TransitionResult {
  accepted : Bool
  from : String
  event : String
  to : String
  action : String
  reason : String
}

///|
pub(all) struct StateMachine {
  name : String
  mut state : String
  mut transitions : Array[Transition]
  mut history : Array[TransitionResult]
}

///|
pub fn transition(
  from : String,
  event : String,
  to : String,
  action? : String = "",
) -> Transition {
  { from, event, to, action }
}

///|
pub fn StateMachine::new(name : String, initial : String) -> StateMachine {
  { name, state: initial, transitions: [], history: [] }
}

///|
pub fn StateMachine::add(
  self : StateMachine,
  transition : Transition,
) -> StateMachine {
  self.transitions.push(transition)
  self
}

///|
pub fn StateMachine::state(self : StateMachine) -> String {
  self.state
}

///|
pub fn StateMachine::send(
  self : StateMachine,
  event : String,
) -> TransitionResult {
  for transition in self.transitions {
    if transition.from == self.state && transition.event == event {
      let from = self.state
      self.state = transition.to
      let result = {
        accepted: true,
        from,
        event,
        to: transition.to,
        action: transition.action,
        reason: "accepted",
      }
      self.history.push(result)
      return result
    }
  }
  let rejected = {
    accepted: false,
    from: self.state,
    event,
    to: self.state,
    action: "",
    reason: "no transition",
  }
  self.history.push(rejected)
  rejected
}

///|
pub fn StateMachine::history(self : StateMachine) -> Array[TransitionResult] {
  self.history.copy()
}

///|
pub fn Sim::record_transition(
  self : Sim,
  machine : StateMachine,
  result : TransitionResult,
) -> Unit {
  let status = if result.accepted { "accepted" } else { "rejected" }
  self.record(
    0,
    "state.transition",
    machine.name +
    ":" +
    result.from +
    "-" +
    result.event +
    "->" +
    result.to +
    ":" +
    status,
  )
  if result.accepted {
    self.inc_counter("state.accepted")
  } else {
    self.inc_counter("state.rejected")
  }
}

///|
/// Projects accepted and rejected transitions into a causally linked event stream.
pub fn StateMachine::event_stream(self : StateMachine) -> EventStream {
  let stream = EventStream::new()
  let mut parent_id = 0
  let mut tick = 0
  for result in self.history {
    let event = stream.record(
      StateTransition,
      tick,
      result.event,
      correlation_id=self.name,
      source=result.from,
      target=result.to,
      parent_id~,
      payload=result.action,
      failed=!result.accepted,
    )
    parent_id = event.id
    tick += 1
  }
  stream
}
