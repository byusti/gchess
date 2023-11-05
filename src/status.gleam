import color.{type Color}
import board.{type BoardBB}
import position.{type Position}
import gleam/option.{type Option}
import castle_rights.{type CastleRights}
import gleam/map.{type Map}

pub type DrawReason {
  Stalemate
  FiftyMoveRule
  ThreefoldRepetition
  InsufficientMaterial
  Manual
}

pub type WinReason {
  Checkmate
  Resignation
  Timeout
}

pub type ThreeFoldPosition {
  ThreeFoldPosition(
    turn: Color,
    board: BoardBB,
    en_passant: Option(Position),
    white_kingside_castle: CastleRights,
    white_queenside_castle: CastleRights,
    black_kingside_castle: CastleRights,
    black_queenside_castle: CastleRights,
  )
}

pub type Status {
  Draw(reason: DrawReason)
  Win(winner: Color, reason: String)
  InProgress(
    fifty_move_rule: Int,
    threefold_repetition_rule: Map(ThreeFoldPosition, Int),
  )
}

pub fn to_string(status: Status) -> String {
  case status {
    InProgress(_, _) -> "In Progress"
    Draw(_) -> "Draw"
    Win(_, _) -> "Win"
  }
}
