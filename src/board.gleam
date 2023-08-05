import position.{Position}
import piece.{Piece}
import boardbb.{BoardBB}
import fen.{parse_board}
import gleam/option.{Option}
import gleam/map
import gleam/string
import gleam/list

pub type BoardMap =
  map.Map(Position, Option(Piece))

pub fn from_fen(fen: String) -> BoardBB {
  let fen_string_parts = string.split(fen, " ")
  let parsed_board = case list.length(fen_string_parts) == 6 {
    False -> panic as "Invalid FEN string"
    True -> {
      let [board_string, ..] = fen_string_parts
      let parsed_board = parse_board(board_string)
      parsed_board
    }
  }
  parsed_board
}
