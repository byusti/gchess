import game
import gleam/erlang/process
import gleam/io
import gleam/list
import move

pub fn main() {
  let game_actor =
    game.new_game_from_fen(
      "rnbqkbnr/ppppppPp/8/8/8/8/PPPPPP1P/RNBQKBNR w KQkq - 0 1",
    )
  process.call(game_actor, game.PrintBoard, 100)
  let assert list_of_moves = process.call(game_actor, game.AllLegalMoves, 100)
  list.each(list_of_moves, fn(move) { io.println(move.to_string(move)) })
}
