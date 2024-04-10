import game_server.{disable_status, new_game_from_fen, new_server}
import gleam/erlang.{Second, system_time}
import gleam/int
import gleam/io
import gleam/list

pub fn main() {
  let server = new_server()
  new_game_from_fen(
    server,
    "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1",
  )
  disable_status(server)
  let start = system_time(Second)
  let perft_result = perft(server, 3)
  let end = system_time(Second)

  io.print("Perft result: ")
  io.print(int.to_string(perft_result))
  io.print("\n")
  io.print("Time: ")
  io.print(int.to_string(end - start))
  io.print(" seconds")
  io.print("\n")
}

pub fn perft(game_server_subject, depth) {
  case depth {
    0 -> 1
    _ -> {
      let moves = game_server.all_legal_moves(game_server_subject)
      let nodes =
        list.fold(moves, 0, fn(nodes, move) {
          game_server.apply_move_raw(game_server_subject, move)
          let nodes = nodes + perft(game_server_subject, depth - 1)

          game_server.undo_move(game_server_subject)
          nodes
        })
      nodes
    }
  }
}
