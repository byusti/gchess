// import gleam/erlang/process
import game
import gleam/erlang/process
import gleam/io
import gleam/list
import move

pub fn main() {
  let game_actor = game.new_server()
  process.call(game_actor, game.PrintBoard, 100)
  let assert list_of_moves = process.call(game_actor, game.AllLegalMoves, 100)
  list.each(list_of_moves, fn(move) { io.println(move.to_string(move)) })
  // game.print_board_from_fen(
  //   "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
  // )
}
