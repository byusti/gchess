import gleeunit
import gleeunit/should
import game_server
import game
import pgn
import piece
import move_san
import position
import gleam/option.{None, Some}
import gleam/map.{type Map}
import status.{Draw, InProgress, ThreefoldRepetition}

pub fn main() {
  gleeunit.main()
}

pub fn move_san_from_string_test() {
  let assert Ok(move) = move_san.from_string("e4")

  move
  |> should.equal(move_san.Normal(
    moving_piece: piece.Pawn,
    from: None,
    to: position.Position(file: position.E, rank: position.Four),
    capture: False,
    promotion: None,
    maybe_check_or_checkmate: None,
  ))

  let assert Ok(move) = move_san.from_string("R1a3")

  move
  |> should.equal(move_san.Normal(
    moving_piece: piece.Rook,
    from: Some(move_san.PositionSan(file: None, rank: Some(position.One))),
    to: position.Position(file: position.A, rank: position.Three),
    capture: False,
    promotion: None,
    maybe_check_or_checkmate: None,
  ))

  let assert Ok(move) = move_san.from_string("Rxa3")
  move
  |> should.equal(move_san.Normal(
    moving_piece: piece.Rook,
    from: None,
    to: position.Position(file: position.A, rank: position.Three),
    capture: True,
    promotion: None,
    maybe_check_or_checkmate: None,
  ))

  let assert Ok(move) = move_san.from_string("Qh4e1")
  move
  |> should.equal(move_san.Normal(
    moving_piece: piece.Queen,
    from: Some(move_san.PositionSan(
      file: Some(position.H),
      rank: Some(position.Four),
    )),
    to: position.Position(file: position.E, rank: position.One),
    capture: False,
    promotion: None,
    maybe_check_or_checkmate: None,
  ))

  let assert Ok(move) = move_san.from_string("0-0")
  move
  |> should.equal(move_san.Castle(
    side: move_san.KingSide,
    maybe_check_or_checkmate: None,
  ))

  let assert Ok(move) = move_san.from_string("0-0-0")
  move
  |> should.equal(move_san.Castle(
    side: move_san.QueenSide,
    maybe_check_or_checkmate: None,
  ))
}

pub fn load_pgn_into_game_test() {
  let pgn = "1. e4 e5 2. Bd3 Bd6 3. Nf3 Nf6 4. O-O"
  let assert Ok(game) = pgn.load_pgn(pgn)
  game.print_board(game.new_game())
  case game.status {
    Some(InProgress(fifty_move_rule: 5, threefold_repetition_rule: _)) -> True
    _ -> False
  }
  |> should.equal(True)
}

pub fn split_movetext_test() {
  let pgn = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O"
  let moves = pgn.split_movetext(pgn)
  moves
  |> should.equal(["e4 e5", "Nf3 Nc6", "Bb5 a6", "Ba4 Nf6", "O-O"])
}

pub fn threefold_repetition_rule_test() {
  let server = game_server.new_game()

  game_server.apply_move_uci(server, "e2e4")
  game_server.apply_move_uci(server, "e7e5")

  game_server.apply_move_uci(server, "f1e2")
  game_server.apply_move_uci(server, "f8e7")
  game_server.apply_move_uci(server, "e2f1")
  game_server.apply_move_uci(server, "e7f8")
  game_server.print_board(server)
  case game_server.get_status(server) {
    Some(InProgress(_, _)) -> True
    _ -> False
  }
  |> should.equal(True)

  game_server.apply_move_uci(server, "f1e2")
  game_server.apply_move_uci(server, "f8e7")
  game_server.apply_move_uci(server, "e2f1")
  game_server.apply_move_uci(server, "e7f8")
  game_server.print_board(server)
  case game_server.get_status(server) {
    Some(InProgress(_, _)) -> True
    _ -> False
  }
  |> should.equal(True)

  game_server.apply_move_uci(server, "f1e2")
  game_server.apply_move_uci(server, "f8e7")
  game_server.apply_move_uci(server, "e2f1")
  game_server.apply_move_uci(server, "e7f8")
  game_server.print_board(server)
  game_server.get_status(server)
  |> should.equal(Some(Draw(ThreefoldRepetition)))
}
