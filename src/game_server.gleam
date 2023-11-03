import gleam/otp/actor
import gleam/erlang/process.{type Subject}
import move.{type Move}
import game.{type Game, InProgress}
import fen
import color.{Black, White}
import castle_rights.{No, Yes}
import gleam/option.{None, Some}
import bitboard
import board

pub type Message {
  AllLegalMoves(reply_with: Subject(List(Move)))
  ApplyMove(reply_with: Subject(Game), move: Move)
  ApplyMoveUCI(reply_with: Subject(Game), move: String)
  UndoMove(reply_with: Subject(Game))
  GetFen(reply_with: Subject(String))
  Shutdown
  PrintBoard(reply_with: Subject(Nil))
}

pub fn print_board(game_actor: Subject(Message)) {
  process.call(game_actor, PrintBoard, 1000)
}

pub fn apply_move(game_actor: Subject(Message), move: Move) {
  process.call(game_actor, ApplyMove(_, move), 1000)
}

pub fn apply_move_uci(game_actor: Subject(Message), move_uci: String) {
  process.call(game_actor, ApplyMoveUCI(_, move_uci), 1000)
}

pub fn undo_move(game_actor: Subject(Message)) {
  process.call(game_actor, UndoMove, 1000)
}

pub fn all_legal_moves(game_actor: Subject(Message)) {
  process.call(game_actor, AllLegalMoves, 1000)
}

pub fn get_fen(game_actor: Subject(Message)) {
  process.call(game_actor, GetFen, 1000)
}

fn handle_message(message: Message, game: Game) -> actor.Next(Message, Game) {
  case message {
    AllLegalMoves(client) -> handle_all_legal_moves(game, client)
    ApplyMove(client, move) -> handle_apply_move(game, client, move)
    ApplyMoveUCI(client, move) -> handle_apply_move_uci(game, client, move)
    UndoMove(client) -> handle_undo_move(game, client)
    GetFen(client) -> handle_get_fen(game, client)
    Shutdown -> actor.Stop(process.Normal)
    PrintBoard(client) -> handle_print_board(game, client)
  }
}

fn handle_all_legal_moves(
  game: Game,
  client: Subject(List(Move)),
) -> actor.Next(Message, Game) {
  process.send(client, game.all_legal_moves(game))
  actor.continue(game)
}

fn handle_undo_move(game: Game, client: Subject(Game)) {
  let new_game_state = game.undo_move(game)

  process.send(client, new_game_state)
  actor.continue(new_game_state)
}

fn handle_apply_move_uci(game: Game, client: Subject(Game), move: String) {
  let new_game_state = game.apply_move_uci(game, move)
  process.send(client, new_game_state)
  actor.continue(new_game_state)
}

fn handle_apply_move(game: Game, client: Subject(Game), move: Move) {
  let new_game_state = game.apply_move(game, move)
  process.send(client, new_game_state)
  actor.continue(new_game_state)
}

fn handle_get_fen(game: Game, client: Subject(String)) {
  process.send(client, game.to_fen(game))
  actor.continue(game)
}

fn handle_print_board(
  game: Game,
  client: Subject(Nil),
) -> actor.Next(Message, Game) {
  game.print_board(game)

  process.send(client, Nil)
  actor.continue(game)
}

pub fn from_fen(fen_string: String) {
  let fen = fen.from_string(fen_string)

  let status = InProgress

  let ply = case fen.turn {
    White -> {
      { fen.fullmove - 1 } * 2
    }
    Black -> {
      { fen.fullmove - 1 } * 2 + 1
    }
  }

  let white_kingside_castle = case fen.castling.white_kingside {
    True -> Yes
    False -> No(1)
  }

  let white_queenside_castle = case fen.castling.white_queenside {
    True -> Yes
    False -> No(1)
  }

  let black_kingside_castle = case fen.castling.black_kingside {
    True -> Yes
    False -> No(2)
  }

  let black_queenside_castle = case fen.castling.black_queenside {
    True -> Yes
    False -> No(2)
  }

  let game =
    game.Game(
      board: fen.board,
      turn: fen.turn,
      history: [],
      status: Some(status),
      fifty_move_rule: fen.halfmove,
      ply: ply,
      white_kingside_castle: white_kingside_castle,
      white_queenside_castle: white_queenside_castle,
      black_kingside_castle: black_kingside_castle,
      black_queenside_castle: black_queenside_castle,
      en_passant: fen.en_passant,
    )
  let assert Ok(actor) = actor.start(game, handle_message)
  actor
}

pub fn new_game() {
  let white_king_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00001000,
    )

  let white_queen_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00010000,
    )

  let white_rook_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_10000001,
    )

  let white_bishop_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00100100,
    )

  let white_knight_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_01000010,
    )

  let white_pawns_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_11111111_00000000,
    )

  let black_king_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00001000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
    )

  let black_queen_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00010000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
    )

  let black_rook_bitboard =
    bitboard.Bitboard(
      bitboard: 0b10000001_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
    )

  let black_bishop_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00100100_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
    )

  let black_knight_bitboard =
    bitboard.Bitboard(
      bitboard: 0b01000010_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
    )

  let black_pawns_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00000000_11111111_00000000_00000000_00000000_00000000_00000000_00000000,
    )

  let board =
    board.BoardBB(
      black_king_bitboard: black_king_bitboard,
      black_queen_bitboard: black_queen_bitboard,
      black_rook_bitboard: black_rook_bitboard,
      black_bishop_bitboard: black_bishop_bitboard,
      black_knight_bitboard: black_knight_bitboard,
      black_pawns_bitboard: black_pawns_bitboard,
      white_king_bitboard: white_king_bitboard,
      white_queen_bitboard: white_queen_bitboard,
      white_rook_bitboard: white_rook_bitboard,
      white_bishop_bitboard: white_bishop_bitboard,
      white_knight_bitboard: white_knight_bitboard,
      white_pawns_bitboard: white_pawns_bitboard,
    )

  let turn = White

  let history = []

  let status = InProgress

  let ply = 0

  let assert Ok(actor) =
    actor.start(
      game.Game(
        board: board,
        turn: turn,
        history: history,
        status: Some(status),
        fifty_move_rule: 0,
        ply: ply,
        white_kingside_castle: Yes,
        white_queenside_castle: Yes,
        black_kingside_castle: Yes,
        black_queenside_castle: Yes,
        en_passant: None,
      ),
      handle_message,
    )
  actor
}
