import position.{type Position}
import piece.{type Kind}
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/list

pub type MoveSan {
  Normal(
    from: Option(Position),
    to: Position,
    moving_piece: Kind,
    capture: Bool,
    promotion: Option(Kind),
    maybe_check_or_checkmate: Option(CheckOrCheckMate),
  )
  Castle(side: CastleSide, maybe_check_or_checkmate: Option(CheckOrCheckMate))
  EnPassant(
    from: Option(Position),
    to: Position,
    maybe_check_or_checkmate: Option(CheckOrCheckMate),
  )
}

pub type ErrorSan {
  InvalidCastleString
  InvalidPositionalInformation
}

pub type CastleSide {
  KingSide
  QueenSide
}

pub type CheckOrCheckMate {
  Check
  CheckMate
}

pub fn from_string(san: String) -> Result(MoveSan, ErrorSan) {
  case string.to_graphemes(san) {
    [] -> panic("Cannot parse empty string.")
    [piece_letter, ..rest] if piece_letter == "K" || piece_letter == "Q" || piece_letter == "R" || piece_letter == "B" || piece_letter == "N" -> {
      let check_or_checkmate = case list.last(rest) {
        Ok("+") -> Some(Check)
        Ok("#") -> Some(CheckMate)
        _ -> None
      }

      let moving_piece = case piece_letter {
        "K" -> piece.King
        "Q" -> piece.Queen
        "R" -> piece.Rook
        "B" -> piece.Bishop
        "N" -> piece.Knight
        _ -> panic("Invalid piece letter.")
      }

      let promotion = None

      let capture = list.contains(rest, "x")

      let positional_information =
        list.filter(
          rest,
          fn(grapheme) { grapheme != "+" && grapheme != "#" && grapheme != "x" },
        )

      case list.length(positional_information) {
        4 -> {
          let [from_file, from_rank, to_file, to_rank] = positional_information
          let from_file = case from_file {
            "a" -> position.A
            "b" -> position.B
            "c" -> position.C
            "d" -> position.D
            "e" -> position.E
            "f" -> position.F
            "g" -> position.G
            "h" -> position.H
            _ -> panic("Invalid file.")
          }

          let from_rank = case from_rank {
            "1" -> position.One
            "2" -> position.Two
            "3" -> position.Three
            "4" -> position.Four
            "5" -> position.Five
            "6" -> position.Six
            "7" -> position.Seven
            "8" -> position.Eight
            _ -> panic("Invalid rank.")
          }

          let to_file = case to_file {
            "a" -> position.A
            "b" -> position.B
            "c" -> position.C
            "d" -> position.D
            "e" -> position.E
            "f" -> position.F
            "g" -> position.G
            "h" -> position.H
            _ -> panic("Invalid file.")
          }

          let to_rank = case to_rank {
            "1" -> position.One
            "2" -> position.Two
            "3" -> position.Three
            "4" -> position.Four
            "5" -> position.Five
            "6" -> position.Six
            "7" -> position.Seven
            "8" -> position.Eight
            _ -> panic("Invalid rank.")
          }

          Ok(Normal(
            from: Some(position.Position(file: from_file, rank: from_rank)),
            to: position.Position(file: to_file, rank: to_rank),
            moving_piece: moving_piece,
            capture: capture,
            promotion: promotion,
            maybe_check_or_checkmate: check_or_checkmate,
          ))
        }
        2 -> {
          let [to_file, to_rank] = positional_information
          let to_file = case to_file {
            "a" -> position.A
            "b" -> position.B
            "c" -> position.C
            "d" -> position.D
            "e" -> position.E
            "f" -> position.F
            "g" -> position.G
            "h" -> position.H
            _ -> panic("Invalid file.")
          }

          let to_rank = case to_rank {
            "1" -> position.One
            "2" -> position.Two
            "3" -> position.Three
            "4" -> position.Four
            "5" -> position.Five
            "6" -> position.Six
            "7" -> position.Seven
            "8" -> position.Eight
            _ -> panic("Invalid rank.")
          }

          Ok(Normal(
            from: None,
            to: position.Position(file: to_file, rank: to_rank),
            moving_piece: moving_piece,
            capture: capture,
            promotion: promotion,
            maybe_check_or_checkmate: check_or_checkmate,
          ))
        }
        _ -> {
          Error(InvalidPositionalInformation)
        }
      }
    }
    ["O", ..rest] | ["0", ..rest] -> {
      case rest {
        ["-", "O", "-", "O", ..checks_or_checkmates]
        | ["-", "0", "-", "0", ..checks_or_checkmates] -> {
          case checks_or_checkmates {
            [] -> {
              Ok(Castle(side: QueenSide, maybe_check_or_checkmate: None))
            }
            ["+", ..] -> {
              Ok(Castle(side: QueenSide, maybe_check_or_checkmate: Some(Check)))
            }
            ["#", ..] -> {
              Ok(Castle(
                side: QueenSide,
                maybe_check_or_checkmate: Some(CheckMate),
              ))
            }
          }
        }
        ["-", "O", ..checks_or_checkmates] | ["-", "0", ..checks_or_checkmates] -> {
          case checks_or_checkmates {
            [] -> {
              Ok(Castle(side: KingSide, maybe_check_or_checkmate: None))
            }
            ["+", ..] -> {
              Ok(Castle(side: KingSide, maybe_check_or_checkmate: Some(Check)))
            }
            ["#", ..] -> {
              Ok(Castle(
                side: KingSide,
                maybe_check_or_checkmate: Some(CheckMate),
              ))
            }
          }
        }
        _ -> Error(InvalidCastleString)
      }
    }
    _ -> todo
  }
}
