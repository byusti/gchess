import game_server
import gleam/list

pub fn perft(game_server_subject, depth) {
  case depth {
    0 -> 1
    _ -> {
      let moves = game_server.all_legal_moves(game_server_subject)
      let nodes =
        list.fold(
          moves,
          0,
          fn(nodes, move) {
            game_server.apply_move(game_server_subject, move)
            let nodes = nodes + perft(game_server_subject, depth - 1)
            game_server.undo_move(game_server_subject)
            nodes
          },
        )
      nodes
    }
  }
}
