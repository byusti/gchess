import bitboard
import board.{type BoardBB}
import color.{type Color, Black, White}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import piece
import position.{type File, type Position, type Rank}

pub type CastlingStatus {
  CastlingStatus(
    white_kingside: Bool,
    white_queenside: Bool,
    black_kingside: Bool,
    black_queenside: Bool,
  )
}

pub type HalfMove =
  Int

pub type FullMove =
  Int

pub type Fen {
  Fen(
    board: BoardBB,
    turn: Color,
    castling: CastlingStatus,
    en_passant: Option(Position),
    halfmove: HalfMove,
    fullmove: FullMove,
  )
}

const positions_in_fen_order = [
  position.Position(file: position.A, rank: position.Eight),
  position.Position(file: position.B, rank: position.Eight),
  position.Position(file: position.C, rank: position.Eight),
  position.Position(file: position.D, rank: position.Eight),
  position.Position(file: position.E, rank: position.Eight),
  position.Position(file: position.F, rank: position.Eight),
  position.Position(file: position.G, rank: position.Eight),
  position.Position(file: position.H, rank: position.Eight),
  position.Position(file: position.A, rank: position.Seven),
  position.Position(file: position.B, rank: position.Seven),
  position.Position(file: position.C, rank: position.Seven),
  position.Position(file: position.D, rank: position.Seven),
  position.Position(file: position.E, rank: position.Seven),
  position.Position(file: position.F, rank: position.Seven),
  position.Position(file: position.G, rank: position.Seven),
  position.Position(file: position.H, rank: position.Seven),
  position.Position(file: position.A, rank: position.Six),
  position.Position(file: position.B, rank: position.Six),
  position.Position(file: position.C, rank: position.Six),
  position.Position(file: position.D, rank: position.Six),
  position.Position(file: position.E, rank: position.Six),
  position.Position(file: position.F, rank: position.Six),
  position.Position(file: position.G, rank: position.Six),
  position.Position(file: position.H, rank: position.Six),
  position.Position(file: position.A, rank: position.Five),
  position.Position(file: position.B, rank: position.Five),
  position.Position(file: position.C, rank: position.Five),
  position.Position(file: position.D, rank: position.Five),
  position.Position(file: position.E, rank: position.Five),
  position.Position(file: position.F, rank: position.Five),
  position.Position(file: position.G, rank: position.Five),
  position.Position(file: position.H, rank: position.Five),
  position.Position(file: position.A, rank: position.Four),
  position.Position(file: position.B, rank: position.Four),
  position.Position(file: position.C, rank: position.Four),
  position.Position(file: position.D, rank: position.Four),
  position.Position(file: position.E, rank: position.Four),
  position.Position(file: position.F, rank: position.Four),
  position.Position(file: position.G, rank: position.Four),
  position.Position(file: position.H, rank: position.Four),
  position.Position(file: position.A, rank: position.Three),
  position.Position(file: position.B, rank: position.Three),
  position.Position(file: position.C, rank: position.Three),
  position.Position(file: position.D, rank: position.Three),
  position.Position(file: position.E, rank: position.Three),
  position.Position(file: position.F, rank: position.Three),
  position.Position(file: position.G, rank: position.Three),
  position.Position(file: position.H, rank: position.Three),
  position.Position(file: position.A, rank: position.Two),
  position.Position(file: position.B, rank: position.Two),
  position.Position(file: position.C, rank: position.Two),
  position.Position(file: position.D, rank: position.Two),
  position.Position(file: position.E, rank: position.Two),
  position.Position(file: position.F, rank: position.Two),
  position.Position(file: position.G, rank: position.Two),
  position.Position(file: position.H, rank: position.Two),
  position.Position(file: position.A, rank: position.One),
  position.Position(file: position.B, rank: position.One),
  position.Position(file: position.C, rank: position.One),
  position.Position(file: position.D, rank: position.One),
  position.Position(file: position.E, rank: position.One),
  position.Position(file: position.F, rank: position.One),
  position.Position(file: position.G, rank: position.One),
  position.Position(file: position.H, rank: position.One),
]

pub fn to_board(fen: String) -> BoardBB {
  let fen_string_parts = string.split(fen, " ")
  let parsed_board = case list.length(fen_string_parts) == 6 {
    False -> panic as "Invalid FEN string"
    True -> {
      let assert [board_string, ..] = fen_string_parts
      let parsed_board = parse_board(board_string)
      parsed_board
    }
  }
  parsed_board
}

fn board_to_fen_string(board: BoardBB) -> String {
  let board_string =
    list.fold(positions_in_fen_order, "", fn(acc, pos) {
      let piece = board.get_piece_at_position(board, pos)
      let acc = case piece {
        None -> {
          let last_char = string.last(acc)
          case last_char {
            Error(Nil) | Ok("/") -> string.append(acc, "1")
            Ok("1") -> {
              string.append(string.drop_right(acc, 1), "2")
            }
            Ok("2") -> {
              string.append(string.drop_right(acc, 1), "3")
            }
            Ok("3") -> {
              string.append(string.drop_right(acc, 1), "4")
            }
            Ok("4") -> {
              string.append(string.drop_right(acc, 1), "5")
            }
            Ok("5") -> {
              string.append(string.drop_right(acc, 1), "6")
            }
            Ok("6") -> {
              string.append(string.drop_right(acc, 1), "7")
            }
            Ok("7") -> {
              string.append(string.drop_right(acc, 1), "8")
            }
            Ok("8") -> panic as "Unable to encode BoardBB to FEN string"
            Ok(_) -> {
              string.append(acc, "1")
            }
          }
        }
        Some(piece) -> {
          let piece_string = piece_to_fen_string(piece)
          string.append(acc, piece_string)
        }
      }
      let acc = case pos {
        position.Position(file: position.H, rank: position.One) -> acc
        position.Position(file: position.H, rank: _) -> {
          string.append(acc, "/")
        }
        _ -> acc
      }
      acc
    })

  board_string
}

fn piece_to_fen_string(piece: piece.Piece) -> String {
  case piece {
    piece.Piece(color: White, kind: piece.King) -> "K"
    piece.Piece(color: White, kind: piece.Queen) -> "Q"
    piece.Piece(color: White, kind: piece.Rook) -> "R"
    piece.Piece(color: White, kind: piece.Bishop) -> "B"
    piece.Piece(color: White, kind: piece.Knight) -> "N"
    piece.Piece(color: White, kind: piece.Pawn) -> "P"
    piece.Piece(color: Black, kind: piece.King) -> "k"
    piece.Piece(color: Black, kind: piece.Queen) -> "q"
    piece.Piece(color: Black, kind: piece.Rook) -> "r"
    piece.Piece(color: Black, kind: piece.Bishop) -> "b"
    piece.Piece(color: Black, kind: piece.Knight) -> "n"
    piece.Piece(color: Black, kind: piece.Pawn) -> "p"
  }
}

fn turn_to_fen_string(turn: Color) -> String {
  case turn {
    White -> "w"
    Black -> "b"
  }
}

fn castling_to_fen_string(castling: CastlingStatus) -> String {
  let white_kingside_castling = case castling.white_kingside {
    True -> "K"
    False -> ""
  }
  let white_queenside_castling = case castling.white_queenside {
    True -> "Q"
    False -> ""
  }
  let black_kingside_castling = case castling.black_kingside {
    True -> "k"
    False -> ""
  }
  let black_queenside_castling = case castling.black_queenside {
    True -> "q"
    False -> ""
  }
  let castling_string =
    string.join(
      [
        white_kingside_castling,
        white_queenside_castling,
        black_kingside_castling,
        black_queenside_castling,
      ],
      "",
    )
  case castling_string {
    "" -> "-"
    _ -> castling_string
  }
}

fn en_passant_to_fen_string(en_passant: Option(Position)) -> String {
  case en_passant {
    None -> "-"
    Some(pos) -> {
      let file_string = position.file_to_string(pos.file)
      let rank_string = position.rank_to_string(pos.rank)
      string.join([file_string, rank_string], "")
    }
  }
}

pub fn to_string(fen: Fen) -> String {
  let board_string = board_to_fen_string(fen.board)
  let turn_string = turn_to_fen_string(fen.turn)
  let castling_string = castling_to_fen_string(fen.castling)
  let en_passant_string = en_passant_to_fen_string(fen.en_passant)
  let halfmove_string = int.to_string(fen.halfmove)
  let fullmove_string = int.to_string(fen.fullmove)

  let fen_string =
    string.join(
      [
        board_string,
        turn_string,
        castling_string,
        en_passant_string,
        halfmove_string,
        fullmove_string,
      ],
      " ",
    )

  fen_string
}

pub fn from_string(fen: String) -> Fen {
  let fen = string.trim(fen)
  let fen_string_parts = string.split(fen, " ")
  case list.length(fen_string_parts) == 6 {
    False -> panic as "Invalid FEN string"
    True -> {
      let assert [board_string, ..rest] = fen_string_parts
      let assert [turn_string, ..rest] = rest
      let assert [castling_string, ..rest] = rest
      let assert [en_passant_string, ..rest] = rest
      let assert [halfmove_string, ..rest] = rest
      let assert [fullmove_string, ..] = rest

      let parsed_board = parse_board(board_string)
      let parsed_turn = parse_turn(turn_string)
      let parsed_castling = parse_castling(castling_string)
      let parsed_en_passant = parse_en_passant(en_passant_string)
      let parsed_halfmove = parse_halfmove(halfmove_string)
      let parsed_fullmove = parse_fullmove(fullmove_string)

      let fen =
        Fen(
          board: parsed_board,
          turn: parsed_turn,
          castling: parsed_castling,
          en_passant: parsed_en_passant,
          halfmove: parsed_halfmove,
          fullmove: parsed_fullmove,
        )

      fen
    }
  }
}

// This function parses the board part of the FEN string
pub fn parse_board(board_string: String) -> BoardBB {
  // in the context of this function, rank means a an entire row of the board 
  // represented as a string of piece chars and numbers for empy spaces
  // example: "rnbqk1nr"

  let list_of_ranks_as_strings = string.split(board_string, "/")

  let accumulator =
    board.BoardBB(
      black_king_bitboard: 0,
      black_queen_bitboard: 0,
      black_rook_bitboard: 0,
      black_bishop_bitboard: 0,
      black_knight_bitboard: 0,
      black_pawns_bitboard: 0,
      white_king_bitboard: 0,
      white_queen_bitboard: 0,
      white_rook_bitboard: 0,
      white_bishop_bitboard: 0,
      white_knight_bitboard: 0,
      white_pawns_bitboard: 0,
    )

  list.index_fold(
    list_of_ranks_as_strings,
    accumulator,
    fn(acc, rank_as_string, rank_index) {
      let rank_index = position.int_to_rank(7 - rank_index)
      let rank_parts = string.to_graphemes(rank_as_string)
      let expanded_rank = expand_rank(rank_parts)
      list.index_fold(expanded_rank, acc, fn(acc, square, file_index) {
        let file_index = position.int_to_file(file_index)
        case square {
          "" -> acc
          "K" -> {
            let new_white_king_bitboard =
              board.from_position(position.Position(
                file: file_index,
                rank: rank_index,
              ))
            board.BoardBB(
              black_king_bitboard: acc.black_king_bitboard,
              black_queen_bitboard: acc.black_queen_bitboard,
              black_rook_bitboard: acc.black_rook_bitboard,
              black_bishop_bitboard: acc.black_bishop_bitboard,
              black_knight_bitboard: acc.black_knight_bitboard,
              black_pawns_bitboard: acc.black_pawns_bitboard,
              white_king_bitboard: bitboard.or(
                acc.white_king_bitboard,
                new_white_king_bitboard,
              ),
              white_queen_bitboard: acc.white_queen_bitboard,
              white_rook_bitboard: acc.white_rook_bitboard,
              white_bishop_bitboard: acc.white_bishop_bitboard,
              white_knight_bitboard: acc.white_knight_bitboard,
              white_pawns_bitboard: acc.white_pawns_bitboard,
            )
          }
          "Q" -> {
            let new_white_queen_bitboard =
              board.from_position(position.Position(
                file: file_index,
                rank: rank_index,
              ))
            board.BoardBB(
              black_king_bitboard: acc.black_king_bitboard,
              black_queen_bitboard: acc.black_queen_bitboard,
              black_rook_bitboard: acc.black_rook_bitboard,
              black_bishop_bitboard: acc.black_bishop_bitboard,
              black_knight_bitboard: acc.black_knight_bitboard,
              black_pawns_bitboard: acc.black_pawns_bitboard,
              white_king_bitboard: acc.white_king_bitboard,
              white_queen_bitboard: bitboard.or(
                acc.white_queen_bitboard,
                new_white_queen_bitboard,
              ),
              white_rook_bitboard: acc.white_rook_bitboard,
              white_bishop_bitboard: acc.white_bishop_bitboard,
              white_knight_bitboard: acc.white_knight_bitboard,
              white_pawns_bitboard: acc.white_pawns_bitboard,
            )
          }
          "R" -> {
            let new_white_rook_bitboard =
              board.from_position(position.Position(
                file: file_index,
                rank: rank_index,
              ))
            board.BoardBB(
              black_king_bitboard: acc.black_king_bitboard,
              black_queen_bitboard: acc.black_queen_bitboard,
              black_rook_bitboard: acc.black_rook_bitboard,
              black_bishop_bitboard: acc.black_bishop_bitboard,
              black_knight_bitboard: acc.black_knight_bitboard,
              black_pawns_bitboard: acc.black_pawns_bitboard,
              white_king_bitboard: acc.white_king_bitboard,
              white_queen_bitboard: acc.white_queen_bitboard,
              white_rook_bitboard: bitboard.or(
                acc.white_rook_bitboard,
                new_white_rook_bitboard,
              ),
              white_bishop_bitboard: acc.white_bishop_bitboard,
              white_knight_bitboard: acc.white_knight_bitboard,
              white_pawns_bitboard: acc.white_pawns_bitboard,
            )
          }
          "B" -> {
            let new_white_bishop_bitboard =
              board.from_position(position.Position(
                file: file_index,
                rank: rank_index,
              ))
            board.BoardBB(
              black_king_bitboard: acc.black_king_bitboard,
              black_queen_bitboard: acc.black_queen_bitboard,
              black_rook_bitboard: acc.black_rook_bitboard,
              black_bishop_bitboard: acc.black_bishop_bitboard,
              black_knight_bitboard: acc.black_knight_bitboard,
              black_pawns_bitboard: acc.black_pawns_bitboard,
              white_king_bitboard: acc.white_king_bitboard,
              white_queen_bitboard: acc.white_queen_bitboard,
              white_rook_bitboard: acc.white_rook_bitboard,
              white_bishop_bitboard: bitboard.or(
                acc.white_bishop_bitboard,
                new_white_bishop_bitboard,
              ),
              white_knight_bitboard: acc.white_knight_bitboard,
              white_pawns_bitboard: acc.white_pawns_bitboard,
            )
          }
          "N" -> {
            let new_white_knight_bitboard =
              board.from_position(position.Position(
                file: file_index,
                rank: rank_index,
              ))
            board.BoardBB(
              black_king_bitboard: acc.black_king_bitboard,
              black_queen_bitboard: acc.black_queen_bitboard,
              black_rook_bitboard: acc.black_rook_bitboard,
              black_bishop_bitboard: acc.black_bishop_bitboard,
              black_knight_bitboard: acc.black_knight_bitboard,
              black_pawns_bitboard: acc.black_pawns_bitboard,
              white_king_bitboard: acc.white_king_bitboard,
              white_queen_bitboard: acc.white_queen_bitboard,
              white_rook_bitboard: acc.white_rook_bitboard,
              white_bishop_bitboard: acc.white_bishop_bitboard,
              white_knight_bitboard: bitboard.or(
                acc.white_knight_bitboard,
                new_white_knight_bitboard,
              ),
              white_pawns_bitboard: acc.white_pawns_bitboard,
            )
          }
          "P" -> {
            let new_white_pawn_bitboard =
              board.from_position(position.Position(
                file: file_index,
                rank: rank_index,
              ))
            board.BoardBB(
              black_king_bitboard: acc.black_king_bitboard,
              black_queen_bitboard: acc.black_queen_bitboard,
              black_rook_bitboard: acc.black_rook_bitboard,
              black_bishop_bitboard: acc.black_bishop_bitboard,
              black_knight_bitboard: acc.black_knight_bitboard,
              black_pawns_bitboard: acc.black_pawns_bitboard,
              white_king_bitboard: acc.white_king_bitboard,
              white_queen_bitboard: acc.white_queen_bitboard,
              white_rook_bitboard: acc.white_rook_bitboard,
              white_bishop_bitboard: acc.white_bishop_bitboard,
              white_knight_bitboard: acc.white_knight_bitboard,
              white_pawns_bitboard: bitboard.or(
                acc.white_pawns_bitboard,
                new_white_pawn_bitboard,
              ),
            )
          }
          "k" -> {
            let new_black_king_bitboard =
              board.from_position(position.Position(
                file: file_index,
                rank: rank_index,
              ))
            board.BoardBB(
              black_king_bitboard: bitboard.or(
                acc.black_king_bitboard,
                new_black_king_bitboard,
              ),
              black_queen_bitboard: acc.black_queen_bitboard,
              black_rook_bitboard: acc.black_rook_bitboard,
              black_bishop_bitboard: acc.black_bishop_bitboard,
              black_knight_bitboard: acc.black_knight_bitboard,
              black_pawns_bitboard: acc.black_pawns_bitboard,
              white_king_bitboard: acc.white_king_bitboard,
              white_queen_bitboard: acc.white_queen_bitboard,
              white_rook_bitboard: acc.white_rook_bitboard,
              white_bishop_bitboard: acc.white_bishop_bitboard,
              white_knight_bitboard: acc.white_knight_bitboard,
              white_pawns_bitboard: acc.white_pawns_bitboard,
            )
          }
          "q" -> {
            let new_black_queen_bitboard =
              board.from_position(position.Position(
                file: file_index,
                rank: rank_index,
              ))
            board.BoardBB(
              black_king_bitboard: acc.black_king_bitboard,
              black_queen_bitboard: bitboard.or(
                acc.black_queen_bitboard,
                new_black_queen_bitboard,
              ),
              black_rook_bitboard: acc.black_rook_bitboard,
              black_bishop_bitboard: acc.black_bishop_bitboard,
              black_knight_bitboard: acc.black_knight_bitboard,
              black_pawns_bitboard: acc.black_pawns_bitboard,
              white_king_bitboard: acc.white_king_bitboard,
              white_queen_bitboard: acc.white_queen_bitboard,
              white_rook_bitboard: acc.white_rook_bitboard,
              white_bishop_bitboard: acc.white_bishop_bitboard,
              white_knight_bitboard: acc.white_knight_bitboard,
              white_pawns_bitboard: acc.white_pawns_bitboard,
            )
          }
          "r" -> {
            let new_black_rook_bitboard =
              board.from_position(position.Position(
                file: file_index,
                rank: rank_index,
              ))
            board.BoardBB(
              black_king_bitboard: acc.black_king_bitboard,
              black_queen_bitboard: acc.black_queen_bitboard,
              black_rook_bitboard: bitboard.or(
                acc.black_rook_bitboard,
                new_black_rook_bitboard,
              ),
              black_bishop_bitboard: acc.black_bishop_bitboard,
              black_knight_bitboard: acc.black_knight_bitboard,
              black_pawns_bitboard: acc.black_pawns_bitboard,
              white_king_bitboard: acc.white_king_bitboard,
              white_queen_bitboard: acc.white_queen_bitboard,
              white_rook_bitboard: acc.white_rook_bitboard,
              white_bishop_bitboard: acc.white_bishop_bitboard,
              white_knight_bitboard: acc.white_knight_bitboard,
              white_pawns_bitboard: acc.white_pawns_bitboard,
            )
          }
          "b" -> {
            let new_black_bishop_bitboard =
              board.from_position(position.Position(
                file: file_index,
                rank: rank_index,
              ))
            board.BoardBB(
              black_king_bitboard: acc.black_king_bitboard,
              black_queen_bitboard: acc.black_queen_bitboard,
              black_rook_bitboard: acc.black_rook_bitboard,
              black_bishop_bitboard: bitboard.or(
                acc.black_bishop_bitboard,
                new_black_bishop_bitboard,
              ),
              black_knight_bitboard: acc.black_knight_bitboard,
              black_pawns_bitboard: acc.black_pawns_bitboard,
              white_king_bitboard: acc.white_king_bitboard,
              white_queen_bitboard: acc.white_queen_bitboard,
              white_rook_bitboard: acc.white_rook_bitboard,
              white_bishop_bitboard: acc.white_bishop_bitboard,
              white_knight_bitboard: acc.white_knight_bitboard,
              white_pawns_bitboard: acc.white_pawns_bitboard,
            )
          }
          "n" -> {
            let new_black_knight_bitboard =
              board.from_position(position.Position(
                file: file_index,
                rank: rank_index,
              ))
            board.BoardBB(
              black_king_bitboard: acc.black_king_bitboard,
              black_queen_bitboard: acc.black_queen_bitboard,
              black_rook_bitboard: acc.black_rook_bitboard,
              black_bishop_bitboard: acc.black_bishop_bitboard,
              black_knight_bitboard: bitboard.or(
                acc.black_knight_bitboard,
                new_black_knight_bitboard,
              ),
              black_pawns_bitboard: acc.black_pawns_bitboard,
              white_king_bitboard: acc.white_king_bitboard,
              white_queen_bitboard: acc.white_queen_bitboard,
              white_rook_bitboard: acc.white_rook_bitboard,
              white_bishop_bitboard: acc.white_bishop_bitboard,
              white_knight_bitboard: acc.white_knight_bitboard,
              white_pawns_bitboard: acc.white_pawns_bitboard,
            )
          }
          "p" -> {
            let new_black_pawns_bitboard =
              board.from_position(position.Position(
                file: file_index,
                rank: rank_index,
              ))
            board.BoardBB(
              black_king_bitboard: acc.black_king_bitboard,
              black_queen_bitboard: acc.black_queen_bitboard,
              black_rook_bitboard: acc.black_rook_bitboard,
              black_bishop_bitboard: acc.black_bishop_bitboard,
              black_knight_bitboard: acc.black_knight_bitboard,
              black_pawns_bitboard: bitboard.or(
                acc.black_pawns_bitboard,
                new_black_pawns_bitboard,
              ),
              white_king_bitboard: acc.white_king_bitboard,
              white_queen_bitboard: acc.white_queen_bitboard,
              white_rook_bitboard: acc.white_rook_bitboard,
              white_bishop_bitboard: acc.white_bishop_bitboard,
              white_knight_bitboard: acc.white_knight_bitboard,
              white_pawns_bitboard: acc.white_pawns_bitboard,
            )
          }
          _ -> {
            panic
          }
        }
      })
    },
  )
}

fn expand_rank(rank: List(String)) -> List(String) {
  let accumulator = []
  list.fold(rank, accumulator, fn(acc, part) {
    case part {
      "1" -> list.append(acc, [""])
      "2" -> list.append(acc, ["", ""])
      "3" -> list.append(acc, ["", "", ""])
      "4" -> list.append(acc, ["", "", "", ""])
      "5" -> list.append(acc, ["", "", "", "", ""])
      "6" -> list.append(acc, ["", "", "", "", "", ""])
      "7" -> list.append(acc, ["", "", "", "", "", "", ""])
      "8" -> list.append(acc, ["", "", "", "", "", "", "", ""])
      "K" -> list.append(acc, ["K"])
      "Q" -> list.append(acc, ["Q"])
      "R" -> list.append(acc, ["R"])
      "B" -> list.append(acc, ["B"])
      "N" -> list.append(acc, ["N"])
      "P" -> list.append(acc, ["P"])
      "k" -> list.append(acc, ["k"])
      "q" -> list.append(acc, ["q"])
      "r" -> list.append(acc, ["r"])
      "b" -> list.append(acc, ["b"])
      "n" -> list.append(acc, ["n"])
      "p" -> list.append(acc, ["p"])
      _ -> list.append(acc, [part])
    }
  })
}

fn parse_turn(turn_string: String) -> Color {
  case turn_string {
    "w" -> White
    "b" -> Black
    _ -> panic as "Invalid turn string, must be 'w' or 'b'"
  }
}

fn parse_castling(castling_string: String) -> CastlingStatus {
  case string.length(castling_string) <= 4 {
    True -> {
      let cs_parts = string.split(castling_string, "")
      list.each(cs_parts, fn(part) {
        case part {
          "K" -> Nil
          "Q" -> Nil
          "k" -> Nil
          "q" -> Nil
          "-" -> Nil
          _ -> panic as "Invalid castling string"
        }
      })

      let white_queenside_castling = string.contains(castling_string, "Q")
      let white_kingside_castling = string.contains(castling_string, "K")
      let black_queenside_castling = string.contains(castling_string, "q")
      let black_kingside_castling = string.contains(castling_string, "k")
      CastlingStatus(
        white_kingside: white_kingside_castling,
        white_queenside: white_queenside_castling,
        black_kingside: black_kingside_castling,
        black_queenside: black_queenside_castling,
      )
    }
    False -> panic as "Invalid castling string"
  }
}

fn parse_en_passant(en_passant_string: String) -> Option(Position) {
  case en_passant_string {
    "-" -> None
    _ -> {
      case string.length(en_passant_string) == 2 {
        True -> Nil
        False -> panic as "Invalid en passant string"
      }
      let en_passant_parts = string.split(en_passant_string, "")
      let assert [file_string, rank_string] = en_passant_parts
      let file = parse_file(file_string)
      let rank = parse_rank(rank_string)
      Some(position.Position(file: file, rank: rank))
    }
  }
}

fn parse_file(file_string: String) -> File {
  case file_string {
    "a" -> position.A
    "b" -> position.B
    "c" -> position.C
    "d" -> position.D
    "e" -> position.E
    "f" -> position.F
    "g" -> position.G
    "h" -> position.H
    _ -> panic as "Invalid file string"
  }
}

fn parse_rank(rank_string: String) -> Rank {
  case rank_string {
    "1" -> position.One
    "2" -> position.Two
    "3" -> position.Three
    "4" -> position.Four
    "5" -> position.Five
    "6" -> position.Six
    "7" -> position.Seven
    "8" -> position.Eight
    _ -> panic as "Invalid rank string"
  }
}

fn parse_halfmove(halfmove_string: String) -> HalfMove {
  string_to_int(halfmove_string)
}

fn parse_fullmove(fullmove_string: String) -> FullMove {
  string_to_int(fullmove_string)
}

fn string_to_int(string: String) -> Int {
  case string.length(string) {
    1 -> {
      case string {
        "0" -> 0
        "1" -> 1
        "2" -> 2
        "3" -> 3
        "4" -> 4
        "5" -> 5
        "6" -> 6
        "7" -> 7
        "8" -> 8
        "9" -> 9
        _ -> panic as "Invalid halfmove string"
      }
    }
    2 -> {
      let assert [tenths_place_string, ones_place_string] =
        string.split(string, "")
      let tenths_place = case tenths_place_string {
        "0" -> 0
        "1" -> 10
        "2" -> 20
        "3" -> 30
        "4" -> 40
        "5" -> 50
        "6" -> 60
        "7" -> 70
        "8" -> 80
        "9" -> 90
        _ -> panic as "Invalid halfmove string"
      }

      let ones_place = case ones_place_string {
        "0" -> 0
        "1" -> 1
        "2" -> 2
        "3" -> 3
        "4" -> 4
        "5" -> 5
        "6" -> 6
        "7" -> 7
        "8" -> 8
        "9" -> 9
        _ -> panic as "Invalid halfmove string"
      }
      tenths_place + ones_place
    }
    3 -> {
      let assert [hundreds_place_string, tenths_place_string, ones_place_string] =
        string.split(string, "")
      let hundreds_place = case hundreds_place_string {
        "0" -> 0
        "1" -> 100
        "2" -> 200
        "3" -> 300
        "4" -> 400
        "5" -> 500
        "6" -> 600
        "7" -> 700
        "8" -> 800
        "9" -> 900
        _ -> panic as "Invalid halfmove string"
      }

      let tenths_place = case tenths_place_string {
        "0" -> 0
        "1" -> 10
        "2" -> 20
        "3" -> 30
        "4" -> 40
        "5" -> 50
        "6" -> 60
        "7" -> 70
        "8" -> 80
        "9" -> 90
        _ -> panic as "Invalid halfmove string"
      }

      let ones_place = case ones_place_string {
        "0" -> 0
        "1" -> 1
        "2" -> 2
        "3" -> 3
        "4" -> 4
        "5" -> 5
        "6" -> 6
        "7" -> 7
        "8" -> 8
        "9" -> 9
        _ -> panic as "Invalid halfmove string"
      }
      hundreds_place + tenths_place + ones_place
    }
    _ -> panic as "Invalid halfmove string"
  }
}
