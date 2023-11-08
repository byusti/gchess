import gleam/otp/actor
import gleam/erlang/process.{type Subject}
import move.{type Move}
import gleam/option.{type Option}
import game.{type Game}
import status.{type Status}

pub type Message {
  AllLegalMoves(reply_with: Subject(List(Move)))
  ApplyMove(reply_with: Subject(Game), move: Move)
  ApplyMoveUCI(reply_with: Subject(Game), move: String)
  ApplyMoveSanString(reply_with: Subject(Game), move: String)
  UndoMove(reply_with: Subject(Game))
  GetFen(reply_with: Subject(String))
  GetStatus(reply_with: Subject(Option(Status)))
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

pub fn get_status(game_actor: Subject(Message)) {
  process.call(game_actor, GetStatus, 1000)
}

fn handle_message(message: Message, game: Game) -> actor.Next(Message, Game) {
  case message {
    AllLegalMoves(client) -> handle_all_legal_moves(game, client)
    ApplyMove(client, move) -> handle_apply_move(game, client, move)
    ApplyMoveUCI(client, move) -> handle_apply_move_uci(game, client, move)
    ApplyMoveSanString(client, move) ->
      handle_apply_move_san_string(game, client, move)
    UndoMove(client) -> handle_undo_move(game, client)
    GetFen(client) -> handle_get_fen(game, client)
    GetStatus(client) -> {
      process.send(client, game.status)
      actor.continue(game)
    }
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

fn handle_apply_move_san_string(game: Game, client: Subject(Game), move: String) {
  let assert Ok(new_game_state) = game.apply_move_san_string(game, move)
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
  let assert Ok(actor) =
    actor.start(game.from_fen_string(fen_string), handle_message)
  actor
}

pub fn new_game() {
  let assert Ok(actor) = actor.start(game.new_game(), handle_message)
  actor
}

pub fn load_pgn(pgn_string: String) {
  case game.load_pgn(pgn_string) {
    Ok(game) -> {
      let assert Ok(actor) = actor.start(game, handle_message)
      Ok(actor)
    }
    Error(error) -> Error(error)
  }
}
