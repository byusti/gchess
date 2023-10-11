import position.{Position}

pub type Move {
  Move(from: Position, to: Position)
}

pub fn to_string(move: Move) -> String {
  let from = position.to_string(move.from)
  let to = position.to_string(move.to)
  from <> " -> " <> to
}
