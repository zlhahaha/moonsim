///|
/// Deterministic pseudo-random generator for reproducible simulations.
///
/// This generator is not cryptographic. It is intentionally small and portable
/// so simulations behave the same across MoonBit targets.
pub(all) struct Rng {
  mut state : UInt64
}

///|
pub fn Rng::new(seed : UInt64) -> Rng {
  let normalized = if seed == 0UL { 0x9E3779B97F4A7C15UL } else { seed }
  { state: normalized }
}

///|
pub fn Rng::state(self : Rng) -> UInt64 {
  self.state
}

///|
pub fn Rng::next_u64(self : Rng) -> UInt64 {
  let mut x = self.state
  x = x ^ (x >> 12)
  x = x ^ (x << 25)
  x = x ^ (x >> 27)
  self.state = x
  x * 2685821657736338717UL
}

///|
pub fn Rng::next_int(self : Rng, bound : Int) -> Int {
  if bound <= 0 {
    0
  } else {
    (self.next_u64() % bound.to_uint64()).to_int()
  }
}

///|
pub fn Rng::next_bool(self : Rng) -> Bool {
  (self.next_u64() & 1UL) == 1UL
}

///|
pub fn Rng::next_range(self : Rng, low : Int, high : Int) -> Int {
  if high <= low {
    low
  } else {
    low + self.next_int(high - low)
  }
}

///|
pub fn[T] Rng::choose(self : Rng, items : Array[T]) -> T? {
  if items.length() == 0 {
    None
  } else {
    Some(items[self.next_int(items.length())])
  }
}

///|
pub fn[T] Rng::shuffle(self : Rng, items : Array[T]) -> Array[T] {
  let shuffled = items.copy()
  let mut i = shuffled.length() - 1
  while i > 0 {
    let j = self.next_int(i + 1)
    let tmp = shuffled[i]
    shuffled[i] = shuffled[j]
    shuffled[j] = tmp
    i -= 1
  }
  shuffled
}

///|
pub(all) struct WeightedChoice {
  label : String
  weight : Int
}

///|
pub fn weighted_choice(label : String, weight : Int) -> WeightedChoice {
  { label, weight: if weight < 0 { 0 } else { weight } }
}

///|
pub fn Rng::choose_weighted(
  self : Rng,
  choices : Array[WeightedChoice],
) -> String? {
  let mut total = 0
  for choice in choices {
    total += choice.weight
  }
  if total <= 0 {
    None
  } else {
    let ticket = self.next_int(total)
    let mut cursor = 0
    for choice in choices {
      cursor += choice.weight
      if ticket < cursor {
        return Some(choice.label)
      }
    }
    None
  }
}
