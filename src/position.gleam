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

pub fn to_int(position: Position) -> Int {
  let file = file_to_int(position.file)
  let rank = rank_to_int(position.rank)
  let pos_as_int = file + { rank * 8 }
  pos_as_int
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

pub fn int_to_position(i: Int) -> Position {
  let file = int_to_file(i % 8)
  let rank = int_to_rank(i / 8)
  Position(file, rank)
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
