import game_server
import gleam/io
import gleam/list
import move

pub fn main() {
  // When we start the gamer server process, we receive a "subject" which allows
  // us to send messages to the process, similar to how we need a PID in erlang/elixir
  // to send messages to a specific process.
  let game_server_subject =
    game_server.from_fen(
      "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
    )

  game_server.print_board(game_server_subject)

  game_server.all_legal_moves(game_server_subject)
  |> list.map(move.to_string)
  |> list.each(io.println)

  game_server.apply_move_uci(game_server_subject, "e2e4")

  game_server.print_board(game_server_subject)
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
