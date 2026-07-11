///|
pub(all) struct Message {
  id : Int
  from : String
  to : String
  body : String
  send_tick : Int
  deliver_tick : Int
  dropped : Bool
}

///|
pub(all) struct MessageBus {
  mut next_message_id : Int
  mut messages : Array[Message]
}

///|
pub fn MessageBus::new() -> MessageBus {
  { next_message_id: 1, messages: [] }
}

///|
pub fn MessageBus::send(
  self : MessageBus,
  sim : Sim,
  from : String,
  to : String,
  body : String,
  delay? : Int = 1,
) -> Int {
  let id = self.next_message_id
  self.next_message_id += 1
  let deliver_tick = sim.time() + (if delay < 0 { 0 } else { delay })
  let msg = {
    id,
    from,
    to,
    body,
    send_tick: sim.time(),
    deliver_tick,
    dropped: false,
  }
  self.messages.push(msg)
  ignore(
    sim.schedule_at(deliver_tick, "message:" + id.to_string() + ":deliver"),
  )
  sim.record(0, "message.send", from + "->" + to + "#" + id.to_string())
  id
}

///|
pub fn MessageBus::drop(self : MessageBus, sim : Sim, id : Int) -> Bool {
  let mut i = 0
  while i < self.messages.length() {
    if self.messages[i].id == id && !self.messages[i].dropped {
      self.messages[i] = {
        id: self.messages[i].id,
        from: self.messages[i].from,
        to: self.messages[i].to,
        body: self.messages[i].body,
        send_tick: self.messages[i].send_tick,
        deliver_tick: self.messages[i].deliver_tick,
        dropped: true,
      }
      sim.record(0, "message.drop", id.to_string())
      sim.inc_counter("messages_dropped")
      return true
    }
    i += 1
  }
  false
}

///|
pub fn MessageBus::deliver_due(self : MessageBus, sim : Sim) -> Int {
  let mut delivered = 0
  for msg in self.messages {
    if !msg.dropped && msg.deliver_tick <= sim.time() {
      delivered += 1
      sim.record(
        0,
        "message.deliver",
        msg.from + "->" + msg.to + "#" + msg.id.to_string(),
      )
    }
  }
  sim.inc_counter("messages_delivered", delta=delivered)
  delivered
}

///|
pub fn MessageBus::messages(self : MessageBus) -> Array[Message] {
  self.messages.copy()
}

///|
pub fn MessageBus::pending(self : MessageBus, sim : Sim) -> Int {
  let mut count = 0
  for msg in self.messages {
    if !msg.dropped && msg.deliver_tick > sim.time() {
      count += 1
    }
  }
  count
}

///|
/// Projects message send and delivery facts into the generic event stream.
pub fn MessageBus::event_stream(self : MessageBus) -> EventStream {
  let stream = EventStream::new()
  for message in self.messages {
    let correlation_id = "message:" + message.id.to_string()
    let sent = stream.record(
      Message,
      message.send_tick,
      "message.send",
      correlation_id~,
      source=message.from,
      target=message.to,
      payload=message.body,
    )
    ignore(
      stream.record(
        Message,
        message.deliver_tick,
        if message.dropped {
          "message.drop"
        } else {
          "message.deliver"
        },
        correlation_id~,
        source=message.from,
        target=message.to,
        parent_id=sent.id,
        payload=message.body,
        dropped=message.dropped,
      ),
    )
  }
  stream
}
