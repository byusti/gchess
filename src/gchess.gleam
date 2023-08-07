// import gleam/erlang/process
import game

pub fn main() {
  // let game_actor = game.new_server()
  // process.call(game_actor, game.PrintBoard, 100)

  game.print_board_from_fen(
    "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
  )
}
