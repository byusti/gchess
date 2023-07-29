import gleam/erlang/process
import game

pub fn main() {
  let game_actor = game.new_server()
  process.call(game_actor, game.PrintBoard, 10)
}
