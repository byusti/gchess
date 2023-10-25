import game
import gleam/erlang/process
import gleam/io
import gleam/list
import move
import position
import gleam/option.{None}

pub fn main() {
  let game_actor =
    game.new_game_from_fen(
      "rn1qkbnr/pppppppp/8/8/8/6b1/PPPPP1P1/RNBQKBNR w KQkq - 0 1",
    )
  process.call(game_actor, game.PrintBoard, 100)
  let assert list_of_moves = process.call(game_actor, game.AllLegalMoves, 100)
  list.each(list_of_moves, fn(move) { io.println(move.to_string(move)) })
  // process.call(
  //   game_actor,
  //   game.ApplyMove(_, move: move.Normal(
  //     from: position.Position(file: position.F, rank: position.Two),
  //     to: position.Position(file: position.F, rank: position.Three),
  //     captured: None,
  //     promotion: None,
  //   )),
  //   100,
  // )
  // process.call(game_actor, game.PrintBoard, 100)
}
