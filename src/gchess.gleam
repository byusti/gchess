import game_server
import game
import gleam/io
import gleam/list
import move
import gleam/int

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

  int.to_string(perft(
    game.from_fen_string(
      "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8",
    ),
    1,
  ))
  |> io.println()
}

fn perft(game, depth) {
  case depth {
    0 -> 1
    _ -> {
      let moves = game.all_legal_moves(game)
      let nodes =
        list.fold(
          moves,
          0,
          fn(nodes, move) {
            io.println(move.to_string(move))
            let new_game = game.apply_move(game, move)
            let nodes = nodes + perft(new_game, depth - 1)
            nodes
          },
        )
      nodes
    }
  }
}
