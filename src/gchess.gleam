import game_server
import gleam/io
import gleam/list
import move

pub fn main() {
  let game_actor =
    game_server.from_fen(
      "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8",
    )

  game_server.all_legal_moves(game_actor)
  |> list.map(move.to_string)
  |> list.each(io.println)
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
