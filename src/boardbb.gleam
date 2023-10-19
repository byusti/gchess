import bitboard.{type Bitboard, and, new_bitboard, shift_left}
import position.{type Position}
import move.{type Move, SimpleMove}
import gleam/option.{Some}

pub type BoardBB {
  BoardBB(
    black_king_bitboard: bitboard.Bitboard,
    black_queen_bitboard: bitboard.Bitboard,
    black_rook_bitboard: bitboard.Bitboard,
    black_bishop_bitboard: bitboard.Bitboard,
    black_knight_bitboard: bitboard.Bitboard,
    black_pawns_bitboard: bitboard.Bitboard,
    white_king_bitboard: bitboard.Bitboard,
    white_queen_bitboard: bitboard.Bitboard,
    white_rook_bitboard: bitboard.Bitboard,
    white_bishop_bitboard: bitboard.Bitboard,
    white_knight_bitboard: bitboard.Bitboard,
    white_pawns_bitboard: bitboard.Bitboard,
  )
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
        _ -> {
          let assert Some(position_dest) = position.from_int(count)
          [
            SimpleMove(position, position_dest),
            ..get_moves_inner(shift_left(bitboard, 1), count - 1, position)
          ]
        }
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
        _ -> {
          let assert Some(position_dest) = position.from_int(count)
          [
            SimpleMove(position, position_dest),
            ..get_moves_inner(shift_left(bitboard, 1), count - 1, position)
          ]
        }
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
        _ -> {
          let assert Some(position_dest) = position.from_int(count)
          [
            position_dest,
            ..get_positions_inner(shift_left(bitboard, 1), count - 1)
          ]
        }
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
        _ -> {
          let assert Some(position_dest) = position.from_int(count)
          [
            position_dest,
            ..get_positions_inner(shift_left(bitboard, 1), count - 1)
          ]
        }
      }
    }
  }
}

pub fn from_position(position: Position) -> Bitboard {
  let bitboard = shift_left(new_bitboard(1), position.to_int(position))
  bitboard
}
