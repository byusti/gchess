import gleam/bitwise

pub type Bitboard {
  Bitboard(bitboard: Int)
}

pub fn new_bitboard(bitboard: Int) -> Bitboard {
  Bitboard(bitboard)
}

pub fn empty_bitboard() -> Bitboard {
  Bitboard(0)
}

pub fn full_bitboard() -> Bitboard {
  Bitboard(0xffffffffffffffff)
}

pub fn and(bitboard1: Bitboard, bitboard2: Bitboard) -> Bitboard {
  Bitboard(bitwise.and(bitboard1.bitboard, bitboard2.bitboard))
}

pub fn exclusive_or(bitboard1: Bitboard, bitboard2: Bitboard) -> Bitboard {
  Bitboard(bitwise.exclusive_or(bitboard1.bitboard, bitboard2.bitboard))
}

pub fn or(bitboard1: Bitboard, bitboard2: Bitboard) -> Bitboard {
  Bitboard(bitwise.or(bitboard1.bitboard, bitboard2.bitboard))
}

pub fn not(bitboard: Bitboard) -> Bitboard {
  Bitboard(bitwise.not(bitboard.bitboard))
}

pub fn shift_left(bitboard: Bitboard, shift: Int) -> Bitboard {
  Bitboard(bitwise.shift_left(bitboard.bitboard, shift))
}

pub fn shift_right(bitboard: Bitboard, shift: Int) -> Bitboard {
  Bitboard(bitwise.shift_right(bitboard.bitboard, shift))
}
