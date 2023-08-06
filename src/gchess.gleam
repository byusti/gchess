import gleam/erlang/process
import game

pub fn main() {
  let game_actor = game.new_server()
  process.call(
    game_actor,
    game.PrintBoardFromFen(
      _,
      "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
    ),
    100,
  )
}
