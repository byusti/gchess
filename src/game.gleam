import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/option.{None, Option, Some}
import gleam/io

pub type Color {
  White
  Black
}

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

pub type Turn {
  Turn(color: Color)
}

pub type Status {
  Checkmate
  Stalemate
  InProgress
}

pub type Move {
  Move(from: Position, to: Position)
}

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

pub type Board {
  Board(rows: List(List(Option(Piece))))
}

pub type Game {
  Game(board: Board, turn: Turn, history: List(Move), status: Status, ply: Int)
}

pub type Message {
  Shutdown
  PrintBoard(reply_with: Subject(Nil))
}

fn handle_message(message: Message, game_state: Game) -> actor.Next(Game) {
  case message {
    Shutdown -> actor.Stop(process.Normal)
    PrintBoard(client) -> {
      io.print(
        "   
   +---+---+---+---+---+---+---+---+
 1 | ♖ | ♘ | ♗ | ♕ | ♔ | ♗ | ♘ | ♖ |
   +---+---+---+---+---+---+---+---+
 2 | ♙ | ♙ | ♙ | ♙ | ♙ | ♙ | ♙ | ♙ |
   +---+---+---+---+---+---+---+---+
 3 |   |   |   |   |   |   |   |   |
   +---+---+---+---+---+---+---+---+
 4 |   |   |   |   |   |   |   |   |
   +---+---+---+---+---+---+---+---+
 5 |   |   |   |   |   |   |   |   |
   +---+---+---+---+---+---+---+---+ 
 6 |   |   |   |   |   |   |   |   |
   +---+---+---+---+---+---+---+---+
 7 | ♟ | ♟ | ♟ | ♟ | ♟ | ♟ | ♟ | ♟ |
   +---+---+---+---+---+---+---+---+
 8 | ♜ | ♞ | ♝ | ♚ | ♛ | ♝ | ♞ | ♜ |
   +---+---+---+---+---+---+---+---+
     A   B   C   D   E   F   G   H
 ",
      )
      process.send(client, Nil)
      actor.Continue(game_state)
    }
  }
}

pub fn new_game() {
  let board =
    Board(rows: [
      [
        Some(Piece(White, Rook)),
        Some(Piece(White, Knight)),
        Some(Piece(White, Bishop)),
        Some(Piece(White, Queen)),
        Some(Piece(White, King)),
        Some(Piece(White, Bishop)),
        Some(Piece(White, Knight)),
        Some(Piece(White, Rook)),
      ],
      [
        Some(Piece(White, Pawn)),
        Some(Piece(White, Pawn)),
        Some(Piece(White, Pawn)),
        Some(Piece(White, Pawn)),
        Some(Piece(White, Pawn)),
        Some(Piece(White, Pawn)),
        Some(Piece(White, Pawn)),
        Some(Piece(White, Pawn)),
      ],
      [None, None, None, None, None, None, None, None],
      [None, None, None, None, None, None, None, None],
      [None, None, None, None, None, None, None, None],
      [None, None, None, None, None, None, None, None],
      [
        Some(Piece(Black, Pawn)),
        Some(Piece(Black, Pawn)),
        Some(Piece(Black, Pawn)),
        Some(Piece(Black, Pawn)),
        Some(Piece(Black, Pawn)),
        Some(Piece(Black, Pawn)),
        Some(Piece(Black, Pawn)),
        Some(Piece(Black, Pawn)),
      ],
      [
        Some(Piece(Black, Rook)),
        Some(Piece(Black, Knight)),
        Some(Piece(Black, Bishop)),
        Some(Piece(Black, Queen)),
        Some(Piece(Black, King)),
        Some(Piece(Black, Bishop)),
        Some(Piece(Black, Knight)),
        Some(Piece(Black, Rook)),
      ],
    ])

  let turn = Turn(White)

  let history = []

  let status = InProgress

  let ply = 0

  let assert Ok(actor) =
    actor.start(Game(board, turn, history, status, ply), handle_message)
  actor
}
