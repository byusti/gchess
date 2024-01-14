import position.{type Position}
import piece.{type Piece}
import gleam/option.{type Option}
import gleam/dict

// Representation of the the board as a map of positions to pieces
// Used for pretty printing the state of the board
pub type BoardDict =
  dict.Dict(Position, Option(Piece))
