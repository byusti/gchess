import bitboard.{type Bitboard, and, new_bitboard, shift_left}
import color.{Black, White}
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set
import piece.{type Piece, Bishop, King, Knight, Pawn, Queen, Rook}
import position.{type Position}

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

pub fn remove_piece_at_position(
  board: BoardBB,
  position: Position,
) -> Result(BoardBB, _) {
  let bitboard = bitboard.not(from_position(position))

  let new_board = case get_piece_at_position(board, position) {
    None -> Error("No piece at position")
    Some(piece.Piece(color: color, kind: kind)) if color == White
      && kind == King -> {
      Ok(
        BoardBB(
          ..board,
          white_king_bitboard: bitboard.and(bitboard, board.white_king_bitboard),
        ),
      )
    }
    Some(piece.Piece(color: color, kind: kind)) if color == White
      && kind == Queen -> {
      Ok(
        BoardBB(
          ..board,
          white_queen_bitboard: bitboard.and(
            bitboard,
            board.white_queen_bitboard,
          ),
        ),
      )
    }
    Some(piece.Piece(color: color, kind: kind)) if color == White
      && kind == Rook -> {
      Ok(
        BoardBB(
          ..board,
          white_rook_bitboard: bitboard.and(bitboard, board.white_rook_bitboard),
        ),
      )
    }

    Some(piece.Piece(color: color, kind: kind)) if color == White
      && kind == Bishop -> {
      Ok(
        BoardBB(
          ..board,
          white_bishop_bitboard: bitboard.and(
            bitboard,
            board.white_bishop_bitboard,
          ),
        ),
      )
    }
    Some(piece.Piece(color: color, kind: kind)) if color == White
      && kind == Knight -> {
      Ok(
        BoardBB(
          ..board,
          white_knight_bitboard: bitboard.and(
            bitboard,
            board.white_knight_bitboard,
          ),
        ),
      )
    }
    Some(piece.Piece(color: color, kind: kind)) if color == White
      && kind == Pawn -> {
      Ok(
        BoardBB(
          ..board,
          white_pawns_bitboard: bitboard.and(
            bitboard,
            board.white_pawns_bitboard,
          ),
        ),
      )
    }
    Some(piece.Piece(color: color, kind: kind)) if color == Black
      && kind == King -> {
      Ok(
        BoardBB(
          ..board,
          black_king_bitboard: bitboard.and(bitboard, board.black_king_bitboard),
        ),
      )
    }
    Some(piece.Piece(color: color, kind: kind)) if color == Black
      && kind == Queen -> {
      Ok(
        BoardBB(
          ..board,
          black_queen_bitboard: bitboard.and(
            bitboard,
            board.black_queen_bitboard,
          ),
        ),
      )
    }
    Some(piece.Piece(color: color, kind: kind)) if color == Black
      && kind == Rook -> {
      Ok(
        BoardBB(
          ..board,
          black_rook_bitboard: bitboard.and(bitboard, board.black_rook_bitboard),
        ),
      )
    }
    Some(piece.Piece(color: color, kind: kind)) if color == Black
      && kind == Bishop -> {
      Ok(
        BoardBB(
          ..board,
          black_bishop_bitboard: bitboard.and(
            bitboard,
            board.black_bishop_bitboard,
          ),
        ),
      )
    }
    Some(piece.Piece(color: color, kind: kind)) if color == Black
      && kind == Knight -> {
      Ok(
        BoardBB(
          ..board,
          black_knight_bitboard: bitboard.and(
            bitboard,
            board.black_knight_bitboard,
          ),
        ),
      )
    }
    Some(piece.Piece(color: color, kind: kind)) if color == Black
      && kind == Pawn -> {
      Ok(
        BoardBB(
          ..board,
          black_pawns_bitboard: bitboard.and(
            bitboard,
            board.black_pawns_bitboard,
          ),
        ),
      )
    }
    _ -> {
      panic("Invalid piece")
    }
  }
  new_board
}

pub fn set_piece_at_position(
  board: BoardBB,
  position: Position,
  piece: Piece,
) -> BoardBB {
  let bitboard = from_position(position)

  let new_board = case piece {
    piece.Piece(color: color, kind: kind) if color == White && kind == King -> {
      BoardBB(
        ..board,
        white_king_bitboard: bitboard.or(bitboard, board.white_king_bitboard),
      )
    }
    piece.Piece(color: color, kind: kind) if color == White && kind == Queen -> {
      BoardBB(
        ..board,
        white_queen_bitboard: bitboard.or(bitboard, board.white_queen_bitboard),
      )
    }
    piece.Piece(color: color, kind: kind) if color == White && kind == Rook -> {
      BoardBB(
        ..board,
        white_rook_bitboard: bitboard.or(bitboard, board.white_rook_bitboard),
      )
    }
    piece.Piece(color: color, kind: kind) if color == White && kind == Bishop -> {
      BoardBB(
        ..board,
        white_bishop_bitboard: bitboard.or(
          bitboard,
          board.white_bishop_bitboard,
        ),
      )
    }
    piece.Piece(color: color, kind: kind) if color == White && kind == Knight -> {
      BoardBB(
        ..board,
        white_knight_bitboard: bitboard.or(
          bitboard,
          board.white_knight_bitboard,
        ),
      )
    }
    piece.Piece(color: color, kind: kind) if color == White && kind == Pawn -> {
      BoardBB(
        ..board,
        white_pawns_bitboard: bitboard.or(bitboard, board.white_pawns_bitboard),
      )
    }
    piece.Piece(color: color, kind: kind) if color == Black && kind == King -> {
      BoardBB(
        ..board,
        black_king_bitboard: bitboard.or(bitboard, board.black_king_bitboard),
      )
    }
    piece.Piece(color: color, kind: kind) if color == Black && kind == Queen -> {
      BoardBB(
        ..board,
        black_queen_bitboard: bitboard.or(bitboard, board.black_queen_bitboard),
      )
    }
    piece.Piece(color: color, kind: kind) if color == Black && kind == Rook -> {
      BoardBB(
        ..board,
        black_rook_bitboard: bitboard.or(bitboard, board.black_rook_bitboard),
      )
    }
    piece.Piece(color: color, kind: kind) if color == Black && kind == Bishop -> {
      BoardBB(
        ..board,
        black_bishop_bitboard: bitboard.or(
          bitboard,
          board.black_bishop_bitboard,
        ),
      )
    }
    piece.Piece(color: color, kind: kind) if color == Black && kind == Knight -> {
      BoardBB(
        ..board,
        black_knight_bitboard: bitboard.or(
          bitboard,
          board.black_knight_bitboard,
        ),
      )
    }
    piece.Piece(color: color, kind: kind) if color == Black && kind == Pawn -> {
      BoardBB(
        ..board,
        black_pawns_bitboard: bitboard.or(bitboard, board.black_pawns_bitboard),
      )
    }
    _ -> {
      panic("Invalid piece")
    }
  }
  new_board
}

pub fn get_piece_at_position(board: BoardBB, position: Position) {
  let bitboard = from_position(position)
  let black_king_bb_compare = bitboard.and(board.black_king_bitboard, bitboard)
  let black_queen_bb_compare =
    bitboard.and(board.black_queen_bitboard, bitboard)
  let black_rook_bb_compare = bitboard.and(board.black_rook_bitboard, bitboard)
  let black_bishop_bb_compare =
    bitboard.and(board.black_bishop_bitboard, bitboard)
  let black_knight_bb_compare =
    bitboard.and(board.black_knight_bitboard, bitboard)
  let black_pawns_bb_compare =
    bitboard.and(board.black_pawns_bitboard, bitboard)
  let white_king_bb_compare = bitboard.and(board.white_king_bitboard, bitboard)
  let white_queen_bb_compare =
    bitboard.and(board.white_queen_bitboard, bitboard)
  let white_rook_bb_compare = bitboard.and(board.white_rook_bitboard, bitboard)
  let white_bishop_bb_compare =
    bitboard.and(board.white_bishop_bitboard, bitboard)
  let white_knight_bb_compare =
    bitboard.and(board.white_knight_bitboard, bitboard)
  let white_pawns_bb_compare =
    bitboard.and(board.white_pawns_bitboard, bitboard)

  let piece = case bitboard {
    0 -> None
    _ -> {
      let piece = case bitboard {
        _ if bitboard == black_king_bb_compare ->
          Some(piece.Piece(color.Black, King))
        _ if bitboard == black_queen_bb_compare ->
          Some(piece.Piece(color.Black, Queen))
        _ if bitboard == black_rook_bb_compare ->
          Some(piece.Piece(color.Black, Rook))
        _ if bitboard == black_bishop_bb_compare ->
          Some(piece.Piece(color.Black, Bishop))
        _ if bitboard == black_knight_bb_compare ->
          Some(piece.Piece(color.Black, Knight))
        _ if bitboard == black_pawns_bb_compare ->
          Some(piece.Piece(color.Black, Pawn))
        _ if bitboard == white_king_bb_compare ->
          Some(piece.Piece(color.White, King))
        _ if bitboard == white_queen_bb_compare ->
          Some(piece.Piece(color.White, Queen))
        _ if bitboard == white_rook_bb_compare ->
          Some(piece.Piece(color.White, Rook))
        _ if bitboard == white_bishop_bb_compare ->
          Some(piece.Piece(color.White, Bishop))
        _ if bitboard == white_knight_bb_compare ->
          Some(piece.Piece(color.White, Knight))
        _ if bitboard == white_pawns_bb_compare ->
          Some(piece.Piece(color.White, Pawn))
        _ -> None
      }
      piece
    }
  }
  piece
}

pub fn get_all_positions(board: BoardBB) -> Result(List(Position), _) {
  let list_of_bitboards = [
    board.black_king_bitboard,
    board.black_queen_bitboard,
    board.black_rook_bitboard,
    board.black_bishop_bitboard,
    board.black_knight_bitboard,
    board.black_pawns_bitboard,
    board.white_king_bitboard,
    board.white_queen_bitboard,
    board.white_rook_bitboard,
    board.white_bishop_bitboard,
    board.white_knight_bitboard,
    board.white_pawns_bitboard,
  ]

  let positions =
    list.fold(list_of_bitboards, set.new(), fn(acc, bitboard) {
      let positions = case get_positions(bitboard) {
        Ok(positions) -> positions
        Error(_) -> []
      }
      let positions = set.from_list(positions)
      set.union(acc, positions)
    })

  Ok(set.to_list(positions))
}

pub fn get_positions(bitboard: Bitboard) -> Result(List(Position), _) {
  let positions = []
  case bitboard {
    0 -> Ok(positions)
    _ -> {
      let count = 63
      let just_first_bit_of_bb = and(bitboard, new_bitboard(0x8000000000000000))
      case just_first_bit_of_bb {
        0 -> get_positions_inner(shift_left(bitboard, 1), count - 1)
        _ -> {
          use position_dest <- result.try(position.from_int(count))
          use positions_inner <- result.try(get_positions_inner(
            shift_left(bitboard, 1),
            count - 1,
          ))
          Ok([position_dest, ..positions_inner])
        }
      }
    }
  }
}

pub fn get_positions_inner(
  bitboard: Bitboard,
  count: Int,
) -> Result(List(Position), _) {
  case count < 0 {
    True -> Ok([])
    False -> {
      let just_first_bit_of_bb = and(bitboard, new_bitboard(0x8000000000000000))
      case just_first_bit_of_bb {
        0 -> get_positions_inner(shift_left(bitboard, 1), count - 1)
        _ -> {
          use position_dest <- result.try(position.from_int(count))
          use positions_inner <- result.try(get_positions_inner(
            shift_left(bitboard, 1),
            count - 1,
          ))
          Ok([position_dest, ..positions_inner])
        }
      }
    }
  }
}

pub fn from_position(position: Position) -> Bitboard {
  let bitboard = shift_left(new_bitboard(1), position.to_int(position))
  bitboard
}
