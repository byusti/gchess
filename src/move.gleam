import position.{type Position}
import piece.{type Piece}

pub type Move {
  SimpleMove(from: Position, to: Position)
  CaptureMove(from: Position, to: Position, captured: Piece)
}

pub fn to_string(move: Move) -> String {
  let from = position.to_string(move.from)
  let to = position.to_string(move.to)
  from <> " -> " <> to
}
