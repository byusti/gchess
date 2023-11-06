import move.{type Move}
import position.{type Position}
import piece.{type Kind, type Piece}
import color
import gleam/option.{type Option}
import gleam/string

pub type MoveSan {
  NormalSan(
    from: Option(Position),
    to: Position,
    moving_piece: Kind,
    capture: Option(Kind),
    promotion: Option(Kind),
    check: Bool,
    checkmate: Bool,
  )
  Castle(from: Position, to: Position, check: Bool, checkmate: Bool)
  EnPassant(from: Position, to: Position, check: Bool, checkmate: Bool)
}

pub type ErrorSan {
  InvalidCastleString
}

pub fn from_string(san: String) -> Result(MoveSan, ErrorSan) {
  case string.to_graphemes(san) {
    [] -> panic("Cannot parse empty string.")
    ["K", ..rest]
    | ["Q", ..rest]
    | ["R", ..rest]
    | ["B", ..rest]
    | ["N", ..rest] -> {
      todo
    }
    ["O", ..rest] | ["0", ..rest] -> {
      case rest {
        ["-", "O", "-", "O", ..checks_or_checkmates]
        | ["-", "0", "-", "0", ..checks_or_checkmates] -> {
          //   Castle(
          //     from: position.Position(file: position.E, rank: position.One),
          //     to: position.Position(file: position.G, rank: position.One),
          //     check: false,
          //     checkmate: false,
          //   )
          todo
        }
        ["-", "O", ..checks_or_checkmates] | ["-", "0", ..checks_or_checkmates] -> {
          todo
        }
        _ -> Error(InvalidCastleString)
      }
    }
    _ -> todo
  }
}
