import color.{type Color}
import game.{type Game}
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option}
import gleam/otp/actor
import move.{type Move}
import status.{type Status}

pub type Message {
  AllLegalMoves(reply_with: Subject(List(Move)))
  ApplyMove(reply_with: Subject(Game), move: Move)
  ApplyMoveUciString(reply_with: Subject(Game), move: String)
  ApplyMoveSanString(reply_with: Subject(Game), move: String)
  ApplyMoveRaw(reply_with: Subject(Game), move: Move)
  UndoMove(reply_with: Subject(Game))
  GetState(reply_with: Subject(Game))
  GetSideToMove(reply_with: Subject(Color))
  GetFen(reply_with: Subject(String))
  GetStatus(reply_with: Subject(Option(Status)))
  NewGame(reply_with: Subject(Game))
  NewGameFromFen(reply_with: Subject(Game), fen: String)
  DisableStatus(reply_with: Subject(Game))
  Shutdown
  PrintBoard(reply_with: Subject(Nil))
}

// TODO: This module contains all functions related to interacting
// with erlang processes. It keeps the library from being compiled
// to javascript. At some point in the future, I would like to 
// address this issue so that the library can target js.

pub fn print_board(game_actor: Subject(Message)) {
  process.call(game_actor, PrintBoard, 1000)
}

pub fn apply_move(game_actor: Subject(Message), move: Move) {
  process.call(game_actor, ApplyMove(_, move), 1000)
}

pub fn apply_move_uci_string(game_actor: Subject(Message), move_uci: String) {
  process.call(game_actor, ApplyMoveUciString(_, move_uci), 1000)
}

pub fn apply_move_san_string(game_actor: Subject(Message), move_san: String) {
  process.call(game_actor, ApplyMoveSanString(_, move_san), 1000)
}

pub fn apply_move_raw(game_actor: Subject(Message), move: Move) {
  process.call(game_actor, ApplyMoveRaw(_, move), 1000)
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

pub fn disable_status(game_actor: Subject(Message)) {
  process.call(game_actor, DisableStatus, 1000)
}

pub fn new_game(game_actor: Subject(Message)) {
  process.call(game_actor, NewGame, 1000)
}

pub fn new_game_from_fen(game_actor: Subject(Message), fen: String) {
  process.call(game_actor, NewGameFromFen(_, fen), 1000)
}

fn handle_message(message: Message, game: Game) -> actor.Next(Message, Game) {
  case message {
    AllLegalMoves(client) -> handle_all_legal_moves(game, client)
    ApplyMove(client, move) -> handle_apply_move(game, client, move)
    ApplyMoveUciString(client, move) ->
      handle_apply_move_uci(game, client, move)
    ApplyMoveSanString(client, move) ->
      handle_apply_move_san_string(game, client, move)
    ApplyMoveRaw(client, move) -> handle_apply_move_raw(game, client, move)
    UndoMove(client) -> handle_undo_move(game, client)
    GetState(client) -> {
      process.send(client, game)
      actor.continue(game)
    }
    GetFen(client) -> handle_get_fen(game, client)
    GetStatus(client) -> {
      process.send(client, game.status)
      actor.continue(game)
    }
    GetSideToMove(client) -> {
      process.send(client, game.turn)
      actor.continue(game)
    }
    NewGame(client) -> {
      let new_game = game.new_game()
      process.send(client, new_game)
      actor.continue(new_game)
    }
    NewGameFromFen(client, fen) -> {
      let new_game = game.from_fen_string(fen)
      process.send(client, new_game)
      actor.continue(new_game)
    }
    DisableStatus(client) -> {
      let new_game = game.disable_status(game)
      process.send(client, new_game)
      actor.continue(new_game)
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

fn handle_apply_move_raw(game: Game, client: Subject(Game), move: Move) {
  let new_game_state = game.apply_move_raw(game, move)
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

pub fn new_server() {
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
