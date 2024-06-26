import color.{type Color}
import game.{type Game}
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option}
import gleam/otp/actor
import gleam/result
import move.{type Move}
import status.{type Status}

pub type Message {
  AllLegalMoves(reply_with: Subject(List(Move)))
  ApplyMove(reply_with: Subject(Result(Game, String)), move: Move)
  ApplyMoveUciString(reply_with: Subject(Result(Game, String)), move: String)
  ApplyMoveSanString(reply_with: Subject(Result(Game, String)), move: String)
  ApplyMoveRaw(reply_with: Subject(Result(Game, String)), move: Move)
  UndoMove(reply_with: Subject(Result(Game, String)))
  GetState(reply_with: Subject(Game))
  GetSideToMove(reply_with: Subject(Color))
  GetFen(reply_with: Subject(String))
  GetStatus(reply_with: Subject(Option(Status)))
  NewGame(reply_with: Subject(Game))
  NewGameFromFen(reply_with: Subject(Result(Game, String)), fen: String)
  DisableStatus(reply_with: Subject(Result(Game, Nil)))
  Shutdown
  PrintBoard(reply_with: Subject(Result(String, String)))
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

pub fn apply_move_uci_string(
  game_actor: Subject(Message),
  move_uci: String,
) -> Result(Game, _) {
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

pub fn shutdown(game_actor: Subject(Message)) {
  process.send(game_actor, Shutdown)
}

fn handle_message(message: Message, game: Game) -> actor.Next(Message, Game) {
  case message {
    AllLegalMoves(client) ->
      case handle_all_legal_moves(game, client) {
        Ok(next) -> next
        Error(_) -> actor.continue(game)
      }
    ApplyMove(client, move) ->
      case handle_apply_move(game, client, move) {
        Ok(next) -> next
        Error(_) -> actor.continue(game)
      }
    ApplyMoveUciString(client, move) ->
      case handle_apply_move_uci(game, client, move) {
        Ok(next) -> next
        Error(_) -> actor.continue(game)
      }
    ApplyMoveSanString(client, move) ->
      case handle_apply_move_san_string(game, client, move) {
        Ok(next) -> next
        Error(_) -> actor.continue(game)
      }
    ApplyMoveRaw(client, move) ->
      case handle_apply_move_raw(game, client, move) {
        Ok(next) -> next
        Error(_) -> actor.continue(game)
      }
    UndoMove(client) ->
      case handle_undo_move(game, client) {
        Ok(next) -> next
        Error(_) -> actor.continue(game)
      }
    GetState(client) -> {
      process.send(client, game)
      actor.continue(game)
    }
    GetFen(client) ->
      case handle_get_fen(game, client) {
        Ok(next) -> next
        Error(_) -> actor.continue(game)
      }
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
      case game.from_fen_string(fen) {
        Ok(new_game) -> {
          process.send(client, Ok(new_game))
          actor.continue(new_game)
        }
        Error(_) -> {
          process.send(client, Error("Failed to create game from fen"))
          actor.continue(game)
        }
      }
    }
    DisableStatus(client) -> {
      let new_game = game.disable_status(game)
      process.send(client, Ok(new_game))
      actor.continue(new_game)
    }
    Shutdown -> actor.Stop(process.Normal)
    PrintBoard(client) -> handle_print_board(game, client)
  }
}

fn handle_all_legal_moves(
  game: Game,
  client: Subject(List(Move)),
) -> Result(actor.Next(Message, Game), _) {
  use all_legal_moves <- result.try(game.all_legal_moves(game))
  process.send(client, all_legal_moves)
  Ok(actor.continue(game))
}

fn handle_undo_move(
  game: Game,
  client: Subject(Result(Game, _)),
) -> Result(actor.Next(Message, Game), _) {
  case game.undo_move(game) {
    Ok(new_game_state) -> {
      process.send(client, Ok(new_game_state))
      Ok(actor.continue(new_game_state))
    }
    Error(_) -> {
      process.send(client, Error("Failed to undo move"))
      Ok(actor.continue(game))
    }
  }
}

fn handle_apply_move_san_string(
  game: Game,
  client: Subject(Result(Game, _)),
  move: String,
) -> Result(actor.Next(Message, Game), _) {
  case game.apply_move_san_string(game, move) {
    Ok(new_game_state) -> {
      process.send(client, Ok(new_game_state))
      Ok(actor.continue(new_game_state))
    }
    Error(_) -> {
      process.send(client, Error("Failed to apply move"))
      Ok(actor.continue(game))
    }
  }
}

fn handle_apply_move_uci(
  game: Game,
  client: Subject(Result(Game, _)),
  move: String,
) -> Result(actor.Next(Message, Game), _) {
  case game.apply_move_uci(game, move) {
    Ok(new_game_state) -> {
      process.send(client, Ok(new_game_state))
      Ok(actor.continue(new_game_state))
    }
    Error(_) -> {
      process.send(client, Error("Failed to apply move"))
      Ok(actor.continue(game))
    }
  }
}

fn handle_apply_move(
  game: Game,
  client: Subject(Result(Game, _)),
  move: Move,
) -> Result(actor.Next(Message, Game), _) {
  case game.apply_move(game, move) {
    Ok(new_game_state) -> {
      process.send(client, Ok(new_game_state))
      Ok(actor.continue(new_game_state))
    }
    Error(_) -> {
      process.send(client, Error("Failed to apply move"))
      Ok(actor.continue(game))
    }
  }
}

fn handle_apply_move_raw(
  game: Game,
  client: Subject(Result(Game, _)),
  move: Move,
) -> Result(actor.Next(Message, Game), _) {
  let new_game_state = game.apply_move_raw(game, move)
  process.send(client, new_game_state)
  Ok(case new_game_state {
    Ok(new_game_state) -> actor.continue(new_game_state)
    Error(_) -> actor.continue(game)
  })
}

fn handle_get_fen(game: Game, client: Subject(String)) {
  process.send(client, game.to_fen(game))
  Ok(actor.continue(game))
}

fn handle_print_board(
  game: Game,
  client: Subject(Result(String, String)),
) -> actor.Next(Message, Game) {
  process.send(client, game.print_board(game))
  actor.continue(game)
}

pub fn new_server() {
  actor.start(game.new_game(), handle_message)
}

pub fn load_pgn(pgn_string: String) {
  case game.load_pgn(pgn_string) {
    Ok(game) -> {
      case actor.start(game, handle_message) {
        Ok(actor) -> Ok(actor)
        Error(_) -> Error("Failed to start actor")
      }
    }
    Error(error) -> Error(error)
  }
}
