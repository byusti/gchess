import position.{type Position}
import piece.{type Piece}
import gleam/option.{type Option}

pub type Move {
  Normal(
    from: Position,
    to: Position,
    captured: Option(Piece),
    promotion: Option(Piece),
  )
  Castle(from: Position, to: Position)
  EnPassant(from: Position, to: Position)
}

pub fn to_string(move: Move) -> String {
  let from = position.to_string(move.from)
  let to = position.to_string(move.to)
  let captured = case move {
    Normal(_, _, option.None, _) -> ""
    Normal(_, _, option.Some(captured), _) ->
      " capturing " <> piece.to_string(captured)
    Castle(_, _) -> ""
    EnPassant(_, _) -> ""
  }
  from <> " -> " <> to <> captured
}
