import game
import game_server
import gleam/list

pub fn perft(game, depth) {
  case depth {
    0 -> 1
    _ -> {
      let moves = game.all_legal_moves(game)
      let nodes =
        list.fold(
          moves,
          0,
          fn(nodes, move) {
            let new_game = game.apply_move(game, move)
            let nodes = nodes + perft(new_game, depth - 1)
            nodes
          },
        )
      nodes
    }
  }
}

pub fn perft_server(game_server_subject, depth) {
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
            let nodes = nodes + perft_server(game_server_subject, depth - 1)
            game_server.undo_move(game_server_subject)
            nodes
          },
        )
      nodes
    }
  }
}
