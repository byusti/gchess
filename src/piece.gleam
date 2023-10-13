import color.{type Color}

pub type Piece {
  Piece(color: Color, kind: Kind)
}

pub type Kind {
  Pawn
  Knight
  Bishop
  Rook
  Queen
  King
}
