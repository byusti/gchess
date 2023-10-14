import color.{type Color, Black, White}
import gleam/io
import gleam/int
import gleam/option.{None, Option, Some}

pub type Position {
  Position(file: File, rank: Rank)
}

pub type File {
  A
  B
  C
  D
  E
  F
  G
  H
}

pub type Rank {
  One
  Two
  Three
  Four
  Five
  Six
  Seven
  Eight
}

pub fn distance_between(position1: Position, position2: Position) -> Int {
  let pos1_as_int = to_int(position1)
  let pos2_as_int = to_int(position2)
  let distance = pos1_as_int - pos2_as_int
  distance
}

pub fn to_int(position: Position) -> Int {
  let file = file_to_int(position.file)
  let rank = rank_to_int(position.rank)
  let pos_as_int = file + { rank * 8 }
  pos_as_int
}

pub fn to_string(position: Position) -> String {
  let file = file_to_string(position.file)
  let rank = rank_to_string(position.rank)
  let pos_as_string = file <> rank
  pos_as_string
}

pub fn file_to_string(file: File) -> String {
  case file {
    A -> "a"
    B -> "b"
    C -> "c"
    D -> "d"
    E -> "e"
    F -> "f"
    G -> "g"
    H -> "h"
  }
}

pub fn rank_to_string(rank: Rank) -> String {
  case rank {
    One -> "1"
    Two -> "2"
    Three -> "3"
    Four -> "4"
    Five -> "5"
    Six -> "6"
    Seven -> "7"
    Eight -> "8"
  }
}

pub fn file_to_int(file: File) -> Int {
  case file {
    A -> 0
    B -> 1
    C -> 2
    D -> 3
    E -> 4
    F -> 5
    G -> 6
    H -> 7
  }
}

pub fn rank_to_int(rank: Rank) -> Int {
  case rank {
    One -> 0
    Two -> 1
    Three -> 2
    Four -> 3
    Five -> 4
    Six -> 5
    Seven -> 6
    Eight -> 7
  }
}

pub fn from_int(i: Int) -> Option(Position) {
  case i {
    i if i >= 0 && i < 64 -> {
      let file = int_to_file(i % 8)
      let rank = int_to_rank(i / 8)
      Some(Position(file, rank))
    }
    _ -> None
  }
}

pub fn int_to_rank(i: Int) -> Rank {
  case i {
    0 -> One
    1 -> Two
    2 -> Three
    3 -> Four
    4 -> Five
    5 -> Six
    6 -> Seven
    7 -> Eight
  }
}

pub fn int_to_file(i: Int) -> File {
  case i {
    0 -> A
    1 -> B
    2 -> C
    3 -> D
    4 -> E
    5 -> F
    6 -> G
    7 -> H
  }
}

//a function that returns a position that is x squares rank-wise away from the given position and y squares file-wise away from the given position
pub fn get_position(position: Position, x: Int, y: Int) -> Position {
  let file = get_file(position.file, y)
  let rank = get_rank(position.rank, x)
  Position(file, rank)
}

pub fn get_position_relative(
  position: Position,
  x: Int,
  y: Int,
  relative_to: Color,
) -> Position {
  let file = get_file_relative(position.file, y, relative_to)
  let rank = get_rank_relative(position.rank, x, relative_to)
  Position(file, rank)
}

pub fn get_file_relative(file: File, y: Int, relative_to: Color) -> File {
  case relative_to {
    White -> get_file(file, y)
    Black -> get_file(file, -y)
  }
}

pub fn get_rank_relative(rank: Rank, x: Int, relative_to: Color) -> Rank {
  case relative_to {
    White -> get_rank(rank, x)
    Black -> get_rank(rank, -x)
  }
}

pub fn get_file(file: File, y: Int) -> File {
  let file_as_int = file_to_int(file)
  let new_file_as_int = file_as_int + y
  let new_file = int_to_file(new_file_as_int)
  new_file
}

pub fn get_rank(rank: Rank, x: Int) -> Rank {
  let rank_as_int = rank_to_int(rank)
  let new_rank_as_int = rank_as_int + x
  let new_rank = int_to_rank(new_rank_as_int)
  new_rank
}

pub fn get_rear_position(position: Position, color: Color) -> Position {
  let rank = get_rear_rank(position.rank, color)
  Position(position.file, rank)
}

pub fn get_rear_rank(rank: Rank, color: Color) -> Rank {
  case color {
    White -> get_rear_white_rank(rank)
    Black -> get_rear_black_rank(rank)
  }
}

pub fn get_rear_white_rank(rank: Rank) -> Rank {
  case rank {
    One -> One
    Two -> One
    Three -> Two
    Four -> Three
    Five -> Four
    Six -> Five
    Seven -> Six
    Eight -> Seven
  }
}

pub fn get_rear_black_rank(rank: Rank) -> Rank {
  case rank {
    One -> Two
    Two -> Three
    Three -> Four
    Four -> Five
    Five -> Six
    Six -> Seven
    Seven -> Eight
    Eight -> Eight
  }
}
