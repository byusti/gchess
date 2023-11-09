import gleam/list
import game_server

// pub fn main() {
//   let server = new_server()
//   new_game_from_fen(
//     server,
//     "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8",
//   )
//   disable_status(server)
//   io.println(int.to_string(perft(server, 2)))
// }

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
