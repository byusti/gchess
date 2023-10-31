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
    Normal(_, _, option.None, option.None) -> ""
    Normal(_, _, option.None, option.Some(promotion)) ->
      " promoting to " <> piece.to_string(promotion)
    Normal(_, _, option.Some(captured), option.None) ->
      " capturing " <> piece.to_string(captured)
    Normal(_, _, option.Some(captured), option.Some(promotion)) ->
      " capturing " <> piece.to_string(captured) <> " and promoting to " <> piece.to_string(
        promotion,
      )
    Castle(_, _) -> " castling"
    EnPassant(_, _) -> " en passant"
  }
  from <> "" <> to <> captured
}
