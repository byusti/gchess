import gleam/option.{type Option}
import piece.{type Piece}
import position.{type Position}

pub type Move {
  Normal(from: Position, to: Position, promotion: Option(Piece))
  Castle(from: Position, to: Position)
  EnPassant(from: Position, to: Position)
}

pub type MoveWithCapture {
  MoveWithCapture(move: Move, captured_piece: Option(Piece))
}
