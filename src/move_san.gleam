import position.{type File, type Rank}
import piece.{type Kind}
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/string_builder
import gleam/list

pub type MoveSan {
  Normal(
    from: Option(PositionSan),
    to: PositionSan,
    moving_piece: Kind,
    capture: Bool,
    promotion: Option(Kind),
    maybe_check_or_checkmate: Option(CheckOrCheckMate),
  )
  Castle(side: CastleSide, maybe_check_or_checkmate: Option(CheckOrCheckMate))
  EnPassant(
    from: Option(PositionSan),
    to: PositionSan,
    maybe_check_or_checkmate: Option(CheckOrCheckMate),
  )
}

pub type PositionSan {
  PositionSan(file: Option(File), rank: Option(Rank))
}

pub type ErrorSan {
  InvalidMoveString
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
            from: Some(PositionSan(file: Some(from_file), rank: Some(from_rank))),
            to: PositionSan(file: Some(to_file), rank: Some(to_rank)),
            moving_piece: moving_piece,
            capture: capture,
            promotion: promotion,
            maybe_check_or_checkmate: check_or_checkmate,
          ))
        }
        3 -> {
          let [maybe_from_file_or_from_rank, to_file, to_rank] =
            positional_information
          case maybe_from_file_or_from_rank {
            "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" -> {
              let from_file = case maybe_from_file_or_from_rank {
                "a" -> position.A
                "b" -> position.B
                "c" -> position.C
                "d" -> position.D
                "e" -> position.E
                "f" -> position.F
                "g" -> position.G
                "h" -> position.H
                _ -> panic("Invalid file")
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
                from: Some(PositionSan(file: Some(from_file), rank: None)),
                to: PositionSan(file: Some(to_file), rank: Some(to_rank)),
                moving_piece: moving_piece,
                capture: capture,
                promotion: promotion,
                maybe_check_or_checkmate: check_or_checkmate,
              ))
            }
            "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" -> {
              let from_rank = case maybe_from_file_or_from_rank {
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
                from: Some(PositionSan(file: None, rank: Some(from_rank))),
                to: PositionSan(file: Some(to_file), rank: Some(to_rank)),
                moving_piece: moving_piece,
                capture: capture,
                promotion: promotion,
                maybe_check_or_checkmate: check_or_checkmate,
              ))
            }
            _ -> Error(InvalidPositionalInformation)
          }
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
            to: PositionSan(file: Some(to_file), rank: Some(to_rank)),
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
    [pawn_move_first_grapheme, ..rest] if pawn_move_first_grapheme == "a" || pawn_move_first_grapheme == "b" || pawn_move_first_grapheme == "c" || pawn_move_first_grapheme == "d" || pawn_move_first_grapheme == "e" || pawn_move_first_grapheme == "f" || pawn_move_first_grapheme == "g" || pawn_move_first_grapheme == "h" -> {
      let is_en_passant =
        string.contains(
          string_builder.to_string(string_builder.from_strings(rest)),
          "e.p.",
        )

      let rest =
        string.replace(
          string_builder.to_string(string_builder.from_strings(rest)),
          "e.p.",
          "",
        )

      let rest = string.trim(rest)

      let rest = string.to_graphemes(rest)

      let capture = list.contains(rest, "x")

      let rest = list.filter(rest, fn(grapheme) { grapheme != "x" })

      let #(promotion_segment, rest) =
        list.partition(
          [pawn_move_first_grapheme, ..rest],
          fn(grapheme) {
            case grapheme {
              "=" | "Q" | "R" | "B" | "N" -> True
              _ -> False
            }
          },
        )

      let promotion = case promotion_segment {
        [] -> None
        ["=", "Q", ..] -> Some(piece.Queen)
        ["=", "R", ..] -> Some(piece.Rook)
        ["=", "B", ..] -> Some(piece.Bishop)
        ["=", "N", ..] -> Some(piece.Knight)
      }

      let maybe_check_or_checkmate = case list.last(rest) {
        Ok("+") -> Some(Check)
        Ok("#") -> Some(CheckMate)
        _ -> None
      }

      let positional_information =
        list.filter(rest, fn(grapheme) { grapheme != "+" && grapheme != "#" })

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

          case is_en_passant {
            True -> {
              Ok(EnPassant(
                from: Some(PositionSan(
                  file: Some(from_file),
                  rank: Some(from_rank),
                )),
                to: PositionSan(file: Some(to_file), rank: Some(to_rank)),
                maybe_check_or_checkmate: maybe_check_or_checkmate,
              ))
            }
            False -> {
              Ok(Normal(
                from: Some(PositionSan(
                  file: Some(from_file),
                  rank: Some(from_rank),
                )),
                to: PositionSan(file: Some(to_file), rank: Some(to_rank)),
                moving_piece: piece.Pawn,
                capture: capture,
                promotion: promotion,
                maybe_check_or_checkmate: maybe_check_or_checkmate,
              ))
            }
          }
        }
        3 -> {
          let [maybe_from_file_or_from_rank, to_file, to_rank] =
            positional_information
          case maybe_from_file_or_from_rank {
            "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" -> {
              let from_file = case maybe_from_file_or_from_rank {
                "a" -> position.A
                "b" -> position.B
                "c" -> position.C
                "d" -> position.D
                "e" -> position.E
                "f" -> position.F
                "g" -> position.G
                "h" -> position.H
                _ -> panic("Invalid file")
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

              case is_en_passant {
                True -> {
                  Ok(EnPassant(
                    from: Some(PositionSan(file: Some(from_file), rank: None)),
                    to: PositionSan(file: Some(to_file), rank: Some(to_rank)),
                    maybe_check_or_checkmate: maybe_check_or_checkmate,
                  ))
                }
                False -> {
                  Ok(Normal(
                    from: Some(PositionSan(file: Some(from_file), rank: None)),
                    to: PositionSan(file: Some(to_file), rank: Some(to_rank)),
                    moving_piece: piece.Pawn,
                    capture: capture,
                    promotion: promotion,
                    maybe_check_or_checkmate: maybe_check_or_checkmate,
                  ))
                }
              }
            }
            "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" -> {
              let from_rank = case maybe_from_file_or_from_rank {
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

              case is_en_passant {
                True -> {
                  Ok(EnPassant(
                    from: Some(PositionSan(file: None, rank: Some(from_rank))),
                    to: PositionSan(file: Some(to_file), rank: Some(to_rank)),
                    maybe_check_or_checkmate: maybe_check_or_checkmate,
                  ))
                }
                False -> {
                  Ok(Normal(
                    from: Some(PositionSan(file: None, rank: Some(from_rank))),
                    to: PositionSan(file: Some(to_file), rank: Some(to_rank)),
                    moving_piece: piece.Pawn,
                    capture: capture,
                    promotion: promotion,
                    maybe_check_or_checkmate: maybe_check_or_checkmate,
                  ))
                }
              }
            }
            _ -> Error(InvalidPositionalInformation)
          }
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

          case is_en_passant {
            True -> {
              Ok(EnPassant(
                from: None,
                to: PositionSan(file: Some(to_file), rank: Some(to_rank)),
                maybe_check_or_checkmate: maybe_check_or_checkmate,
              ))
            }
            False -> {
              Ok(Normal(
                from: None,
                to: PositionSan(file: Some(to_file), rank: Some(to_rank)),
                moving_piece: piece.Pawn,
                capture: capture,
                promotion: promotion,
                maybe_check_or_checkmate: maybe_check_or_checkmate,
              ))
            }
          }
        }
      }
    }
    _ -> Error(InvalidMoveString)
  }
}
