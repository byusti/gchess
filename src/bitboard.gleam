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

pub fn bitscan_forward(bitboard: Bitboard) -> Int {
  bitscan_forward_inner(bitboard, 0)
}

pub fn bitscan_forward_inner(bitboard: Bitboard, index: Int) -> Int {
  case bitboard.bitboard == 0 || index > 63 {
    True -> -1
    False -> {
      let lsb_digit =
        0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000001
      let first_digit_bitboard = and(bitboard, new_bitboard(lsb_digit))
      case first_digit_bitboard.bitboard {
        0 -> bitscan_forward_inner(shift_right(bitboard, 1), index + 1)
        _ -> index
      }
    }
  }
}

pub fn bitscan_backward(bitboard: Bitboard) -> Int {
  bitscan_backward_inner(bitboard, 63)
}

pub fn bitscan_backward_inner(bitboard: Bitboard, index: Int) -> Int {
  case bitboard.bitboard == 0 || index < 0 {
    True -> -1
    False -> {
      let msb_digit =
        0b10000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000
      let first_digit_bitboard = and(bitboard, new_bitboard(msb_digit))
      case first_digit_bitboard.bitboard {
        0 -> bitscan_backward_inner(shift_left(bitboard, 1), index - 1)
        _ -> index
      }
    }
  }
}
