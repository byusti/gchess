import game
import gleam/io
import gleam/list
import move
import position
import gleam/int
import gleam/option.{None}

pub fn main() {
  let game_actor = game.new_game()
  // let pawn_g2_to_g4 =
  //   move.Normal(
  //     from: position.Position(file: position.G, rank: position.Two),
  //     to: position.Position(file: position.G, rank: position.Four),
  //     captured: None,
  //     promotion: None,
  //   )

  // let pawn_g7_to_g5 =
  //   move.Normal(
  //     from: position.Position(file: position.G, rank: position.Seven),
  //     to: position.Position(file: position.G, rank: position.Five),
  //     captured: None,
  //     promotion: None,
  //   )

  // let pawn_f2_to_f4 =
  //   move.Normal(
  //     from: position.Position(file: position.F, rank: position.Two),
  //     to: position.Position(file: position.F, rank: position.Four),
  //     captured: None,
  //     promotion: None,
  //   )

  // let pawn_f7_to_f6 =
  //   move.Normal(
  //     from: position.Position(file: position.F, rank: position.Seven),
  //     to: position.Position(file: position.F, rank: position.Six),
  //     captured: None,
  //     promotion: None,
  //   )

  // let pawn_f4_to_f5 =
  //   move.Normal(
  //     from: position.Position(file: position.F, rank: position.Four),
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
  perft(game_actor, 3)
  |> int.to_string()
  |> io.println
}

fn perft(game_actor, depth) {
  case depth {
    0 -> 1
    _ -> {
      let moves = game.all_legal_moves(game_actor)
      let seed = 0
      let nodes =
        list.fold(
          moves,
          0,
          fn(nodes, move) {
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
