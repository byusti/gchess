import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/option.{None, Option, Some}
import gleam/io
import gleam/list
import gleam/int
import gleam/map
import gleam/result
import bitboard.{Bitboard}
import piece.{Bishop, King, Knight, Pawn, Piece, Queen, Rook}
import color.{Black, Color, White}
import position.{Position}
import board.{BoardMap}
import boardbb.{BoardBB}
import move.{Move}
import fen

pub type Turn {
  Turn(color: Color)
}

pub type Status {
  Checkmate
  Stalemate
  InProgress
}

pub type Game {
  Game(
    board: BoardBB,
    turn: Turn,
    history: List(Move),
    status: Status,
    ply: Int,
  )
}

pub type Message {
  AllLegalMoves(reply_with: Subject(List(Move)))
  Shutdown
  PrintBoard(reply_with: Subject(Nil))
}

// Hard coded list of all positions in traversal order
const positions_in_traversal_order = [
  Position(file: position.A, rank: position.Eight),
  Position(file: position.B, rank: position.Eight),
  Position(file: position.C, rank: position.Eight),
  Position(file: position.D, rank: position.Eight),
  Position(file: position.E, rank: position.Eight),
  Position(file: position.F, rank: position.Eight),
  Position(file: position.G, rank: position.Eight),
  Position(file: position.H, rank: position.Eight),
  Position(file: position.A, rank: position.Seven),
  Position(file: position.B, rank: position.Seven),
  Position(file: position.C, rank: position.Seven),
  Position(file: position.D, rank: position.Seven),
  Position(file: position.E, rank: position.Seven),
  Position(file: position.F, rank: position.Seven),
  Position(file: position.G, rank: position.Seven),
  Position(file: position.H, rank: position.Seven),
  Position(file: position.A, rank: position.Six),
  Position(file: position.B, rank: position.Six),
  Position(file: position.C, rank: position.Six),
  Position(file: position.D, rank: position.Six),
  Position(file: position.E, rank: position.Six),
  Position(file: position.F, rank: position.Six),
  Position(file: position.G, rank: position.Six),
  Position(file: position.H, rank: position.Six),
  Position(file: position.A, rank: position.Five),
  Position(file: position.B, rank: position.Five),
  Position(file: position.C, rank: position.Five),
  Position(file: position.D, rank: position.Five),
  Position(file: position.E, rank: position.Five),
  Position(file: position.F, rank: position.Five),
  Position(file: position.G, rank: position.Five),
  Position(file: position.H, rank: position.Five),
  Position(file: position.A, rank: position.Four),
  Position(file: position.B, rank: position.Four),
  Position(file: position.C, rank: position.Four),
  Position(file: position.D, rank: position.Four),
  Position(file: position.E, rank: position.Four),
  Position(file: position.F, rank: position.Four),
  Position(file: position.G, rank: position.Four),
  Position(file: position.H, rank: position.Four),
  Position(file: position.A, rank: position.Three),
  Position(file: position.B, rank: position.Three),
  Position(file: position.C, rank: position.Three),
  Position(file: position.D, rank: position.Three),
  Position(file: position.E, rank: position.Three),
  Position(file: position.F, rank: position.Three),
  Position(file: position.G, rank: position.Three),
  Position(file: position.H, rank: position.Three),
  Position(file: position.A, rank: position.Two),
  Position(file: position.B, rank: position.Two),
  Position(file: position.C, rank: position.Two),
  Position(file: position.D, rank: position.Two),
  Position(file: position.E, rank: position.Two),
  Position(file: position.F, rank: position.Two),
  Position(file: position.G, rank: position.Two),
  Position(file: position.H, rank: position.Two),
  Position(file: position.A, rank: position.One),
  Position(file: position.B, rank: position.One),
  Position(file: position.C, rank: position.One),
  Position(file: position.D, rank: position.One),
  Position(file: position.E, rank: position.One),
  Position(file: position.F, rank: position.One),
  Position(file: position.G, rank: position.One),
  Position(file: position.H, rank: position.One),
]

fn handle_message(
  message: Message,
  game_state: Game,
) -> actor.Next(Message, Game) {
  case message {
    AllLegalMoves(client) -> handle_all_legal_moves(game_state, client)
    Shutdown -> actor.Stop(process.Normal)
    PrintBoard(client) -> handle_print_board(game_state, client)
  }
}

fn handle_all_legal_moves(
  game_state: Game,
  client: Subject(List(Move)),
) -> actor.Next(Message, Game) {
  let legal_moves = generate_move_list(game_state, game_state.turn.color)
  process.send(client, legal_moves)
  actor.continue(game_state)
}

const not_a_file = bitboard.Bitboard(
  bitboard: 0b01111111_01111111_01111111_01111111_01111111_01111111_01111111_01111111,
)

const not_h_file = bitboard.Bitboard(
  bitboard: 0b11111110_11111110_11111110_11111110_11111110_11111110_11111110_11111110,
)

fn generate_move_list(game_state: Game, color: Color) -> List(Move) {
  generate_pawn_move_list(color, game_state)
}

fn generate_pawn_move_list(color: Color, game_state: Game) -> List(Move) {
  let capture_list = generate_pawn_capture_move_list(color, game_state)
  let moves_no_captures =
    generate_pawn_non_capture_move_bitboard(color, game_state)

  let non_capture_dest_list = bitboard.get_positions(moves_no_captures)

  let non_capture_move_list =
    list.map(
      non_capture_dest_list,
      fn(dest) -> Move {
        let origin = position.get_rear_position(dest, color)
        Move(from: origin, to: dest)
      },
    )
  list.append(capture_list, non_capture_move_list)
}

fn generate_pawn_non_capture_move_bitboard(
  color: Color,
  game_state: Game,
) -> bitboard.Bitboard {
  case color {
    White -> {
      let white_pawn_target_squares =
        bitboard.shift_left(game_state.board.white_pawns_bitboard, 8)
      let list_of_enemy_piece_bitboards = [
        game_state.board.black_king_bitboard,
        game_state.board.black_queen_bitboard,
        game_state.board.black_rook_bitboard,
        game_state.board.black_bishop_bitboard,
        game_state.board.black_knight_bitboard,
        game_state.board.black_pawns_bitboard,
      ]
      let enemy_pieces =
        list.fold(
          list_of_enemy_piece_bitboards,
          bitboard.Bitboard(bitboard: 0),
          fn(collector, next) -> Bitboard { bitboard.or(collector, next) },
        )
      let moves = bitboard.exclusive_or(white_pawn_target_squares, enemy_pieces)
      let moves = bitboard.and(moves, white_pawn_target_squares)
      moves
    }

    Black -> {
      let black_pawn_target_squares =
        bitboard.shift_right(game_state.board.black_pawns_bitboard, 8)
      let list_of_enemy_piece_bitboards = [
        game_state.board.white_king_bitboard,
        game_state.board.white_queen_bitboard,
        game_state.board.white_rook_bitboard,
        game_state.board.white_bishop_bitboard,
        game_state.board.white_knight_bitboard,
        game_state.board.white_pawns_bitboard,
      ]
      let enemy_pieces =
        list.fold(
          list_of_enemy_piece_bitboards,
          bitboard.Bitboard(bitboard: 0),
          fn(collector, next) { bitboard.or(collector, next) },
        )
      let moves = bitboard.exclusive_or(black_pawn_target_squares, enemy_pieces)
      let moves = bitboard.and(moves, black_pawn_target_squares)
      moves
    }
  }
}

fn generate_pawn_capture_move_list(color: Color, game_state: Game) -> List(Move) {
  let pawn_attack_set =
    generate_pawn_attack_set(game_state.board.white_pawns_bitboard, color)
  let list_of_enemy_piece_bitboards = [
    game_state.board.black_king_bitboard,
    game_state.board.black_queen_bitboard,
    game_state.board.black_rook_bitboard,
    game_state.board.black_bishop_bitboard,
    game_state.board.black_knight_bitboard,
    game_state.board.black_pawns_bitboard,
  ]
  let enemy_pieces =
    list.fold(
      list_of_enemy_piece_bitboards,
      bitboard.Bitboard(bitboard: 0),
      fn(collector, next) { bitboard.and(collector, next) },
    )
  let pawn_capture_destination_set = bitboard.and(pawn_attack_set, enemy_pieces)

  let [east_origins, west_origins] = case color {
    White -> {
      let east_origins =
        bitboard.and(
          bitboard.shift_right(pawn_capture_destination_set, 9),
          not_a_file,
        )
      let west_origins =
        bitboard.and(
          bitboard.shift_right(pawn_capture_destination_set, 7),
          not_h_file,
        )
      [east_origins, west_origins]
    }
    Black -> {
      let east_origins =
        bitboard.and(
          bitboard.shift_left(pawn_capture_destination_set, 9),
          not_a_file,
        )
      let west_origins =
        bitboard.and(
          bitboard.shift_left(pawn_capture_destination_set, 7),
          not_h_file,
        )
      [east_origins, west_origins]
    }
  }

  let pawn_capture_origin_set = bitboard.and(east_origins, west_origins)

  let pawn_capture_origin_list = bitboard.get_positions(pawn_capture_origin_set)

  let pawn_capture_destination_list =
    bitboard.get_positions(pawn_capture_destination_set)

  // we need to go through the list of origins and for each origin
  // if one or both of its attack squares are in the destination list,
  // then we combine the origin and dest into a move and add that move to the list of moves
  let pawn_capture_move_list =
    list.fold(
      pawn_capture_origin_list,
      [],
      fn(collector, position) -> List(Move) {
        let east_attack = position.get_position(position, 1, 1)
        let west_attack = position.get_position(position, 1, -1)
        let east_attack_in_dest_list =
          list.contains(pawn_capture_destination_list, east_attack)
        let west_attack_in_dest_list =
          list.contains(pawn_capture_destination_list, west_attack)
        let moves = case [east_attack_in_dest_list, west_attack_in_dest_list] {
          [True, True] -> [
            Move(from: position, to: east_attack),
            Move(from: position, to: west_attack),
          ]
          [True, False] -> [Move(from: position, to: east_attack)]
          [False, True] -> [Move(from: position, to: west_attack)]
          [False, False] -> []
        }
        list.append(collector, moves)
      },
    )
  pawn_capture_move_list
}

fn generate_pawn_attack_set(pawn_bitboard: bitboard.Bitboard, color: Color) {
  case color {
    White -> {
      let east_attack =
        bitboard.and(bitboard.shift_right(pawn_bitboard, 9), not_a_file)
      let west_attack =
        bitboard.and(bitboard.shift_right(pawn_bitboard, 7), not_h_file)
      let all_attacks = bitboard.and(east_attack, west_attack)
      all_attacks
    }
    Black -> {
      let east_attack =
        bitboard.and(bitboard.shift_left(pawn_bitboard, 7), not_a_file)
      let west_attack =
        bitboard.and(bitboard.shift_left(pawn_bitboard, 9), not_h_file)
      let all_attacks = bitboard.and(east_attack, west_attack)
      all_attacks
    }
  }
}

fn bitboard_repr_to_map_repr(board: BoardBB) -> BoardMap {
  let white_king_bitboard = board.white_king_bitboard
  let white_queen_bitboard = board.white_queen_bitboard
  let white_rook_bitboard = board.white_rook_bitboard
  let white_bishop_bitboard = board.white_bishop_bitboard
  let white_knight_bitboard = board.white_knight_bitboard
  let white_pawns_bitboard = board.white_pawns_bitboard
  let black_king_bitboard = board.black_king_bitboard
  let black_queen_bitboard = board.black_queen_bitboard
  let black_rook_bitboard = board.black_rook_bitboard
  let black_bishop_bitboard = board.black_bishop_bitboard
  let black_knight_bitboard = board.black_knight_bitboard
  let black_pawns_bitboard = board.black_pawns_bitboard

  let board_map: map.Map(Position, Option(Piece)) =
    map.from_list([
      #(Position(file: position.A, rank: position.One), None),
      #(Position(file: position.B, rank: position.One), None),
      #(Position(file: position.C, rank: position.One), None),
      #(Position(file: position.D, rank: position.One), None),
      #(Position(file: position.E, rank: position.One), None),
      #(Position(file: position.F, rank: position.One), None),
      #(Position(file: position.G, rank: position.One), None),
      #(Position(file: position.H, rank: position.One), None),
      #(Position(file: position.A, rank: position.Two), None),
      #(Position(file: position.B, rank: position.Two), None),
      #(Position(file: position.C, rank: position.Two), None),
      #(Position(file: position.D, rank: position.Two), None),
      #(Position(file: position.E, rank: position.Two), None),
      #(Position(file: position.F, rank: position.Two), None),
      #(Position(file: position.G, rank: position.Two), None),
      #(Position(file: position.H, rank: position.Two), None),
      #(Position(file: position.A, rank: position.Three), None),
      #(Position(file: position.B, rank: position.Three), None),
      #(Position(file: position.C, rank: position.Three), None),
      #(Position(file: position.D, rank: position.Three), None),
      #(Position(file: position.E, rank: position.Three), None),
      #(Position(file: position.F, rank: position.Three), None),
      #(Position(file: position.G, rank: position.Three), None),
      #(Position(file: position.H, rank: position.Three), None),
      #(Position(file: position.A, rank: position.Four), None),
      #(Position(file: position.B, rank: position.Four), None),
      #(Position(file: position.C, rank: position.Four), None),
      #(Position(file: position.D, rank: position.Four), None),
      #(Position(file: position.E, rank: position.Four), None),
      #(Position(file: position.F, rank: position.Four), None),
      #(Position(file: position.G, rank: position.Four), None),
      #(Position(file: position.H, rank: position.Four), None),
      #(Position(file: position.A, rank: position.Five), None),
      #(Position(file: position.B, rank: position.Five), None),
      #(Position(file: position.C, rank: position.Five), None),
      #(Position(file: position.D, rank: position.Five), None),
      #(Position(file: position.E, rank: position.Five), None),
      #(Position(file: position.F, rank: position.Five), None),
      #(Position(file: position.G, rank: position.Five), None),
      #(Position(file: position.H, rank: position.Five), None),
      #(Position(file: position.A, rank: position.Six), None),
      #(Position(file: position.B, rank: position.Six), None),
      #(Position(file: position.C, rank: position.Six), None),
      #(Position(file: position.D, rank: position.Six), None),
      #(Position(file: position.E, rank: position.Six), None),
      #(Position(file: position.F, rank: position.Six), None),
      #(Position(file: position.G, rank: position.Six), None),
      #(Position(file: position.H, rank: position.Six), None),
      #(Position(file: position.A, rank: position.Seven), None),
      #(Position(file: position.B, rank: position.Seven), None),
      #(Position(file: position.C, rank: position.Seven), None),
      #(Position(file: position.D, rank: position.Seven), None),
      #(Position(file: position.E, rank: position.Seven), None),
      #(Position(file: position.F, rank: position.Seven), None),
      #(Position(file: position.G, rank: position.Seven), None),
      #(Position(file: position.H, rank: position.Seven), None),
      #(Position(file: position.A, rank: position.Eight), None),
      #(Position(file: position.B, rank: position.Eight), None),
      #(Position(file: position.C, rank: position.Eight), None),
      #(Position(file: position.D, rank: position.Eight), None),
      #(Position(file: position.E, rank: position.Eight), None),
      #(Position(file: position.F, rank: position.Eight), None),
      #(Position(file: position.G, rank: position.Eight), None),
      #(Position(file: position.H, rank: position.Eight), None),
    ])

  let white_king_positions = bitboard.get_positions(white_king_bitboard)
  let white_queen_positions = bitboard.get_positions(white_queen_bitboard)
  let white_rook_positions = bitboard.get_positions(white_rook_bitboard)
  let white_bishop_positions = bitboard.get_positions(white_bishop_bitboard)
  let white_knight_positions = bitboard.get_positions(white_knight_bitboard)
  let white_pawns_positions = bitboard.get_positions(white_pawns_bitboard)
  let black_king_positions = bitboard.get_positions(black_king_bitboard)
  let black_queen_positions = bitboard.get_positions(black_queen_bitboard)
  let black_rook_positions = bitboard.get_positions(black_rook_bitboard)
  let black_bishop_positions = bitboard.get_positions(black_bishop_bitboard)
  let black_knight_positions = bitboard.get_positions(black_knight_bitboard)
  let black_pawns_positions = bitboard.get_positions(black_pawns_bitboard)

  let board_map =
    list.fold(
      white_king_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(Piece(White, King)))
      },
    )

  let board_map =
    list.fold(
      white_queen_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(Piece(White, Queen)))
      },
    )

  let board_map =
    list.fold(
      white_rook_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(Piece(White, Rook)))
      },
    )

  let board_map =
    list.fold(
      white_bishop_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(Piece(White, Bishop)))
      },
    )

  let board_map =
    list.fold(
      white_knight_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(Piece(White, Knight)))
      },
    )

  let board_map =
    list.fold(
      white_pawns_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(Piece(White, Pawn)))
      },
    )

  let board_map =
    list.fold(
      black_king_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(Piece(Black, King)))
      },
    )

  let board_map =
    list.fold(
      black_queen_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(Piece(Black, Queen)))
      },
    )

  let board_map =
    list.fold(
      black_rook_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(Piece(Black, Rook)))
      },
    )

  let board_map =
    list.fold(
      black_bishop_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(Piece(Black, Bishop)))
      },
    )

  let board_map =
    list.fold(
      black_knight_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(Piece(Black, Knight)))
      },
    )

  let board_map =
    list.fold(
      black_pawns_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(Piece(Black, Pawn)))
      },
    )

  board_map
}

pub fn print_board_from_fen(fen: String) {
  let parsed_fen = fen.from_string(fen)
  let board_map = bitboard_repr_to_map_repr(parsed_fen.board)
  io.print("\n")
  io.print("   +---+---+---+---+---+---+---+---+")
  list.each(
    positions_in_traversal_order,
    fn(pos) {
      let piece_to_print = result.unwrap(map.get(board_map, pos), None)
      case pos.file {
        position.A -> {
          io.print("\n")
          io.print(
            " " <> int.to_string(position.rank_to_int(pos.rank) + 1) <> " | ",
          )
          io.print(case piece_to_print {
            Some(Piece(White, Pawn)) -> "♙"
            Some(Piece(White, Knight)) -> "♘"
            Some(Piece(White, Bishop)) -> "♗"
            Some(Piece(White, Rook)) -> "♖"
            Some(Piece(White, Queen)) -> "♕"
            Some(Piece(White, King)) -> "♔"
            Some(Piece(Black, Pawn)) -> "♟"
            Some(Piece(Black, Knight)) -> "♞"
            Some(Piece(Black, Bishop)) -> "♝"
            Some(Piece(Black, Rook)) -> "♜"
            Some(Piece(Black, Queen)) -> "♛"
            Some(Piece(Black, King)) -> "♚"
            None -> " "
          })
          io.print(" | ")
        }

        position.H -> {
          io.print(case piece_to_print {
            Some(Piece(White, Pawn)) -> "♙"
            Some(Piece(White, Knight)) -> "♘"
            Some(Piece(White, Bishop)) -> "♗"
            Some(Piece(White, Rook)) -> "♖"
            Some(Piece(White, Queen)) -> "♕"
            Some(Piece(White, King)) -> "♔"
            Some(Piece(Black, Pawn)) -> "♟"
            Some(Piece(Black, Knight)) -> "♞"
            Some(Piece(Black, Bishop)) -> "♝"
            Some(Piece(Black, Rook)) -> "♜"
            Some(Piece(Black, Queen)) -> "♛"
            Some(Piece(Black, King)) -> "♚"
            None -> " "
          })

          io.print(" | ")
          io.print("\n")
          io.print("   +---+---+---+---+---+---+---+---+")
        }

        _ -> {
          io.print(case piece_to_print {
            Some(Piece(White, Pawn)) -> "♙"
            Some(Piece(White, Knight)) -> "♘"
            Some(Piece(White, Bishop)) -> "♗"
            Some(Piece(White, Rook)) -> "♖"
            Some(Piece(White, Queen)) -> "♕"
            Some(Piece(White, King)) -> "♔"
            Some(Piece(Black, Pawn)) -> "♟"
            Some(Piece(Black, Knight)) -> "♞"
            Some(Piece(Black, Bishop)) -> "♝"
            Some(Piece(Black, Rook)) -> "♜"
            Some(Piece(Black, Queen)) -> "♛"
            Some(Piece(Black, King)) -> "♚"
            None -> " "
          })
          io.print(" | ")
        }
      }
    },
  )
  io.print("\n")
  io.print("     a   b   c   d   e   f   g   h\n")
}

fn handle_print_board(
  game_state: Game,
  client: Subject(Nil),
) -> actor.Next(Message, Game) {
  let board_map = bitboard_repr_to_map_repr(game_state.board)
  io.print("\n")
  io.print("\n")
  io.print("   +---+---+---+---+---+---+---+---+")
  list.each(
    positions_in_traversal_order,
    fn(pos) {
      let piece_to_print = result.unwrap(map.get(board_map, pos), None)
      case pos.file {
        position.A -> {
          io.print("\n")
          io.print(
            " " <> int.to_string(position.rank_to_int(pos.rank) + 1) <> " | ",
          )
          io.print(case piece_to_print {
            Some(Piece(White, Pawn)) -> "♙"
            Some(Piece(White, Knight)) -> "♘"
            Some(Piece(White, Bishop)) -> "♗"
            Some(Piece(White, Rook)) -> "♖"
            Some(Piece(White, Queen)) -> "♕"
            Some(Piece(White, King)) -> "♔"
            Some(Piece(Black, Pawn)) -> "♟"
            Some(Piece(Black, Knight)) -> "♞"
            Some(Piece(Black, Bishop)) -> "♝"
            Some(Piece(Black, Rook)) -> "♜"
            Some(Piece(Black, Queen)) -> "♛"
            Some(Piece(Black, King)) -> "♚"
            None -> " "
          })
          io.print(" | ")
        }

        position.H -> {
          io.print(case piece_to_print {
            Some(Piece(White, Pawn)) -> "♙"
            Some(Piece(White, Knight)) -> "♘"
            Some(Piece(White, Bishop)) -> "♗"
            Some(Piece(White, Rook)) -> "♖"
            Some(Piece(White, Queen)) -> "♕"
            Some(Piece(White, King)) -> "♔"
            Some(Piece(Black, Pawn)) -> "♟"
            Some(Piece(Black, Knight)) -> "♞"
            Some(Piece(Black, Bishop)) -> "♝"
            Some(Piece(Black, Rook)) -> "♜"
            Some(Piece(Black, Queen)) -> "♛"
            Some(Piece(Black, King)) -> "♚"
            None -> " "
          })

          io.print(" | ")
          io.print("\n")
          io.print("   +---+---+---+---+---+---+---+---+")
        }

        _ -> {
          io.print(case piece_to_print {
            Some(Piece(White, Pawn)) -> "♙"
            Some(Piece(White, Knight)) -> "♘"
            Some(Piece(White, Bishop)) -> "♗"
            Some(Piece(White, Rook)) -> "♖"
            Some(Piece(White, Queen)) -> "♕"
            Some(Piece(White, King)) -> "♔"
            Some(Piece(Black, Pawn)) -> "♟"
            Some(Piece(Black, Knight)) -> "♞"
            Some(Piece(Black, Bishop)) -> "♝"
            Some(Piece(Black, Rook)) -> "♜"
            Some(Piece(Black, Queen)) -> "♛"
            Some(Piece(Black, King)) -> "♚"
            None -> " "
          })
          io.print(" | ")
        }
      }
    },
  )
  io.print("\n")
  io.print("     a   b   c   d   e   f   g   h\n")

  process.send(client, Nil)
  actor.continue(game_state)
}

pub fn new_server() {
  let white_king_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00001000,
    )

  let white_queen_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00010000,
    )

  let white_rook_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_10000001,
    )

  let white_bishop_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00100100,
    )

  let white_knight_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_01000010,
    )

  let white_pawns_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_11111111_00000000,
    )

  let black_king_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00001000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
    )

  let black_queen_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00010000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
    )

  let black_rook_bitboard =
    bitboard.Bitboard(
      bitboard: 0b10000001_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
    )

  let black_bishop_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00100100_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
    )

  let black_knight_bitboard =
    bitboard.Bitboard(
      bitboard: 0b01000010_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
    )

  let black_pawns_bitboard =
    bitboard.Bitboard(
      bitboard: 0b00000000_11111111_00000000_00000000_00000000_00000000_00000000_00000000,
    )

  let board =
    BoardBB(
      black_king_bitboard: black_king_bitboard,
      black_queen_bitboard: black_queen_bitboard,
      black_rook_bitboard: black_rook_bitboard,
      black_bishop_bitboard: black_bishop_bitboard,
      black_knight_bitboard: black_knight_bitboard,
      black_pawns_bitboard: black_pawns_bitboard,
      white_king_bitboard: white_king_bitboard,
      white_queen_bitboard: white_queen_bitboard,
      white_rook_bitboard: white_rook_bitboard,
      white_bishop_bitboard: white_bishop_bitboard,
      white_knight_bitboard: white_knight_bitboard,
      white_pawns_bitboard: white_pawns_bitboard,
    )

  let turn = Turn(White)

  let history = []

  let status = InProgress

  let ply = 0

  let assert Ok(actor) =
    actor.start(Game(board, turn, history, status, ply), handle_message)
  actor
}
