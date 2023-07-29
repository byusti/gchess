import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/option.{None, Option, Some}
import gleam/io
import gleam/list
import gleam/int
import bitboard

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
  Board(
    list_of_list_representation: List(List(Option(Piece))),
    black_king_bitboard: bitboard.Bitboard,
    black_queen_bitboard: bitboard.Bitboard,
    black_rook_bitboard: bitboard.Bitboard,
    black_bishop_bitboard: bitboard.Bitboard,
    black_knight_bitboard: bitboard.Bitboard,
    black_pawn_bitboard: bitboard.Bitboard,
    white_king_bitboard: bitboard.Bitboard,
    white_queen_bitboard: bitboard.Bitboard,
    white_rook_bitboard: bitboard.Bitboard,
    white_bishop_bitboard: bitboard.Bitboard,
    white_knight_bitboard: bitboard.Bitboard,
    white_pawn_bitboard: bitboard.Bitboard,
  )
}

pub type Game {
  Game(board: Board, turn: Turn, history: List(Move), status: Status, ply: Int)
}

pub type Message {
  AllLegalMoves(reply_with: Subject(List(Move)))
  Shutdown
  PrintBoard(reply_with: Subject(Nil))
}

fn handle_message(message: Message, game_state: Game) -> actor.Next(Game) {
  case message {
    AllLegalMoves(client) -> handle_all_legal_moves(game_state, client)
    Shutdown -> actor.Stop(process.Normal)
    PrintBoard(client) -> handle_print_board(game_state, client)
  }
}

fn handle_all_legal_moves(
  game_state: Game,
  client: Subject(List(Move)),
) -> actor.Next(Game) {
  let legal_moves = []
  process.send(client, legal_moves)
  actor.Continue(game_state)
}

fn handle_print_board(
  game_state: Game,
  client: Subject(Nil),
) -> actor.Next(Game) {
  io.print("\n")
  io.print("   +---+---+---+---+---+---+---+---+")
  io.print("\n")
  list.index_map(
    game_state.board.list_of_list_representation,
    fn(index, row) {
      io.print(" " <> int.to_string(index) <> " | ")
      list.each(
        row,
        fn(piece) {
          case piece {
            Some(Piece(White, Pawn)) -> io.print("♙")
            Some(Piece(White, Knight)) -> io.print("♘")
            Some(Piece(White, Bishop)) -> io.print("♗")
            Some(Piece(White, Rook)) -> io.print("♖")
            Some(Piece(White, Queen)) -> io.print("♕")
            Some(Piece(White, King)) -> io.print("♔")
            Some(Piece(Black, Pawn)) -> io.print("♟")
            Some(Piece(Black, Knight)) -> io.print("♞")
            Some(Piece(Black, Bishop)) -> io.print("♝")
            Some(Piece(Black, Rook)) -> io.print("♜")
            Some(Piece(Black, Queen)) -> io.print("♛")
            Some(Piece(Black, King)) -> io.print("♚")
            None -> io.print(" ")
          }
          io.print(" | ")
        },
      )
      io.print("\n")
      io.print("   +---+---+---+---+---+---+---+---+")
      io.print("\n")
    },
  )

  process.send(client, Nil)
  actor.Continue(game_state)
}

pub fn new_server() {
  let white_king_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00001000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
    )

  let white_queen_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00010000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
    )

  let white_rook_bitboard =
    bitboard.Bitboard(
      bitboard: 0b10000001_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
    )

  let white_bishop_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00100100_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
    )

  let white_knight_bitboard =
    bitboard.Bitboard(
      bitboard: 0b01000010_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
    )

  let white_pawn_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00000000_11111111_00000000_00000000_00000000_00000000_00000000_00000000,
    )

  let black_king_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00001000,
    )

  let black_queen_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00010000,
    )

  let black_rook_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_10000001,
    )

  let black_bishop_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00100100,
    )

  let black_knight_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_01000010,
    )

  let black_pawn_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_11111111_00000000,
    )

  let board =
    Board(
      list_of_list_representation: [
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
      ],
      black_king_bitboard: black_king_bitboard,
      black_queen_bitboard: black_queen_bitboard,
      black_rook_bitboard: black_rook_bitboard,
      black_bishop_bitboard: black_bishop_bitboard,
      black_knight_bitboard: black_knight_bitboard,
      black_pawn_bitboard: black_pawn_bitboard,
      white_king_bitboard: white_king_bitboard,
      white_queen_bitboard: white_queen_bitboard,
      white_rook_bitboard: white_rook_bitboard,
      white_bishop_bitboard: white_bishop_bitboard,
      white_knight_bitboard: white_knight_bitboard,
      white_pawn_bitboard: white_pawn_bitboard,
    )

  let turn = Turn(White)

  let history = []

  let status = InProgress

  let ply = 0

  let assert Ok(actor) =
    actor.start(Game(board, turn, history, status, ply), handle_message)
  actor
}
