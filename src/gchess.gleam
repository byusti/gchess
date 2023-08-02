import gleam/erlang/process
import game

pub fn main() {
  let game_actor = game.new_server()
  process.send(
    game_actor,
    game.PrintBoardFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR"),
  )
}
