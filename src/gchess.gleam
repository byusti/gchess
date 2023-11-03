import game_server
import gleam/io
import gleam/list
import move

pub fn main() {
  let game_actor =
    game_server.from_fen(
      "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
    )

  game_server.print_board(game_actor)

  game_server.all_legal_moves(game_actor)
  |> list.map(move.to_string)
  |> list.each(io.println)

  game_server.apply_move_uci(game_actor, "e2e4")

  game_server.print_board(game_actor)
}

fn perft(game_actor, depth) {
  case depth {
    0 -> 1
    _ -> {
      let moves = game_server.all_legal_moves(game_actor)
      let nodes =
        list.fold(
          moves,
          0,
          fn(nodes, move) {
            io.println(move.to_string(move))
            game_server.apply_move(game_actor, move)
            let nodes = nodes + perft(game_actor, depth - 1)
            game_server.undo_move(game_actor)
            nodes
          },
        )
      nodes
    }
  }
}
