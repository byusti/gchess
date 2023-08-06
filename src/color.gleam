pub type Color {
  White
  Black
}

pub fn to_string(color: Color) -> String {
  case color {
    White -> "White"
    Black -> "Black"
  }
}
