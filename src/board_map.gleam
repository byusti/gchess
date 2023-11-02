import position.{type Position}
import piece.{type Piece}
import gleam/option.{type Option}
import gleam/map

// Representation of the the board as a map of positions to pieces
// Used for pretty printing the state of the board
pub type BoardMap =
  map.Map(Position, Option(Piece))
