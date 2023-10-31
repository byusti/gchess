import game
import gleam/io
import gleam/list
import move
import position
import gleam/int
import gleam/option.{None}

pub fn main() {
  let game_actor =
    game.new_game_from_fen(
      "rnbq1k1r/pp1Pbppp/2pP2PP/5R2/2B2R2/8/2P1NnP1/1NBQK3 w - - 1 8",
    )
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
  game.print_board(game_actor)
  perft(game_actor, 2)
  |> int.to_string()
  |> io.println
}

// should the lsp mark this as unused? it doesnt rightnow because we are using perft() recursively
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
            // io.println("applying move")
            io.println(move.to_string(move))
            game.apply_move(game_actor, move)
            // game.print_board(game_actor)
            let nodes = nodes + perft(game_actor, depth - 1)
            // io.println("undoing move")
            // io.println(move.to_string(move))
            game.undo_move(game_actor)
            // game.print_board(game_actor)
            nodes
          },
        )
      nodes
    }
  }
}
