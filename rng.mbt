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
