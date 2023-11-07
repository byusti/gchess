import gleeunit
import gleeunit/should
import game_server
import pgn
import piece
import move_san
import position
import gleam/option.{None, Some}
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

pub fn split_movetext_test() {
  let pgn = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6"
  let moves = pgn.split_movetext(pgn)
  moves
  |> should.equal(["1. e4 e5", "2. Nf3 Nc6", "3. Bb5 a6", "4. Ba4 Nf6"])
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
