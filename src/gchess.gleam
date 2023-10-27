import game
import gleam/io
import gleam/list
import move
import position

// import gleam/option.{None}

pub fn main() {
  let game_actor =
    game.new_game_from_fen(
      "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQK2R w KQkq - 0 1",
    )
  game.print_board(game_actor)
  let assert list_of_moves = game.all_legal_moves(game_actor)
  list.each(list_of_moves, fn(move) { io.println(move.to_string(move)) })
  game.apply_move(
    game_actor,
    move.Castle(
      from: position.Position(file: position.E, rank: position.One),
      to: position.Position(file: position.G, rank: position.One),
    ),
  )
  game.print_board(game_actor)
}
