import game.{BoardBB}
import color.{Black, Color, White}
import position.{File, Rank}
import gleam/string
import gleam/list
import gleam/option.{None, Option, Some}
import piece
import bitboard.{Bitboard}

type CastlingStatus {
  CastlingStatus(
    white_kingside: Bool,
    white_queenside: Bool,
    black_kingside: Bool,
    black_queenside: Bool,
  )
}

type EnPassant {
  EnPassant(file: File, rank: Rank)
}

type HalfMove =
  Int

type FullMove =
  Int

type Fen {
  Fen(
    board: BoardBB,
    turn: Color,
    castling: CastlingStatus,
    en_passant: Option(EnPassant),
    halfmove: HalfMove,
    fullmove: FullMove,
  )
}

fn parse_fen(fen: String) -> Fen {
  let fen_string_parts = string.split(fen, " ")
  case list.length(fen_string_parts) == 6 {
    False -> panic as "Invalid FEN string"
    True -> {
      let [board_string, ..rest] = fen_string_parts
      let [turn_string, ..rest] = rest
      let [castling_string, ..rest] = rest
      let [en_passant_string, ..rest] = rest
      let [halfmove_string, ..rest] = rest
      let [fullmove_string, ..rest] = rest
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

fn parse_board(board_string: String) -> BoardBB {
  // in the context of this function, rank means a an entire row of the board 
  // represented as a string of piece chars and numbers for empy spaces
  // example: "rnbqk1nr"
  let list_of_ranks_as_strings = string.split(board_string, "/")
  let accumulator =
    BoardBB(
      black_king_bitboard: Bitboard(0),
      black_queen_bitboard: Bitboard(0),
      black_rook_bitboard: Bitboard(0),
      black_bishop_bitboard: Bitboard(0),
      black_knight_bitboard: Bitboard(0),
      black_pawns_bitboard: Bitboard(0),
      white_king_bitboard: Bitboard(0),
      white_queen_bitboard: Bitboard(0),
      white_rook_bitboard: Bitboard(0),
      white_bishop_bitboard: Bitboard(0),
      white_knight_bitboard: Bitboard(0),
      white_pawns_bitboard: Bitboard(0),
    )
  list.index_fold(
    list_of_ranks_as_strings,
    accumulator,
    fn(acc, rank_as_string, rank_index) {
      let rank_index = position.int_to_rank(7 - rank_index)
      let rank_parts = string.to_graphemes(rank_as_string)
      let expanded_rank = expand_rank(rank_parts)
      list.index_fold(
        expanded_rank,
        acc,
        fn(acc, square, file_index) {
          let file_index = position.int_to_file(file_index)
          case square {
            "" -> acc
            "K" -> {
              todo
            }
          }
          todo
        },
      )
      todo
    },
  )

  todo
}

fn expand_rank(rank: List(String)) -> List(String) {
  let accumulator = []
  list.fold(
    rank,
    accumulator,
    fn(acc, part) {
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
    },
  )
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
      list.each(
        cs_parts,
        fn(part) {
          case part {
            "K" -> Nil
            "Q" -> Nil
            "k" -> Nil
            "q" -> Nil
            _ -> panic as "Invalid castling string"
          }
        },
      )

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

fn parse_en_passant(en_passant_string: String) -> Option(EnPassant) {
  case en_passant_string {
    "-" -> None
    _ -> {
      case string.length(en_passant_string) == 2 {
        True -> Nil
        False -> panic as "Invalid en passant string"
      }
      let en_passant_parts = string.split(en_passant_string, "")
      let [file_string, rank_string] = en_passant_parts
      let file = parse_file(file_string)
      let rank = parse_rank(rank_string)
      Some(EnPassant(file: file, rank: rank))
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
      let [tenths_place_string, ones_place_string] = string.split(string, "")
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
      let [hundreds_place_string, tenths_place_string, ones_place_string] =
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