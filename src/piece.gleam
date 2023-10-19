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

pub fn to_string(piece: Piece) -> String {
  let kind = case piece.kind {
    Pawn -> "Pawn"
    Knight -> "Knight"
    Bishop -> "Bishop"
    Rook -> "Rook"
    Queen -> "Queen"
    King -> "King"
  }

  let color = case piece.color {
    color.White -> color.to_string(color.White)
    color.Black -> color.to_string(color.Black)
  }

  color <> " " <> kind
}
