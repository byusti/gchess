import gleam/bitwise
import position.{Position}
import move.{Move}

pub type Bitboard {
  Bitboard(bitboard: Int)
}

pub fn get_moves(bitboard: Bitboard, position: Position) -> List(Move) {
  let moves = []
  case bitboard.bitboard {
    0 -> moves
    _ -> {
      let count = 63
      let just_first_bit_of_bb = and(bitboard, new_bitboard(0x8000000000000000))
      case just_first_bit_of_bb.bitboard {
        0 -> get_moves_inner(shift_left(bitboard, 1), count - 1, position)
        _ -> [
          Move(position, position.int_to_position(count)),
          ..get_moves_inner(shift_left(bitboard, 1), count - 1, position)
        ]
      }
    }
  }
}

pub fn get_moves_inner(
  bitboard: Bitboard,
  count: Int,
  position: Position,
) -> List(Move) {
  case count < 0 {
    True -> []
    False -> {
      let just_first_bit_of_bb = and(bitboard, new_bitboard(0x8000000000000000))
      case just_first_bit_of_bb.bitboard {
        0 -> get_moves_inner(shift_left(bitboard, 1), count - 1, position)
        _ -> [
          Move(position, position.int_to_position(count)),
          ..get_moves_inner(shift_left(bitboard, 1), count - 1, position)
        ]
      }
    }
  }
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
          position.int_to_position(count),
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
          position.int_to_position(count),
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

pub fn from_position(position: Position) -> Bitboard {
  let bitboard = shift_left(new_bitboard(1), position.to_int(position))
  bitboard
}
