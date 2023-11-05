import gleeunit
import gleeunit/should
import game_server
import gleam/option.{Some}
import status.{Draw, InProgress, ThreefoldRepetition}

pub fn main() {
  gleeunit.main()
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
