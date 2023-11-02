import game
import gleam/io
import gleam/list
import move

// import gleam/int

pub fn main() {
  let game_actor =
    game.new_game_from_fen(
      "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8",
    )

  game.get_fen(game_actor)
  |> io.println
  // let pawn_g2_to_g4 =
  //   move.Normal(
  //     from: position.Position(file: position.H, rank: position.Two),
  //     to: position.Position(file: position.H, rank: position.Four),
  //     captured: None,
  //     promotion: None,
  //   )

  // let pawn_g7_to_g5 =
  //   move.Normal(
  //     from: position.Position(file: position.F, rank: position.Seven),
  //     to: position.Position(file: position.F, rank: position.Five),
  //     captured: None,
  //     promotion: None,
  //   )
  // game.apply_move(game_actor, pawn_g2_to_g4)
  // game.apply_move(game_actor, pawn_g7_to_g5)
  // game.print_board(game_actor)
  // let moves = game.all_legal_moves(game_actor)
  // list.each(moves, fn(move) { io.println(move.to_string(move)) })

  // game.print_board(game_actor)
  // perft(game_actor, 2)
  // |> int.to_string()
  // |> io.println
}

fn perft(game_actor, depth) {
  case depth {
    0 -> 1
    _ -> {
      let moves = game.all_legal_moves(game_actor)
      let nodes =
        list.fold(
          moves,
          0,
          fn(nodes, move) {
            io.println(move.to_string(move))
            game.apply_move(game_actor, move)
            let nodes = nodes + perft(game_actor, depth - 1)
            game.undo_move(game_actor)
            nodes
          },
        )
      nodes
    }
  }
}
