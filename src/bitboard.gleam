import gleam/bitwise
import gleam/io
import gleam/int
import position.{Position}

pub type Bitboard {
  Bitboard(bitboard: Int)
}

pub fn get_positions(bitboard: Bitboard) -> List(Position) {
  let positions = []
  case bitboard.bitboard {
    0 -> positions
    _ -> {
      let count = 63
      let just_first_bit_of_bb = and(bitboard, new_bitboard(0x8000000000000000))
      case just_first_bit_of_bb.bitboard {
        0 -> get_positions_inner(shift_left(bitboard, 1), count - 1)
        _ -> [
          position.int_to_position(63 - count),
          ..get_positions_inner(shift_left(bitboard, 1), count - 1)
        ]
      }
    }
  }
}

pub fn get_positions_inner(bitboard: Bitboard, count: Int) -> List(Position) {
  case count < 0 {
    True -> []
    False -> {
      let just_first_bit_of_bb = and(bitboard, new_bitboard(0x8000000000000000))
      case just_first_bit_of_bb.bitboard {
        0 -> get_positions_inner(shift_left(bitboard, 1), count - 1)
        _ -> [
          position.int_to_position(63 - count),
          ..get_positions_inner(shift_left(bitboard, 1), count - 1)
        ]
      }
    }
  }
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
