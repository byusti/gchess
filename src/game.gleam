import gleam/otp/actor
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None, Some}
import gleam/io
import gleam/list
import gleam/int
import gleam/map
import gleam/result
import bitboard.{type Bitboard}
import piece.{type Piece, Bishop, King, Knight, Pawn, Queen, Rook}
import color.{type Color, Black, White}
import board_map.{type BoardMap}
import board.{type BoardBB}
import move.{type Move}
import position.{
  type Position, A, B, C, D, E, Eight, F, Five, Four, G, H, One, Seven, Six,
  Three, Two,
}
import fen
import ray

pub type Status {
  Checkmate
  Stalemate
  InProgress
}

pub type Game {
  Game(
    board: BoardBB,
    turn: Color,
    history: List(Move),
    status: Status,
    ply: Int,
    white_king_castle: Bool,
    white_queen_castle: Bool,
    black_king_castle: Bool,
    black_queen_castle: Bool,
    en_passant: Option(Position),
  )
}

pub type Message {
  AllLegalMoves(reply_with: Subject(List(Move)))
  ApplyMove(reply_with: Subject(Game), move: Move)
  Shutdown
  PrintBoard(reply_with: Subject(Nil))
}

// Hard coded list of all positions in the order they will be printed
// Right now we only print the board from whites perspective
const positions_in_printing_order = [
  position.Position(file: position.A, rank: position.Eight),
  position.Position(file: position.B, rank: position.Eight),
  position.Position(file: position.C, rank: position.Eight),
  position.Position(file: position.D, rank: position.Eight),
  position.Position(file: position.E, rank: position.Eight),
  position.Position(file: position.F, rank: position.Eight),
  position.Position(file: position.G, rank: position.Eight),
  position.Position(file: position.H, rank: position.Eight),
  position.Position(file: position.A, rank: position.Seven),
  position.Position(file: position.B, rank: position.Seven),
  position.Position(file: position.C, rank: position.Seven),
  position.Position(file: position.D, rank: position.Seven),
  position.Position(file: position.E, rank: position.Seven),
  position.Position(file: position.F, rank: position.Seven),
  position.Position(file: position.G, rank: position.Seven),
  position.Position(file: position.H, rank: position.Seven),
  position.Position(file: position.A, rank: position.Six),
  position.Position(file: position.B, rank: position.Six),
  position.Position(file: position.C, rank: position.Six),
  position.Position(file: position.D, rank: position.Six),
  position.Position(file: position.E, rank: position.Six),
  position.Position(file: position.F, rank: position.Six),
  position.Position(file: position.G, rank: position.Six),
  position.Position(file: position.H, rank: position.Six),
  position.Position(file: position.A, rank: position.Five),
  position.Position(file: position.B, rank: position.Five),
  position.Position(file: position.C, rank: position.Five),
  position.Position(file: position.D, rank: position.Five),
  position.Position(file: position.E, rank: position.Five),
  position.Position(file: position.F, rank: position.Five),
  position.Position(file: position.G, rank: position.Five),
  position.Position(file: position.H, rank: position.Five),
  position.Position(file: position.A, rank: position.Four),
  position.Position(file: position.B, rank: position.Four),
  position.Position(file: position.C, rank: position.Four),
  position.Position(file: position.D, rank: position.Four),
  position.Position(file: position.E, rank: position.Four),
  position.Position(file: position.F, rank: position.Four),
  position.Position(file: position.G, rank: position.Four),
  position.Position(file: position.H, rank: position.Four),
  position.Position(file: position.A, rank: position.Three),
  position.Position(file: position.B, rank: position.Three),
  position.Position(file: position.C, rank: position.Three),
  position.Position(file: position.D, rank: position.Three),
  position.Position(file: position.E, rank: position.Three),
  position.Position(file: position.F, rank: position.Three),
  position.Position(file: position.G, rank: position.Three),
  position.Position(file: position.H, rank: position.Three),
  position.Position(file: position.A, rank: position.Two),
  position.Position(file: position.B, rank: position.Two),
  position.Position(file: position.C, rank: position.Two),
  position.Position(file: position.D, rank: position.Two),
  position.Position(file: position.E, rank: position.Two),
  position.Position(file: position.F, rank: position.Two),
  position.Position(file: position.G, rank: position.Two),
  position.Position(file: position.H, rank: position.Two),
  position.Position(file: position.A, rank: position.One),
  position.Position(file: position.B, rank: position.One),
  position.Position(file: position.C, rank: position.One),
  position.Position(file: position.D, rank: position.One),
  position.Position(file: position.E, rank: position.One),
  position.Position(file: position.F, rank: position.One),
  position.Position(file: position.G, rank: position.One),
  position.Position(file: position.H, rank: position.One),
]

const a_file = bitboard.Bitboard(
  bitboard: 0b00000001_00000001_00000001_00000001_00000001_00000001_00000001_00000001,
)

const h_file = bitboard.Bitboard(
  bitboard: 0b10000000_10000000_10000000_10000000_10000000_10000000_10000000_10000000,
)

const not_a_file = bitboard.Bitboard(
  bitboard: 0b11111110_11111110_11111110_11111110_11111110_11111110_11111110_11111110,
)

const not_b_file = bitboard.Bitboard(
  bitboard: 0b11111101_11111101_11111101_11111101_11111101_11111101_11111101_11111101,
)

const not_g_file = bitboard.Bitboard(
  bitboard: 0b10111111_10111111_10111111_10111111_10111111_10111111_10111111_10111111,
)

const not_h_file = bitboard.Bitboard(
  bitboard: 0b01111111_01111111_01111111_01111111_01111111_01111111_01111111_01111111,
)

const rank_1 = bitboard.Bitboard(
  bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_11111111,
)

const rank_2 = bitboard.Bitboard(
  bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_11111111_00000000,
)

const rank_3 = bitboard.Bitboard(
  bitboard: 0b00000000_00000000_00000000_00000000_00000000_11111111_00000000_00000000,
)

const rank_6 = bitboard.Bitboard(
  bitboard: 0b00000000_00000000_11111111_00000000_00000000_00000000_00000000_00000000,
)

const rank_7 = bitboard.Bitboard(
  bitboard: 0b00000000_11111111_00000000_00000000_00000000_00000000_00000000_00000000,
)

const rank_8 = bitboard.Bitboard(
  bitboard: 0b11111111_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
)

fn handle_message(
  message: Message,
  game_state: Game,
) -> actor.Next(Message, Game) {
  case message {
    AllLegalMoves(client) -> handle_all_legal_moves(game_state, client)
    ApplyMove(client, move) -> {
      let new_game_state = apply_move(game_state, move)
      process.send(client, new_game_state)
      actor.continue(new_game_state)
    }
    Shutdown -> actor.Stop(process.Normal)
    PrintBoard(client) -> handle_print_board(game_state, client)
  }
}

fn handle_all_legal_moves(
  game_state: Game,
  client: Subject(List(Move)),
) -> actor.Next(Message, Game) {
  let legal_moves = {
    generate_pseudo_legal_move_list(game_state, game_state.turn)
    |> list.filter(fn(move) {
      let new_game_state = apply_move(game_state, move)
      case move {
        move.Normal(from: _, to: _, captured: _, promotion: _) -> {
          !is_king_in_check(new_game_state, game_state.turn)
        }
        _ -> True
      }
    })
  }

  process.send(client, legal_moves)
  actor.continue(game_state)
}

fn apply_move(game_state: Game, move: Move) -> Game {
  case move {
    move.Normal(from: from, to: to, captured: piece, promotion: _) -> {
      let assert Some(moving_piece) =
        board.get_piece_at_position(game_state.board, from)
      let new_game_state = case piece {
        None -> game_state
        Some(_) -> {
          Game(
            ..game_state,
            board: board.remove_piece_at_position(game_state.board, to),
          )
        }
      }
      let new_game_state =
        Game(
          ..new_game_state,
          board: board.set_piece_at_position(
            new_game_state.board,
            to,
            moving_piece,
          ),
        )
      let new_game_state =
        Game(
          ..new_game_state,
          board: board.remove_piece_at_position(new_game_state.board, from),
        )

      let new_ply = new_game_state.ply + 1
      let new_white_king_castle = case game_state.turn {
        White -> {
          case game_state.white_king_castle {
            True ->
              case from {
                position.Position(file: E, rank: One) -> False
                position.Position(file: H, rank: One) -> False
                _ -> True
              }
            False -> False
          }
        }
        Black -> game_state.white_king_castle
      }
      let new_white_queen_castle = case game_state.turn {
        White -> {
          case game_state.white_queen_castle {
            True ->
              case from {
                position.Position(file: E, rank: One) -> False
                position.Position(file: A, rank: One) -> False
                _ -> True
              }
            False -> False
          }
        }
        Black -> game_state.white_queen_castle
      }
      let new_black_king_castle = case game_state.turn {
        White -> game_state.black_king_castle
        Black -> {
          case game_state.black_king_castle {
            True ->
              case from {
                position.Position(file: E, rank: Eight) -> False
                position.Position(file: H, rank: Eight) -> False
                _ -> True
              }
            False -> False
          }
        }
      }
      let new_black_queen_castle = case game_state.turn {
        White -> game_state.black_queen_castle
        Black -> {
          case game_state.black_queen_castle {
            True ->
              case from {
                position.Position(file: E, rank: Eight) -> False
                position.Position(file: A, rank: Eight) -> False
                _ -> True
              }
            False -> False
          }
        }
      }
      let new_turn = {
        case game_state.turn {
          White -> Black
          Black -> White
        }
      }

      let new_history = [move, ..game_state.history]

      let new_en_passant = case moving_piece {
        piece.Piece(color: color, kind: piece.Pawn) -> {
          case color {
            White -> {
              case from {
                position.Position(file: _, rank: Two) -> {
                  case to {
                    position.Position(file: _, rank: Four) ->
                      Some(position.Position(file: from.file, rank: Three))
                    _ -> None
                  }
                }
                _ -> None
              }
            }
            Black -> {
              case from {
                position.Position(file: _, rank: Seven) -> {
                  case to {
                    position.Position(file: _, rank: Five) ->
                      Some(position.Position(file: from.file, rank: Six))
                    _ -> None
                  }
                }
                _ -> None
              }
            }
          }
        }
        _ -> None
      }

      let new_game_state =
        Game(
          ..new_game_state,
          turn: new_turn,
          history: new_history,
          ply: new_ply,
          white_king_castle: new_white_king_castle,
          white_queen_castle: new_white_queen_castle,
          black_king_castle: new_black_king_castle,
          black_queen_castle: new_black_queen_castle,
          en_passant: new_en_passant,
        )
      new_game_state
    }
    move.Castle(from: from, to: to) -> {
      let new_game_state =
        Game(
          ..game_state,
          board: board.set_piece_at_position(
            game_state.board,
            to,
            piece.Piece(color: game_state.turn, kind: King),
          ),
        )
      let rook_castling_target_square = case to {
        position.Position(file: G, rank: One) ->
          position.Position(file: F, rank: One)
        position.Position(file: G, rank: Eight) ->
          position.Position(file: F, rank: Eight)
        position.Position(file: C, rank: One) ->
          position.Position(file: D, rank: One)
        position.Position(file: C, rank: Eight) ->
          position.Position(file: D, rank: Eight)
        _ -> panic("Invalid castle move")
      }
      let new_game_state =
        Game(
          ..new_game_state,
          board: board.set_piece_at_position(
            new_game_state.board,
            rook_castling_target_square,
            piece.Piece(color: game_state.turn, kind: Rook),
          ),
        )
      let new_game_state =
        Game(
          ..new_game_state,
          board: board.remove_piece_at_position(new_game_state.board, from),
        )

      let rook_castling_origin_square = case to {
        position.Position(file: G, rank: One) ->
          position.Position(file: H, rank: One)
        position.Position(file: G, rank: Eight) ->
          position.Position(file: H, rank: Eight)
        position.Position(file: C, rank: One) ->
          position.Position(file: A, rank: One)
        position.Position(file: C, rank: Eight) ->
          position.Position(file: A, rank: Eight)
        _ -> panic("Invalid castle move")
      }

      let new_game_state =
        Game(
          ..new_game_state,
          board: board.remove_piece_at_position(
            new_game_state.board,
            rook_castling_origin_square,
          ),
        )

      let [
        new_white_king_castle,
        new_white_queen_castle,
        new_black_king_castle,
        new_black_queen_castle,
      ] = case game_state.turn {
        White -> [
          False,
          False,
          game_state.black_king_castle,
          game_state.black_queen_castle,
        ]
        Black -> [
          game_state.white_king_castle,
          game_state.white_queen_castle,
          False,
          False,
        ]
      }

      let new_ply = new_game_state.ply + 1
      let new_turn = {
        case game_state.turn {
          White -> Black
          Black -> White
        }
      }

      let new_history = [move, ..game_state.history]

      let new_game_state =
        Game(
          ..new_game_state,
          turn: new_turn,
          history: new_history,
          ply: new_ply,
          white_king_castle: new_white_king_castle,
          white_queen_castle: new_white_queen_castle,
          black_king_castle: new_black_king_castle,
          black_queen_castle: new_black_queen_castle,
        )
      new_game_state
    }
    move.EnPassant(from: from, to: to) -> {
      let new_game_state =
        Game(
          ..game_state,
          board: board.set_piece_at_position(
            game_state.board,
            to,
            piece.Piece(color: game_state.turn, kind: Pawn),
          ),
        )
      let new_game_state =
        Game(
          ..new_game_state,
          board: board.remove_piece_at_position(new_game_state.board, from),
        )

      let captured_pawn_square = case to {
        position.Position(file: A, rank: Three) ->
          position.Position(file: A, rank: Four)
        position.Position(file: A, rank: Six) ->
          position.Position(file: A, rank: Five)
        position.Position(file: B, rank: Three) ->
          position.Position(file: B, rank: Four)
        position.Position(file: B, rank: Six) ->
          position.Position(file: B, rank: Five)
        position.Position(file: C, rank: Three) ->
          position.Position(file: C, rank: Four)
        position.Position(file: C, rank: Six) ->
          position.Position(file: C, rank: Five)
        position.Position(file: D, rank: Three) ->
          position.Position(file: D, rank: Four)
        position.Position(file: D, rank: Six) ->
          position.Position(file: D, rank: Five)
        position.Position(file: E, rank: Three) ->
          position.Position(file: E, rank: Four)
        position.Position(file: E, rank: Six) ->
          position.Position(file: E, rank: Five)
        position.Position(file: F, rank: Three) ->
          position.Position(file: F, rank: Four)
        position.Position(file: F, rank: Six) ->
          position.Position(file: F, rank: Five)
        position.Position(file: G, rank: Three) ->
          position.Position(file: G, rank: Four)
        position.Position(file: G, rank: Six) ->
          position.Position(file: G, rank: Five)
        position.Position(file: H, rank: Three) ->
          position.Position(file: H, rank: Four)
        position.Position(file: H, rank: Six) ->
          position.Position(file: H, rank: Five)
        _ -> panic("Invalid en passant move")
      }

      let new_game_state =
        Game(
          ..new_game_state,
          board: board.remove_piece_at_position(
            new_game_state.board,
            captured_pawn_square,
          ),
        )
      new_game_state
    }
  }
}

fn is_king_in_check(game_state: Game, color: Color) -> Bool {
  let enemy_color = {
    case color {
      White -> Black
      Black -> White
    }
  }
  let enemy_move_list = {
    generate_pseudo_legal_move_list(game_state, enemy_color)
  }
  let enemy_move_list = {
    enemy_move_list
    |> list.filter(fn(move) {
      case move {
        move.Normal(from: _, to: _, captured: Some(piece), promotion: _) ->
          piece == piece.Piece(color: color, kind: King)
        _ -> False
      }
    })
  }
  list.length(enemy_move_list) > 0
}

fn generate_pseudo_legal_move_list(game_state: Game, color: Color) -> List(Move) {
  let list_of_move_lists = [
    generate_rook_pseudo_legal_move_list(color, game_state),
    generate_pawn_pseudo_legal_move_list(color, game_state),
    generate_knight_pseudo_legal_move_list(color, game_state),
    generate_bishop_pseudo_legal_move_list(color, game_state),
    generate_queen_pseudo_legal_move_list(color, game_state),
    generate_king_pseudo_legal_move_list(color, game_state),
    generate_castling_pseudo_legal_move_list(color, game_state),
    generate_en_passant_pseudo_legal_move_list(color, game_state),
  ]

  let move_list =
    list.fold(
      list_of_move_lists,
      [],
      fn(collector, next) { list.append(collector, next) },
    )

  move_list
}

fn look_up_east_ray_bb(origin_square: Position) -> Bitboard {
  case origin_square {
    position.Position(file: A, rank: One) -> ray.a1_east
    position.Position(file: A, rank: Two) -> ray.a2_east
    position.Position(file: A, rank: Three) -> ray.a3_east
    position.Position(file: A, rank: Four) -> ray.a4_east
    position.Position(file: A, rank: Five) -> ray.a5_east
    position.Position(file: A, rank: Six) -> ray.a6_east
    position.Position(file: A, rank: Seven) -> ray.a7_east
    position.Position(file: A, rank: Eight) -> ray.a8_east
    position.Position(file: B, rank: One) -> ray.b1_east
    position.Position(file: B, rank: Two) -> ray.b2_east
    position.Position(file: B, rank: Three) -> ray.b3_east
    position.Position(file: B, rank: Four) -> ray.b4_east
    position.Position(file: B, rank: Five) -> ray.b5_east
    position.Position(file: B, rank: Six) -> ray.b6_east
    position.Position(file: B, rank: Seven) -> ray.b7_east
    position.Position(file: B, rank: Eight) -> ray.b8_east
    position.Position(file: C, rank: One) -> ray.c1_east
    position.Position(file: C, rank: Two) -> ray.c2_east
    position.Position(file: C, rank: Three) -> ray.c3_east
    position.Position(file: C, rank: Four) -> ray.c4_east
    position.Position(file: C, rank: Five) -> ray.c5_east
    position.Position(file: C, rank: Six) -> ray.c6_east
    position.Position(file: C, rank: Seven) -> ray.c7_east
    position.Position(file: C, rank: Eight) -> ray.c8_east
    position.Position(file: D, rank: One) -> ray.d1_east
    position.Position(file: D, rank: Two) -> ray.d2_east
    position.Position(file: D, rank: Three) -> ray.d3_east
    position.Position(file: D, rank: Four) -> ray.d4_east
    position.Position(file: D, rank: Five) -> ray.d5_east
    position.Position(file: D, rank: Six) -> ray.d6_east
    position.Position(file: D, rank: Seven) -> ray.d7_east
    position.Position(file: D, rank: Eight) -> ray.d8_east
    position.Position(file: E, rank: One) -> ray.e1_east
    position.Position(file: E, rank: Two) -> ray.e2_east
    position.Position(file: E, rank: Three) -> ray.e3_east
    position.Position(file: E, rank: Four) -> ray.e4_east
    position.Position(file: E, rank: Five) -> ray.e5_east
    position.Position(file: E, rank: Six) -> ray.e6_east
    position.Position(file: E, rank: Seven) -> ray.e7_east
    position.Position(file: E, rank: Eight) -> ray.e8_east
    position.Position(file: F, rank: One) -> ray.f1_east
    position.Position(file: F, rank: Two) -> ray.f2_east
    position.Position(file: F, rank: Three) -> ray.f3_east
    position.Position(file: F, rank: Four) -> ray.f4_east
    position.Position(file: F, rank: Five) -> ray.f5_east
    position.Position(file: F, rank: Six) -> ray.f6_east
    position.Position(file: F, rank: Seven) -> ray.f7_east
    position.Position(file: F, rank: Eight) -> ray.f8_east
    position.Position(file: G, rank: One) -> ray.g1_east
    position.Position(file: G, rank: Two) -> ray.g2_east
    position.Position(file: G, rank: Three) -> ray.g3_east
    position.Position(file: G, rank: Four) -> ray.g4_east
    position.Position(file: G, rank: Five) -> ray.g5_east
    position.Position(file: G, rank: Six) -> ray.g6_east
    position.Position(file: G, rank: Seven) -> ray.g7_east
    position.Position(file: G, rank: Eight) -> ray.g8_east
    position.Position(file: H, rank: One) -> ray.h1_east
    position.Position(file: H, rank: Two) -> ray.h2_east
    position.Position(file: H, rank: Three) -> ray.h3_east
    position.Position(file: H, rank: Four) -> ray.h4_east
    position.Position(file: H, rank: Five) -> ray.h5_east
    position.Position(file: H, rank: Six) -> ray.h6_east
    position.Position(file: H, rank: Seven) -> ray.h7_east
    position.Position(file: H, rank: Eight) -> ray.h8_east
  }
}

fn look_up_north_ray_bb(origin_square: Position) -> Bitboard {
  case origin_square {
    position.Position(file: A, rank: Eight) -> ray.a8_north
    position.Position(file: A, rank: Seven) -> ray.a7_north
    position.Position(file: A, rank: Six) -> ray.a6_north
    position.Position(file: A, rank: Five) -> ray.a5_north
    position.Position(file: A, rank: Four) -> ray.a4_north
    position.Position(file: A, rank: Three) -> ray.a3_north
    position.Position(file: A, rank: Two) -> ray.a2_north
    position.Position(file: A, rank: One) -> ray.a1_north
    position.Position(file: B, rank: Eight) -> ray.b8_north
    position.Position(file: B, rank: Seven) -> ray.b7_north
    position.Position(file: B, rank: Six) -> ray.b6_north
    position.Position(file: B, rank: Five) -> ray.b5_north
    position.Position(file: B, rank: Four) -> ray.b4_north
    position.Position(file: B, rank: Three) -> ray.b3_north
    position.Position(file: B, rank: Two) -> ray.b2_north
    position.Position(file: B, rank: One) -> ray.b1_north
    position.Position(file: C, rank: Eight) -> ray.c8_north
    position.Position(file: C, rank: Seven) -> ray.c7_north
    position.Position(file: C, rank: Six) -> ray.c6_north
    position.Position(file: C, rank: Five) -> ray.c5_north
    position.Position(file: C, rank: Four) -> ray.c4_north
    position.Position(file: C, rank: Three) -> ray.c3_north
    position.Position(file: C, rank: Two) -> ray.c2_north
    position.Position(file: C, rank: One) -> ray.c1_north
    position.Position(file: D, rank: Eight) -> ray.d8_north
    position.Position(file: D, rank: Seven) -> ray.d7_north
    position.Position(file: D, rank: Six) -> ray.d6_north
    position.Position(file: D, rank: Five) -> ray.d5_north
    position.Position(file: D, rank: Four) -> ray.d4_north
    position.Position(file: D, rank: Three) -> ray.d3_north
    position.Position(file: D, rank: Two) -> ray.d2_north
    position.Position(file: D, rank: One) -> ray.d1_north
    position.Position(file: E, rank: Eight) -> ray.e8_north
    position.Position(file: E, rank: Seven) -> ray.e7_north
    position.Position(file: E, rank: Six) -> ray.e6_north
    position.Position(file: E, rank: Five) -> ray.e5_north
    position.Position(file: E, rank: Four) -> ray.e4_north
    position.Position(file: E, rank: Three) -> ray.e3_north
    position.Position(file: E, rank: Two) -> ray.e2_north
    position.Position(file: E, rank: One) -> ray.e1_north
    position.Position(file: F, rank: Eight) -> ray.f8_north
    position.Position(file: F, rank: Seven) -> ray.f7_north
    position.Position(file: F, rank: Six) -> ray.f6_north
    position.Position(file: F, rank: Five) -> ray.f5_north
    position.Position(file: F, rank: Four) -> ray.f4_north
    position.Position(file: F, rank: Three) -> ray.f3_north
    position.Position(file: F, rank: Two) -> ray.f2_north
    position.Position(file: F, rank: One) -> ray.f1_north
    position.Position(file: G, rank: Eight) -> ray.g8_north
    position.Position(file: G, rank: Seven) -> ray.g7_north
    position.Position(file: G, rank: Six) -> ray.g6_north
    position.Position(file: G, rank: Five) -> ray.g5_north
    position.Position(file: G, rank: Four) -> ray.g4_north
    position.Position(file: G, rank: Three) -> ray.g3_north
    position.Position(file: G, rank: Two) -> ray.g2_north
    position.Position(file: G, rank: One) -> ray.g1_north
    position.Position(file: H, rank: Eight) -> ray.h8_north
    position.Position(file: H, rank: Seven) -> ray.h7_north
    position.Position(file: H, rank: Six) -> ray.h6_north
    position.Position(file: H, rank: Five) -> ray.h5_north
    position.Position(file: H, rank: Four) -> ray.h4_north
    position.Position(file: H, rank: Three) -> ray.h3_north
    position.Position(file: H, rank: Two) -> ray.h2_north
    position.Position(file: H, rank: One) -> ray.h1_north
  }
}

fn look_up_west_ray_bb(origin_square: Position) -> Bitboard {
  case origin_square {
    position.Position(file: H, rank: Eight) -> ray.h8_west
    position.Position(file: H, rank: Seven) -> ray.h7_west
    position.Position(file: H, rank: Six) -> ray.h6_west
    position.Position(file: H, rank: Five) -> ray.h5_west
    position.Position(file: H, rank: Four) -> ray.h4_west
    position.Position(file: H, rank: Three) -> ray.h3_west
    position.Position(file: H, rank: Two) -> ray.h2_west
    position.Position(file: H, rank: One) -> ray.h1_west
    position.Position(file: G, rank: Eight) -> ray.g8_west
    position.Position(file: G, rank: Seven) -> ray.g7_west
    position.Position(file: G, rank: Six) -> ray.g6_west
    position.Position(file: G, rank: Five) -> ray.g5_west
    position.Position(file: G, rank: Four) -> ray.g4_west
    position.Position(file: G, rank: Three) -> ray.g3_west
    position.Position(file: G, rank: Two) -> ray.g2_west
    position.Position(file: G, rank: One) -> ray.g1_west
    position.Position(file: F, rank: Eight) -> ray.f8_west
    position.Position(file: F, rank: Seven) -> ray.f7_west
    position.Position(file: F, rank: Six) -> ray.f6_west
    position.Position(file: F, rank: Five) -> ray.f5_west
    position.Position(file: F, rank: Four) -> ray.f4_west
    position.Position(file: F, rank: Three) -> ray.f3_west
    position.Position(file: F, rank: Two) -> ray.f2_west
    position.Position(file: F, rank: One) -> ray.f1_west
    position.Position(file: E, rank: Eight) -> ray.e8_west
    position.Position(file: E, rank: Seven) -> ray.e7_west
    position.Position(file: E, rank: Six) -> ray.e6_west
    position.Position(file: E, rank: Five) -> ray.e5_west
    position.Position(file: E, rank: Four) -> ray.e4_west
    position.Position(file: E, rank: Three) -> ray.e3_west
    position.Position(file: E, rank: Two) -> ray.e2_west
    position.Position(file: E, rank: One) -> ray.e1_west
    position.Position(file: D, rank: Eight) -> ray.d8_west
    position.Position(file: D, rank: Seven) -> ray.d7_west
    position.Position(file: D, rank: Six) -> ray.d6_west
    position.Position(file: D, rank: Five) -> ray.d5_west
    position.Position(file: D, rank: Four) -> ray.d4_west
    position.Position(file: D, rank: Three) -> ray.d3_west
    position.Position(file: D, rank: Two) -> ray.d2_west
    position.Position(file: D, rank: One) -> ray.d1_west
    position.Position(file: C, rank: Eight) -> ray.c8_west
    position.Position(file: C, rank: Seven) -> ray.c7_west
    position.Position(file: C, rank: Six) -> ray.c6_west
    position.Position(file: C, rank: Five) -> ray.c5_west
    position.Position(file: C, rank: Four) -> ray.c4_west
    position.Position(file: C, rank: Three) -> ray.c3_west
    position.Position(file: C, rank: Two) -> ray.c2_west
    position.Position(file: C, rank: One) -> ray.c1_west
    position.Position(file: B, rank: Eight) -> ray.b8_west
    position.Position(file: B, rank: Seven) -> ray.b7_west
    position.Position(file: B, rank: Six) -> ray.b6_west
    position.Position(file: B, rank: Five) -> ray.b5_west
    position.Position(file: B, rank: Four) -> ray.b4_west
    position.Position(file: B, rank: Three) -> ray.b3_west
    position.Position(file: B, rank: Two) -> ray.b2_west
    position.Position(file: B, rank: One) -> ray.b1_west
    position.Position(file: A, rank: Eight) -> ray.a8_west
    position.Position(file: A, rank: Seven) -> ray.a7_west
    position.Position(file: A, rank: Six) -> ray.a6_west
    position.Position(file: A, rank: Five) -> ray.a5_west
    position.Position(file: A, rank: Four) -> ray.a4_west
    position.Position(file: A, rank: Three) -> ray.a3_west
    position.Position(file: A, rank: Two) -> ray.a2_west
    position.Position(file: A, rank: One) -> ray.a1_west
  }
}

fn look_up_south_ray_bb(origin_square: Position) -> Bitboard {
  case origin_square {
    position.Position(file: A, rank: Eight) -> ray.a8_south
    position.Position(file: A, rank: Seven) -> ray.a7_south
    position.Position(file: A, rank: Six) -> ray.a6_south
    position.Position(file: A, rank: Five) -> ray.a5_south
    position.Position(file: A, rank: Four) -> ray.a4_south
    position.Position(file: A, rank: Three) -> ray.a3_south
    position.Position(file: A, rank: Two) -> ray.a2_south
    position.Position(file: A, rank: One) -> ray.a1_south
    position.Position(file: B, rank: Eight) -> ray.b8_south
    position.Position(file: B, rank: Seven) -> ray.b7_south
    position.Position(file: B, rank: Six) -> ray.b6_south
    position.Position(file: B, rank: Five) -> ray.b5_south
    position.Position(file: B, rank: Four) -> ray.b4_south
    position.Position(file: B, rank: Three) -> ray.b3_south
    position.Position(file: B, rank: Two) -> ray.b2_south
    position.Position(file: B, rank: One) -> ray.b1_south
    position.Position(file: C, rank: Eight) -> ray.c8_south
    position.Position(file: C, rank: Seven) -> ray.c7_south
    position.Position(file: C, rank: Six) -> ray.c6_south
    position.Position(file: C, rank: Five) -> ray.c5_south
    position.Position(file: C, rank: Four) -> ray.c4_south
    position.Position(file: C, rank: Three) -> ray.c3_south
    position.Position(file: C, rank: Two) -> ray.c2_south
    position.Position(file: C, rank: One) -> ray.c1_south
    position.Position(file: D, rank: Eight) -> ray.d8_south
    position.Position(file: D, rank: Seven) -> ray.d7_south
    position.Position(file: D, rank: Six) -> ray.d6_south
    position.Position(file: D, rank: Five) -> ray.d5_south
    position.Position(file: D, rank: Four) -> ray.d4_south
    position.Position(file: D, rank: Three) -> ray.d3_south
    position.Position(file: D, rank: Two) -> ray.d2_south
    position.Position(file: D, rank: One) -> ray.d1_south
    position.Position(file: E, rank: Eight) -> ray.e8_south
    position.Position(file: E, rank: Seven) -> ray.e7_south
    position.Position(file: E, rank: Six) -> ray.e6_south
    position.Position(file: E, rank: Five) -> ray.e5_south
    position.Position(file: E, rank: Four) -> ray.e4_south
    position.Position(file: E, rank: Three) -> ray.e3_south
    position.Position(file: E, rank: Two) -> ray.e2_south
    position.Position(file: E, rank: One) -> ray.e1_south
    position.Position(file: F, rank: Eight) -> ray.f8_south
    position.Position(file: F, rank: Seven) -> ray.f7_south
    position.Position(file: F, rank: Six) -> ray.f6_south
    position.Position(file: F, rank: Five) -> ray.f5_south
    position.Position(file: F, rank: Four) -> ray.f4_south
    position.Position(file: F, rank: Three) -> ray.f3_south
    position.Position(file: F, rank: Two) -> ray.f2_south
    position.Position(file: F, rank: One) -> ray.f1_south
    position.Position(file: G, rank: Eight) -> ray.g8_south
    position.Position(file: G, rank: Seven) -> ray.g7_south
    position.Position(file: G, rank: Six) -> ray.g6_south
    position.Position(file: G, rank: Five) -> ray.g5_south
    position.Position(file: G, rank: Four) -> ray.g4_south
    position.Position(file: G, rank: Three) -> ray.g3_south
    position.Position(file: G, rank: Two) -> ray.g2_south
    position.Position(file: G, rank: One) -> ray.g1_south
    position.Position(file: H, rank: Eight) -> ray.h8_south
    position.Position(file: H, rank: Seven) -> ray.h7_south
    position.Position(file: H, rank: Six) -> ray.h6_south
    position.Position(file: H, rank: Five) -> ray.h5_south
    position.Position(file: H, rank: Four) -> ray.h4_south
    position.Position(file: H, rank: Three) -> ray.h3_south
    position.Position(file: H, rank: Two) -> ray.h2_south
    position.Position(file: H, rank: One) -> ray.h1_south
  }
}

fn look_up_south_west_ray_bb(origin_square: Position) -> Bitboard {
  case origin_square {
    position.Position(file: A, rank: Eight) -> ray.a8_south_west
    position.Position(file: A, rank: Seven) -> ray.a7_south_west
    position.Position(file: A, rank: Six) -> ray.a6_south_west
    position.Position(file: A, rank: Five) -> ray.a5_south_west
    position.Position(file: A, rank: Four) -> ray.a4_south_west
    position.Position(file: A, rank: Three) -> ray.a3_south_west
    position.Position(file: A, rank: Two) -> ray.a2_south_west
    position.Position(file: A, rank: One) -> ray.a1_south_west
    position.Position(file: B, rank: Eight) -> ray.b8_south_west
    position.Position(file: B, rank: Seven) -> ray.b7_south_west
    position.Position(file: B, rank: Six) -> ray.b6_south_west
    position.Position(file: B, rank: Five) -> ray.b5_south_west
    position.Position(file: B, rank: Four) -> ray.b4_south_west
    position.Position(file: B, rank: Three) -> ray.b3_south_west
    position.Position(file: B, rank: Two) -> ray.b2_south_west
    position.Position(file: B, rank: One) -> ray.b1_south_west
    position.Position(file: C, rank: Eight) -> ray.c8_south_west
    position.Position(file: C, rank: Seven) -> ray.c7_south_west
    position.Position(file: C, rank: Six) -> ray.c6_south_west
    position.Position(file: C, rank: Five) -> ray.c5_south_west
    position.Position(file: C, rank: Four) -> ray.c4_south_west
    position.Position(file: C, rank: Three) -> ray.c3_south_west
    position.Position(file: C, rank: Two) -> ray.c2_south_west
    position.Position(file: C, rank: One) -> ray.c1_south_west
    position.Position(file: D, rank: Eight) -> ray.d8_south_west
    position.Position(file: D, rank: Seven) -> ray.d7_south_west
    position.Position(file: D, rank: Six) -> ray.d6_south_west
    position.Position(file: D, rank: Five) -> ray.d5_south_west
    position.Position(file: D, rank: Four) -> ray.d4_south_west
    position.Position(file: D, rank: Three) -> ray.d3_south_west
    position.Position(file: D, rank: Two) -> ray.d2_south_west
    position.Position(file: D, rank: One) -> ray.d1_south_west
    position.Position(file: E, rank: Eight) -> ray.e8_south_west
    position.Position(file: E, rank: Seven) -> ray.e7_south_west
    position.Position(file: E, rank: Six) -> ray.e6_south_west
    position.Position(file: E, rank: Five) -> ray.e5_south_west
    position.Position(file: E, rank: Four) -> ray.e4_south_west
    position.Position(file: E, rank: Three) -> ray.e3_south_west
    position.Position(file: E, rank: Two) -> ray.e2_south_west
    position.Position(file: E, rank: One) -> ray.e1_south_west
    position.Position(file: F, rank: Eight) -> ray.f8_south_west
    position.Position(file: F, rank: Seven) -> ray.f7_south_west
    position.Position(file: F, rank: Six) -> ray.f6_south_west
    position.Position(file: F, rank: Five) -> ray.f5_south_west
    position.Position(file: F, rank: Four) -> ray.f4_south_west
    position.Position(file: F, rank: Three) -> ray.f3_south_west
    position.Position(file: F, rank: Two) -> ray.f2_south_west
    position.Position(file: F, rank: One) -> ray.f1_south_west
    position.Position(file: G, rank: Eight) -> ray.g8_south_west
    position.Position(file: G, rank: Seven) -> ray.g7_south_west
    position.Position(file: G, rank: Six) -> ray.g6_south_west
    position.Position(file: G, rank: Five) -> ray.g5_south_west
    position.Position(file: G, rank: Four) -> ray.g4_south_west
    position.Position(file: G, rank: Three) -> ray.g3_south_west
    position.Position(file: G, rank: Two) -> ray.g2_south_west
    position.Position(file: G, rank: One) -> ray.g1_south_west
    position.Position(file: H, rank: Eight) -> ray.h8_south_west
    position.Position(file: H, rank: Seven) -> ray.h7_south_west
    position.Position(file: H, rank: Six) -> ray.h6_south_west
    position.Position(file: H, rank: Five) -> ray.h5_south_west
    position.Position(file: H, rank: Four) -> ray.h4_south_west
    position.Position(file: H, rank: Three) -> ray.h3_south_west
    position.Position(file: H, rank: Two) -> ray.h2_south_west
    position.Position(file: H, rank: One) -> ray.h1_south_west
  }
}

fn look_up_south_east_ray_bb(origin_square: Position) -> Bitboard {
  case origin_square {
    position.Position(file: A, rank: Eight) -> ray.a8_south_east
    position.Position(file: A, rank: Seven) -> ray.a7_south_east
    position.Position(file: A, rank: Six) -> ray.a6_south_east
    position.Position(file: A, rank: Five) -> ray.a5_south_east
    position.Position(file: A, rank: Four) -> ray.a4_south_east
    position.Position(file: A, rank: Three) -> ray.a3_south_east
    position.Position(file: A, rank: Two) -> ray.a2_south_east
    position.Position(file: A, rank: One) -> ray.a1_south_east
    position.Position(file: B, rank: Eight) -> ray.b8_south_east
    position.Position(file: B, rank: Seven) -> ray.b7_south_east
    position.Position(file: B, rank: Six) -> ray.b6_south_east
    position.Position(file: B, rank: Five) -> ray.b5_south_east
    position.Position(file: B, rank: Four) -> ray.b4_south_east
    position.Position(file: B, rank: Three) -> ray.b3_south_east
    position.Position(file: B, rank: Two) -> ray.b2_south_east
    position.Position(file: B, rank: One) -> ray.b1_south_east
    position.Position(file: C, rank: Eight) -> ray.c8_south_east
    position.Position(file: C, rank: Seven) -> ray.c7_south_east
    position.Position(file: C, rank: Six) -> ray.c6_south_east
    position.Position(file: C, rank: Five) -> ray.c5_south_east
    position.Position(file: C, rank: Four) -> ray.c4_south_east
    position.Position(file: C, rank: Three) -> ray.c3_south_east
    position.Position(file: C, rank: Two) -> ray.c2_south_east
    position.Position(file: C, rank: One) -> ray.c1_south_east
    position.Position(file: D, rank: Eight) -> ray.d8_south_east
    position.Position(file: D, rank: Seven) -> ray.d7_south_east
    position.Position(file: D, rank: Six) -> ray.d6_south_east
    position.Position(file: D, rank: Five) -> ray.d5_south_east
    position.Position(file: D, rank: Four) -> ray.d4_south_east
    position.Position(file: D, rank: Three) -> ray.d3_south_east
    position.Position(file: D, rank: Two) -> ray.d2_south_east
    position.Position(file: D, rank: One) -> ray.d1_south_east
    position.Position(file: E, rank: Eight) -> ray.e8_south_east
    position.Position(file: E, rank: Seven) -> ray.e7_south_east
    position.Position(file: E, rank: Six) -> ray.e6_south_east
    position.Position(file: E, rank: Five) -> ray.e5_south_east
    position.Position(file: E, rank: Four) -> ray.e4_south_east
    position.Position(file: E, rank: Three) -> ray.e3_south_east
    position.Position(file: E, rank: Two) -> ray.e2_south_east
    position.Position(file: E, rank: One) -> ray.e1_south_east
    position.Position(file: F, rank: Eight) -> ray.f8_south_east
    position.Position(file: F, rank: Seven) -> ray.f7_south_east
    position.Position(file: F, rank: Six) -> ray.f6_south_east
    position.Position(file: F, rank: Five) -> ray.f5_south_east
    position.Position(file: F, rank: Four) -> ray.f4_south_east
    position.Position(file: F, rank: Three) -> ray.f3_south_east
    position.Position(file: F, rank: Two) -> ray.f2_south_east
    position.Position(file: F, rank: One) -> ray.f1_south_east
    position.Position(file: G, rank: Eight) -> ray.g8_south_east
    position.Position(file: G, rank: Seven) -> ray.g7_south_east
    position.Position(file: G, rank: Six) -> ray.g6_south_east
    position.Position(file: G, rank: Five) -> ray.g5_south_east
    position.Position(file: G, rank: Four) -> ray.g4_south_east
    position.Position(file: G, rank: Three) -> ray.g3_south_east
    position.Position(file: G, rank: Two) -> ray.g2_south_east
    position.Position(file: G, rank: One) -> ray.g1_south_east
    position.Position(file: H, rank: Eight) -> ray.h8_south_east
    position.Position(file: H, rank: Seven) -> ray.h7_south_east
    position.Position(file: H, rank: Six) -> ray.h6_south_east
    position.Position(file: H, rank: Five) -> ray.h5_south_east
    position.Position(file: H, rank: Four) -> ray.h4_south_east
    position.Position(file: H, rank: Three) -> ray.h3_south_east
    position.Position(file: H, rank: Two) -> ray.h2_south_east
    position.Position(file: H, rank: One) -> ray.h1_south_east
  }
}

fn look_up_north_east_ray_bb(origin_square: Position) -> Bitboard {
  case origin_square {
    position.Position(file: A, rank: One) -> ray.a1_north_east
    position.Position(file: A, rank: Two) -> ray.a2_north_east
    position.Position(file: A, rank: Three) -> ray.a3_north_east
    position.Position(file: A, rank: Four) -> ray.a4_north_east
    position.Position(file: A, rank: Five) -> ray.a5_north_east
    position.Position(file: A, rank: Six) -> ray.a6_north_east
    position.Position(file: A, rank: Seven) -> ray.a7_north_east
    position.Position(file: A, rank: Eight) -> ray.a8_north_east
    position.Position(file: B, rank: One) -> ray.b1_north_east
    position.Position(file: B, rank: Two) -> ray.b2_north_east
    position.Position(file: B, rank: Three) -> ray.b3_north_east
    position.Position(file: B, rank: Four) -> ray.b4_north_east
    position.Position(file: B, rank: Five) -> ray.b5_north_east
    position.Position(file: B, rank: Six) -> ray.b6_north_east
    position.Position(file: B, rank: Seven) -> ray.b7_north_east
    position.Position(file: B, rank: Eight) -> ray.b8_north_east
    position.Position(file: C, rank: One) -> ray.c1_north_east
    position.Position(file: C, rank: Two) -> ray.c2_north_east
    position.Position(file: C, rank: Three) -> ray.c3_north_east
    position.Position(file: C, rank: Four) -> ray.c4_north_east
    position.Position(file: C, rank: Five) -> ray.c5_north_east
    position.Position(file: C, rank: Six) -> ray.c6_north_east
    position.Position(file: C, rank: Seven) -> ray.c7_north_east
    position.Position(file: C, rank: Eight) -> ray.c8_north_east
    position.Position(file: D, rank: One) -> ray.d1_north_east
    position.Position(file: D, rank: Two) -> ray.d2_north_east
    position.Position(file: D, rank: Three) -> ray.d3_north_east
    position.Position(file: D, rank: Four) -> ray.d4_north_east
    position.Position(file: D, rank: Five) -> ray.d5_north_east
    position.Position(file: D, rank: Six) -> ray.d6_north_east
    position.Position(file: D, rank: Seven) -> ray.d7_north_east
    position.Position(file: D, rank: Eight) -> ray.d8_north_east
    position.Position(file: E, rank: One) -> ray.e1_north_east
    position.Position(file: E, rank: Two) -> ray.e2_north_east
    position.Position(file: E, rank: Three) -> ray.e3_north_east
    position.Position(file: E, rank: Four) -> ray.e4_north_east
    position.Position(file: E, rank: Five) -> ray.e5_north_east
    position.Position(file: E, rank: Six) -> ray.e6_north_east
    position.Position(file: E, rank: Seven) -> ray.e7_north_east
    position.Position(file: E, rank: Eight) -> ray.e8_north_east
    position.Position(file: F, rank: One) -> ray.f1_north_east
    position.Position(file: F, rank: Two) -> ray.f2_north_east
    position.Position(file: F, rank: Three) -> ray.f3_north_east
    position.Position(file: F, rank: Four) -> ray.f4_north_east
    position.Position(file: F, rank: Five) -> ray.f5_north_east
    position.Position(file: F, rank: Six) -> ray.f6_north_east
    position.Position(file: F, rank: Seven) -> ray.f7_north_east
    position.Position(file: F, rank: Eight) -> ray.f8_north_east
    position.Position(file: G, rank: One) -> ray.g1_north_east
    position.Position(file: G, rank: Two) -> ray.g2_north_east
    position.Position(file: G, rank: Three) -> ray.g3_north_east
    position.Position(file: G, rank: Four) -> ray.g4_north_east
    position.Position(file: G, rank: Five) -> ray.g5_north_east
    position.Position(file: G, rank: Six) -> ray.g6_north_east
    position.Position(file: G, rank: Seven) -> ray.g7_north_east
    position.Position(file: G, rank: Eight) -> ray.g8_north_east
    position.Position(file: H, rank: One) -> ray.h1_north_east
    position.Position(file: H, rank: Two) -> ray.h2_north_east
    position.Position(file: H, rank: Three) -> ray.h3_north_east
    position.Position(file: H, rank: Four) -> ray.h4_north_east
    position.Position(file: H, rank: Five) -> ray.h5_north_east
    position.Position(file: H, rank: Six) -> ray.h6_north_east
    position.Position(file: H, rank: Seven) -> ray.h7_north_east
    position.Position(file: H, rank: Eight) -> ray.h8_north_east
  }
}

fn look_up_north_west_ray_bb(origin_square: Position) -> Bitboard {
  case origin_square {
    position.Position(file: A, rank: One) -> ray.a1_north_west
    position.Position(file: A, rank: Two) -> ray.a2_north_west
    position.Position(file: A, rank: Three) -> ray.a3_north_west
    position.Position(file: A, rank: Four) -> ray.a4_north_west
    position.Position(file: A, rank: Five) -> ray.a5_north_west
    position.Position(file: A, rank: Six) -> ray.a6_north_west
    position.Position(file: A, rank: Seven) -> ray.a7_north_west
    position.Position(file: A, rank: Eight) -> ray.a8_north_west
    position.Position(file: B, rank: One) -> ray.b1_north_west
    position.Position(file: B, rank: Two) -> ray.b2_north_west
    position.Position(file: B, rank: Three) -> ray.b3_north_west
    position.Position(file: B, rank: Four) -> ray.b4_north_west
    position.Position(file: B, rank: Five) -> ray.b5_north_west
    position.Position(file: B, rank: Six) -> ray.b6_north_west
    position.Position(file: B, rank: Seven) -> ray.b7_north_west
    position.Position(file: B, rank: Eight) -> ray.b8_north_west
    position.Position(file: C, rank: One) -> ray.c1_north_west
    position.Position(file: C, rank: Two) -> ray.c2_north_west
    position.Position(file: C, rank: Three) -> ray.c3_north_west
    position.Position(file: C, rank: Four) -> ray.c4_north_west
    position.Position(file: C, rank: Five) -> ray.c5_north_west
    position.Position(file: C, rank: Six) -> ray.c6_north_west
    position.Position(file: C, rank: Seven) -> ray.c7_north_west
    position.Position(file: C, rank: Eight) -> ray.c8_north_west
    position.Position(file: D, rank: One) -> ray.d1_north_west
    position.Position(file: D, rank: Two) -> ray.d2_north_west
    position.Position(file: D, rank: Three) -> ray.d3_north_west
    position.Position(file: D, rank: Four) -> ray.d4_north_west
    position.Position(file: D, rank: Five) -> ray.d5_north_west
    position.Position(file: D, rank: Six) -> ray.d6_north_west
    position.Position(file: D, rank: Seven) -> ray.d7_north_west
    position.Position(file: D, rank: Eight) -> ray.d8_north_west
    position.Position(file: E, rank: One) -> ray.e1_north_west
    position.Position(file: E, rank: Two) -> ray.e2_north_west
    position.Position(file: E, rank: Three) -> ray.e3_north_west
    position.Position(file: E, rank: Four) -> ray.e4_north_west
    position.Position(file: E, rank: Five) -> ray.e5_north_west
    position.Position(file: E, rank: Six) -> ray.e6_north_west
    position.Position(file: E, rank: Seven) -> ray.e7_north_west
    position.Position(file: E, rank: Eight) -> ray.e8_north_west
    position.Position(file: F, rank: One) -> ray.f1_north_west
    position.Position(file: F, rank: Two) -> ray.f2_north_west
    position.Position(file: F, rank: Three) -> ray.f3_north_west
    position.Position(file: F, rank: Four) -> ray.f4_north_west
    position.Position(file: F, rank: Five) -> ray.f5_north_west
    position.Position(file: F, rank: Six) -> ray.f6_north_west
    position.Position(file: F, rank: Seven) -> ray.f7_north_west
    position.Position(file: F, rank: Eight) -> ray.f8_north_west
    position.Position(file: G, rank: One) -> ray.g1_north_west
    position.Position(file: G, rank: Two) -> ray.g2_north_west
    position.Position(file: G, rank: Three) -> ray.g3_north_west
    position.Position(file: G, rank: Four) -> ray.g4_north_west
    position.Position(file: G, rank: Five) -> ray.g5_north_west
    position.Position(file: G, rank: Six) -> ray.g6_north_west
    position.Position(file: G, rank: Seven) -> ray.g7_north_west
    position.Position(file: G, rank: Eight) -> ray.g8_north_west
    position.Position(file: H, rank: One) -> ray.h1_north_west
    position.Position(file: H, rank: Two) -> ray.h2_north_west
    position.Position(file: H, rank: Three) -> ray.h3_north_west
    position.Position(file: H, rank: Four) -> ray.h4_north_west
    position.Position(file: H, rank: Five) -> ray.h5_north_west
    position.Position(file: H, rank: Six) -> ray.h6_north_west
    position.Position(file: H, rank: Seven) -> ray.h7_north_west
    position.Position(file: H, rank: Eight) -> ray.h8_north_west
  }
}

fn occupied_squares(board: BoardBB) -> Bitboard {
  let list_of_all_piece_bitboards = [
    board.white_king_bitboard,
    board.white_queen_bitboard,
    board.white_rook_bitboard,
    board.white_bishop_bitboard,
    board.white_knight_bitboard,
    board.white_pawns_bitboard,
    board.black_king_bitboard,
    board.black_queen_bitboard,
    board.black_rook_bitboard,
    board.black_bishop_bitboard,
    board.black_knight_bitboard,
    board.black_pawns_bitboard,
  ]

  list.fold(
    list_of_all_piece_bitboards,
    bitboard.Bitboard(bitboard: 0),
    fn(collector, next) { bitboard.or(collector, next) },
  )
}

fn occupied_squares_white(board: BoardBB) -> Bitboard {
  let list_of_all_piece_bitboards = [
    board.white_king_bitboard,
    board.white_queen_bitboard,
    board.white_rook_bitboard,
    board.white_bishop_bitboard,
    board.white_knight_bitboard,
    board.white_pawns_bitboard,
  ]

  list.fold(
    list_of_all_piece_bitboards,
    bitboard.Bitboard(bitboard: 0),
    fn(collector, next) { bitboard.or(collector, next) },
  )
}

fn occupied_squares_black(board: BoardBB) -> Bitboard {
  let list_of_all_piece_bitboards = [
    board.black_king_bitboard,
    board.black_queen_bitboard,
    board.black_rook_bitboard,
    board.black_bishop_bitboard,
    board.black_knight_bitboard,
    board.black_pawns_bitboard,
  ]

  list.fold(
    list_of_all_piece_bitboards,
    bitboard.Bitboard(bitboard: 0),
    fn(collector, next) { bitboard.or(collector, next) },
  )
}

fn pawn_squares(color: Color, board: BoardBB) -> Bitboard {
  case color {
    White -> board.white_pawns_bitboard
    Black -> board.black_pawns_bitboard
  }
}

fn generate_en_passant_pseudo_legal_move_list(
  color: Color,
  game_state: Game,
) -> List(Move) {
  case game_state.en_passant {
    None -> []
    Some(ep_position) -> {
      let ep_bitboard = position.to_bitboard(ep_position)
      let pawn_bitboard = pawn_squares(color, game_state.board)

      let ep_attacker_bitboard = case color {
        White -> {
          let west_east_attacker_bb =
            bitboard.and(
              bitboard.and(bitboard.shift_right(ep_bitboard, 7), pawn_bitboard),
              not_a_file,
            )
          let east_west_attacker_bb =
            bitboard.and(
              bitboard.and(bitboard.shift_right(ep_bitboard, 9), pawn_bitboard),
              not_h_file,
            )
          bitboard.or(west_east_attacker_bb, east_west_attacker_bb)
        }
        Black -> {
          let west_east_attacker_bb =
            bitboard.and(
              bitboard.and(bitboard.shift_left(ep_bitboard, 7), pawn_bitboard),
              not_h_file,
            )
          let east_west_attacker_bb =
            bitboard.and(
              bitboard.and(bitboard.shift_left(ep_bitboard, 9), pawn_bitboard),
              not_a_file,
            )
          bitboard.or(west_east_attacker_bb, east_west_attacker_bb)
        }
      }

      let ep_attacker_positions = board.get_positions(ep_attacker_bitboard)

      let ep_moves =
        list.map(
          ep_attacker_positions,
          fn(position) { move.EnPassant(from: position, to: ep_position) },
        )

      ep_moves
    }
  }
}

fn generate_castling_pseudo_legal_move_list(
  color: Color,
  game_state: Game,
) -> List(Move) {
  let king_bitboard = case color {
    White -> game_state.board.white_king_bitboard
    Black -> game_state.board.black_king_bitboard
  }

  let [king_position] = board.get_positions(king_bitboard)

  let king_position_flag = case king_position {
    position.Position(position.E, position.One) if color == White -> True
    position.Position(position.E, position.Eight) if color == Black -> True
    _ -> False
  }

  let rook_bitboard = case color {
    White -> game_state.board.white_rook_bitboard
    Black -> game_state.board.black_rook_bitboard
  }

  let queenside_rook_flag = case color {
    White ->
      case bitboard.and(bitboard.and(rook_bitboard, a_file), rank_1) {
        bitboard.Bitboard(bitboard: 0) -> False
        _ -> True
      }
    Black ->
      case bitboard.and(bitboard.and(rook_bitboard, a_file), rank_8) {
        bitboard.Bitboard(bitboard: 0) -> False
        _ -> True
      }
  }

  let kingside_rook_flag = case color {
    White ->
      case bitboard.and(bitboard.and(rook_bitboard, h_file), rank_1) {
        bitboard.Bitboard(bitboard: 0) -> False
        _ -> True
      }
    Black ->
      case bitboard.and(bitboard.and(rook_bitboard, h_file), rank_8) {
        bitboard.Bitboard(bitboard: 0) -> False
        _ -> True
      }
  }

  //check if there are no pieces between the king and the rook
  let queenside_clear_flag = case color {
    White ->
      case
        bitboard.and(
          bitboard.Bitboard(
            bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00001110,
          ),
          occupied_squares(game_state.board),
        )
      {
        bitboard.Bitboard(bitboard: 0) -> True
        _ -> False
      }
    Black ->
      case
        bitboard.and(
          bitboard.Bitboard(
            bitboard: 0b00001110_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
          ),
          occupied_squares(game_state.board),
        )
      {
        bitboard.Bitboard(bitboard: 0) -> True
        _ -> False
      }
  }

  let kingside_clear_flag = case color {
    White ->
      case
        bitboard.and(
          bitboard.Bitboard(
            bitboard: 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_01100000,
          ),
          occupied_squares(game_state.board),
        )
      {
        bitboard.Bitboard(bitboard: 0) -> True
        _ -> False
      }
    Black ->
      case
        bitboard.and(
          bitboard.Bitboard(
            bitboard: 0b01100000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
          ),
          occupied_squares(game_state.board),
        )
      {
        bitboard.Bitboard(bitboard: 0) -> True
        _ -> False
      }
  }

  //check if king still has castling rights on each side
  let queenside_castle = case color {
    White -> game_state.white_queen_castle
    Black -> game_state.black_queen_castle
  }

  let kingside_castle = case color {
    White -> game_state.white_king_castle
    Black -> game_state.black_king_castle
  }

  let castling_moves =
    list.append(
      case
        [
          queenside_castle,
          queenside_rook_flag,
          queenside_clear_flag,
          king_position_flag,
        ]
      {
        [True, True, True, True] ->
          case color {
            White -> [
              move.Castle(
                from: king_position,
                to: position.Position(position.C, position.One),
              ),
            ]
            Black -> [
              move.Castle(
                from: king_position,
                to: position.Position(position.C, position.Eight),
              ),
            ]
          }
        _ -> []
      },
      case
        [
          kingside_castle,
          kingside_rook_flag,
          kingside_clear_flag,
          king_position_flag,
        ]
      {
        [True, True, True, True] ->
          case color {
            White -> [
              move.Castle(
                from: king_position,
                to: position.Position(position.G, position.One),
              ),
            ]
            Black -> [
              move.Castle(
                from: king_position,
                to: position.Position(position.G, position.Eight),
              ),
            ]
          }
        _ -> []
      },
    )

  castling_moves
}

fn generate_king_pseudo_legal_move_list(
  color: Color,
  game_state: Game,
) -> List(Move) {
  let king_bitboard = case color {
    White -> game_state.board.white_king_bitboard
    Black -> game_state.board.black_king_bitboard
  }

  let king_origin_squares = board.get_positions(king_bitboard)

  list.fold(
    king_origin_squares,
    [],
    fn(collector, origin) {
      let king_bitboard = board.from_position(origin)
      let north_west_north_east_target_squares =
        bitboard.or(
          bitboard.and(bitboard.shift_left(king_bitboard, 9), not_a_file),
          bitboard.and(bitboard.shift_left(king_bitboard, 7), not_h_file),
        )

      let south_west_south_east_target_squares =
        bitboard.or(
          bitboard.and(bitboard.shift_right(king_bitboard, 9), not_h_file),
          bitboard.and(bitboard.shift_right(king_bitboard, 7), not_a_file),
        )

      let west_east_target_squares =
        bitboard.or(
          bitboard.and(bitboard.shift_left(king_bitboard, 1), not_a_file),
          bitboard.and(bitboard.shift_right(king_bitboard, 1), not_h_file),
        )

      let north_south_target_squares =
        bitboard.or(
          bitboard.shift_left(king_bitboard, 8),
          bitboard.shift_right(king_bitboard, 8),
        )

      let king_target_squares =
        bitboard.or(
          bitboard.or(
            north_west_north_east_target_squares,
            south_west_south_east_target_squares,
          ),
          bitboard.or(west_east_target_squares, north_south_target_squares),
        )

      let list_of_friendly_piece_bitboards = case color {
        White -> [
          game_state.board.white_king_bitboard,
          game_state.board.white_queen_bitboard,
          game_state.board.white_rook_bitboard,
          game_state.board.white_bishop_bitboard,
          game_state.board.white_knight_bitboard,
          game_state.board.white_pawns_bitboard,
        ]
        Black -> [
          game_state.board.black_king_bitboard,
          game_state.board.black_queen_bitboard,
          game_state.board.black_rook_bitboard,
          game_state.board.black_bishop_bitboard,
          game_state.board.black_knight_bitboard,
          game_state.board.black_pawns_bitboard,
        ]
      }

      let friendly_pieces =
        list.fold(
          list_of_friendly_piece_bitboards,
          bitboard.Bitboard(bitboard: 0),
          fn(collector, next) -> Bitboard { bitboard.or(collector, next) },
        )

      //Get bitboard for target squares that are not occupied by friendly pieces
      let king_unblocked_target_square_bb =
        bitboard.and(king_target_squares, bitboard.not(friendly_pieces))

      let captures = case color {
        White -> {
          //TODO: should probably add a occupied_squares_by_color function
          bitboard.and(
            king_unblocked_target_square_bb,
            occupied_squares_black(game_state.board),
          )
        }
        Black -> {
          bitboard.and(
            king_unblocked_target_square_bb,
            occupied_squares_white(game_state.board),
          )
        }
      }
      let simple_moves = case color {
        White -> {
          bitboard.exclusive_or(king_unblocked_target_square_bb, captures)
        }
        Black -> {
          bitboard.exclusive_or(king_unblocked_target_square_bb, captures)
        }
      }

      let simple_moves =
        list.map(
          board.get_positions(simple_moves),
          fn(dest) -> Move {
            move.Normal(from: origin, to: dest, captured: None, promotion: None)
          },
        )

      let captures =
        list.map(
          board.get_positions(captures),
          fn(dest) -> Move {
            move.Normal(
              from: origin,
              to: dest,
              captured: {
                let assert Some(piece) = piece_at_position(game_state, dest)
                Some(piece)
              },
              promotion: None,
            )
          },
        )
      let all_moves = list.append(simple_moves, captures)
      list.append(collector, all_moves)
    },
  )
}

fn generate_queen_pseudo_legal_move_list(
  color: Color,
  game_state: Game,
) -> List(Move) {
  let queen_bitboard = case color {
    White -> game_state.board.white_queen_bitboard
    Black -> game_state.board.black_queen_bitboard
  }

  let queen_origin_squares = board.get_positions(queen_bitboard)

  list.fold(
    queen_origin_squares,
    [],
    fn(collector, queen_origin_square) {
      let south_mask_bb = look_up_south_ray_bb(queen_origin_square)
      let east_mask_bb = look_up_east_ray_bb(queen_origin_square)
      let north_mask_bb = look_up_north_ray_bb(queen_origin_square)
      let west_mask_bb = look_up_west_ray_bb(queen_origin_square)

      let occupied_squares_bb = occupied_squares(game_state.board)

      let south_blockers_bb = bitboard.and(south_mask_bb, occupied_squares_bb)
      let east_blockers_bb = bitboard.and(east_mask_bb, occupied_squares_bb)
      let north_blockers_bb = bitboard.and(north_mask_bb, occupied_squares_bb)
      let west_blockers_bb = bitboard.and(west_mask_bb, occupied_squares_bb)

      let first_blocker_south =
        position.from_int(bitboard.bitscan_backward(south_blockers_bb))
      let first_blocker_east =
        position.from_int(bitboard.bitscan_forward(east_blockers_bb))
      let first_blocker_north =
        position.from_int(bitboard.bitscan_forward(north_blockers_bb))
      let first_blocker_west =
        position.from_int(bitboard.bitscan_backward(west_blockers_bb))

      let first_blocker_south_mask_bb = case first_blocker_south {
        None -> bitboard.Bitboard(bitboard: 0)
        Some(position) -> look_up_south_ray_bb(position)
      }
      let first_blocker_east_mask_bb = case first_blocker_east {
        None -> bitboard.Bitboard(bitboard: 0)
        Some(position) -> look_up_east_ray_bb(position)
      }
      let first_blocker_north_mask_bb = case first_blocker_north {
        None -> bitboard.Bitboard(bitboard: 0)
        Some(position) -> look_up_north_ray_bb(position)
      }
      let first_blocker_west_mask_bb = case first_blocker_west {
        None -> bitboard.Bitboard(bitboard: 0)
        Some(position) -> look_up_west_ray_bb(position)
      }

      //Here we create the rays of the bishop with only the first first blocker
      //included. Next we need to remove the first blocker from the ray
      //if its our own piece, and include it if its an enemy piece.
      let south_ray_bb_with_blocker =
        bitboard.exclusive_or(south_mask_bb, first_blocker_south_mask_bb)
      let east_ray_bb_with_blocker =
        bitboard.exclusive_or(east_mask_bb, first_blocker_east_mask_bb)
      let north_ray_bb_with_blocker =
        bitboard.exclusive_or(north_mask_bb, first_blocker_north_mask_bb)
      let west_ray_bb_with_blocker =
        bitboard.exclusive_or(west_mask_bb, first_blocker_west_mask_bb)

      //Here we remove the first blocker from the ray if its our own piece
      let south_ray_bb = case color {
        White -> {
          bitboard.and(
            south_ray_bb_with_blocker,
            bitboard.not(occupied_squares_white(game_state.board)),
          )
        }
        Black -> {
          bitboard.and(
            south_ray_bb_with_blocker,
            bitboard.not(occupied_squares_black(game_state.board)),
          )
        }
      }
      let east_ray_bb = case color {
        White -> {
          bitboard.and(
            east_ray_bb_with_blocker,
            bitboard.not(occupied_squares_white(game_state.board)),
          )
        }
        Black -> {
          bitboard.and(
            east_ray_bb_with_blocker,
            bitboard.not(occupied_squares_black(game_state.board)),
          )
        }
      }
      let north_ray_bb = case color {
        White -> {
          bitboard.and(
            north_ray_bb_with_blocker,
            bitboard.not(occupied_squares_white(game_state.board)),
          )
        }
        Black -> {
          bitboard.and(
            north_ray_bb_with_blocker,
            bitboard.not(occupied_squares_black(game_state.board)),
          )
        }
      }
      let west_ray_bb = case color {
        White -> {
          bitboard.and(
            west_ray_bb_with_blocker,
            bitboard.not(occupied_squares_white(game_state.board)),
          )
        }
        Black -> {
          bitboard.and(
            west_ray_bb_with_blocker,
            bitboard.not(occupied_squares_black(game_state.board)),
          )
        }
      }
      let rook_moves =
        list.fold(
          [south_ray_bb, east_ray_bb, north_ray_bb, west_ray_bb],
          [],
          fn(collector, next) {
            let captures = case color {
              White -> {
                //TODO: should probably add a occupied_squares_by_color function
                bitboard.and(next, occupied_squares_black(game_state.board))
              }
              Black -> {
                bitboard.and(next, occupied_squares_white(game_state.board))
              }
            }
            let rook_simple_moves = case color {
              White -> {
                bitboard.exclusive_or(next, captures)
              }
              Black -> {
                bitboard.exclusive_or(next, captures)
              }
            }

            let simple_moves =
              list.map(
                board.get_positions(rook_simple_moves),
                fn(dest) -> Move {
                  move.Normal(
                    from: queen_origin_square,
                    to: dest,
                    captured: None,
                    promotion: None,
                  )
                },
              )

            let captures =
              list.map(
                board.get_positions(captures),
                fn(dest) -> Move {
                  move.Normal(
                    from: queen_origin_square,
                    to: dest,
                    captured: {
                      let assert Some(piece) =
                        piece_at_position(game_state, dest)
                      Some(piece)
                    },
                    promotion: None,
                  )
                },
              )
            let simple_moves = list.append(collector, simple_moves)
            let all_moves = list.append(simple_moves, captures)
            all_moves
          },
        )

      let bishop_moves =
        list.fold(
          queen_origin_squares,
          [],
          fn(collector, queen_origin_square) {
            let south_west_mask_bb =
              look_up_south_west_ray_bb(queen_origin_square)
            let south_east_mask_bb =
              look_up_south_east_ray_bb(queen_origin_square)
            let north_east_mask_bb =
              look_up_north_east_ray_bb(queen_origin_square)
            let north_west_mask_bb =
              look_up_north_west_ray_bb(queen_origin_square)

            let occupied_squares_bb = occupied_squares(game_state.board)

            let south_west_blockers_bb =
              bitboard.and(south_west_mask_bb, occupied_squares_bb)
            let south_east_blockers_bb =
              bitboard.and(south_east_mask_bb, occupied_squares_bb)
            let north_east_blockers_bb =
              bitboard.and(north_east_mask_bb, occupied_squares_bb)
            let north_west_blockers_bb =
              bitboard.and(north_west_mask_bb, occupied_squares_bb)

            let first_blocker_south_west =
              position.from_int(bitboard.bitscan_backward(
                south_west_blockers_bb,
              ))
            let first_blocker_south_east =
              position.from_int(bitboard.bitscan_backward(
                south_east_blockers_bb,
              ))
            let first_blocker_north_east =
              position.from_int(bitboard.bitscan_forward(north_east_blockers_bb))
            let first_blocker_north_west =
              position.from_int(bitboard.bitscan_forward(north_west_blockers_bb))

            let first_blocker_south_west_mask_bb = case
              first_blocker_south_west
            {
              None -> bitboard.Bitboard(bitboard: 0)
              Some(position) -> look_up_south_west_ray_bb(position)
            }
            let first_blocker_south_east_mask_bb = case
              first_blocker_south_east
            {
              None -> bitboard.Bitboard(bitboard: 0)
              Some(position) -> look_up_south_east_ray_bb(position)
            }
            let first_blocker_north_east_mask_bb = case
              first_blocker_north_east
            {
              None -> bitboard.Bitboard(bitboard: 0)
              Some(position) -> look_up_north_east_ray_bb(position)
            }
            let first_blocker_north_west_mask_bb = case
              first_blocker_north_west
            {
              None -> bitboard.Bitboard(bitboard: 0)
              Some(position) -> look_up_north_west_ray_bb(position)
            }

            //Here we create the rays of the bishop with only the first first blocker
            //included. Next we need to remove the first blocker from the ray
            //if its our own piece, and include it if its an enemy piece.
            let south_west_ray_bb_with_blocker =
              bitboard.exclusive_or(
                south_west_mask_bb,
                first_blocker_south_west_mask_bb,
              )
            let south_east_ray_bb_with_blocker =
              bitboard.exclusive_or(
                south_east_mask_bb,
                first_blocker_south_east_mask_bb,
              )
            let north_east_ray_bb_with_blocker =
              bitboard.exclusive_or(
                north_east_mask_bb,
                first_blocker_north_east_mask_bb,
              )
            let north_west_ray_bb_with_blocker =
              bitboard.exclusive_or(
                north_west_mask_bb,
                first_blocker_north_west_mask_bb,
              )

            //Here we remove the first blocker from the ray if its our own piece
            let south_west_ray_bb = case color {
              White -> {
                bitboard.and(
                  south_west_ray_bb_with_blocker,
                  bitboard.not(occupied_squares_white(game_state.board)),
                )
              }
              Black -> {
                bitboard.and(
                  south_west_ray_bb_with_blocker,
                  bitboard.not(occupied_squares_black(game_state.board)),
                )
              }
            }
            let south_east_ray_bb = case color {
              White -> {
                bitboard.and(
                  south_east_ray_bb_with_blocker,
                  bitboard.not(occupied_squares_white(game_state.board)),
                )
              }
              Black -> {
                bitboard.and(
                  south_east_ray_bb_with_blocker,
                  bitboard.not(occupied_squares_black(game_state.board)),
                )
              }
            }
            let north_east_ray_bb = case color {
              White -> {
                bitboard.and(
                  north_east_ray_bb_with_blocker,
                  bitboard.not(occupied_squares_white(game_state.board)),
                )
              }
              Black -> {
                bitboard.and(
                  north_east_ray_bb_with_blocker,
                  bitboard.not(occupied_squares_black(game_state.board)),
                )
              }
            }
            let north_west_ray_bb = case color {
              White -> {
                bitboard.and(
                  north_west_ray_bb_with_blocker,
                  bitboard.not(occupied_squares_white(game_state.board)),
                )
              }
              Black -> {
                bitboard.and(
                  north_west_ray_bb_with_blocker,
                  bitboard.not(occupied_squares_black(game_state.board)),
                )
              }
            }
            let bishop_moves =
              list.fold(
                [
                  south_west_ray_bb,
                  south_east_ray_bb,
                  north_east_ray_bb,
                  north_west_ray_bb,
                ],
                [],
                fn(collector, next) {
                  let captures = case color {
                    White -> {
                      //TODO: should probably add a occupied_squares_by_color function
                      bitboard.and(
                        next,
                        occupied_squares_black(game_state.board),
                      )
                    }
                    Black -> {
                      bitboard.and(
                        next,
                        occupied_squares_white(game_state.board),
                      )
                    }
                  }
                  let rook_simple_moves = case color {
                    White -> {
                      bitboard.exclusive_or(next, captures)
                    }
                    Black -> {
                      bitboard.exclusive_or(next, captures)
                    }
                  }

                  let simple_moves =
                    list.map(
                      board.get_positions(rook_simple_moves),
                      fn(dest) -> Move {
                        move.Normal(
                          from: queen_origin_square,
                          to: dest,
                          captured: None,
                          promotion: None,
                        )
                      },
                    )

                  let captures =
                    list.map(
                      board.get_positions(captures),
                      fn(dest) -> Move {
                        move.Normal(
                          from: queen_origin_square,
                          to: dest,
                          captured: {
                            let assert Some(piece) =
                              piece_at_position(game_state, dest)
                            Some(piece)
                          },
                          promotion: None,
                        )
                      },
                    )
                  let simple_moves = list.append(collector, simple_moves)
                  let all_moves = list.append(simple_moves, captures)
                  all_moves
                },
              )
            list.append(collector, bishop_moves)
          },
        )
      list.append(list.append(collector, rook_moves), bishop_moves)
    },
  )
}

fn generate_rook_pseudo_legal_move_list(
  color: Color,
  game_state: Game,
) -> List(Move) {
  let rook_bitboard = case color {
    White -> game_state.board.white_rook_bitboard
    Black -> game_state.board.black_rook_bitboard
  }

  let rook_origin_squares = board.get_positions(rook_bitboard)

  list.fold(
    rook_origin_squares,
    [],
    fn(collector, rook_origin_square) {
      let south_mask_bb = look_up_south_ray_bb(rook_origin_square)
      let east_mask_bb = look_up_east_ray_bb(rook_origin_square)
      let north_mask_bb = look_up_north_ray_bb(rook_origin_square)
      let west_mask_bb = look_up_west_ray_bb(rook_origin_square)

      let occupied_squares_bb = occupied_squares(game_state.board)

      let south_blockers_bb = bitboard.and(south_mask_bb, occupied_squares_bb)
      let east_blockers_bb = bitboard.and(east_mask_bb, occupied_squares_bb)
      let north_blockers_bb = bitboard.and(north_mask_bb, occupied_squares_bb)
      let west_blockers_bb = bitboard.and(west_mask_bb, occupied_squares_bb)

      let first_blocker_south =
        position.from_int(bitboard.bitscan_backward(south_blockers_bb))
      let first_blocker_east =
        position.from_int(bitboard.bitscan_forward(east_blockers_bb))
      let first_blocker_north =
        position.from_int(bitboard.bitscan_forward(north_blockers_bb))
      let first_blocker_west =
        position.from_int(bitboard.bitscan_backward(west_blockers_bb))

      let first_blocker_south_mask_bb = case first_blocker_south {
        None -> bitboard.Bitboard(bitboard: 0)
        Some(position) -> look_up_south_ray_bb(position)
      }
      let first_blocker_east_mask_bb = case first_blocker_east {
        None -> bitboard.Bitboard(bitboard: 0)
        Some(position) -> look_up_east_ray_bb(position)
      }
      let first_blocker_north_mask_bb = case first_blocker_north {
        None -> bitboard.Bitboard(bitboard: 0)
        Some(position) -> look_up_north_ray_bb(position)
      }
      let first_blocker_west_mask_bb = case first_blocker_west {
        None -> bitboard.Bitboard(bitboard: 0)
        Some(position) -> look_up_west_ray_bb(position)
      }

      //Here we create the rays of the bishop with only the first first blocker
      //included. Next we need to remove the first blocker from the ray
      //if its our own piece, and include it if its an enemy piece.
      let south_ray_bb_with_blocker =
        bitboard.exclusive_or(south_mask_bb, first_blocker_south_mask_bb)
      let east_ray_bb_with_blocker =
        bitboard.exclusive_or(east_mask_bb, first_blocker_east_mask_bb)
      let north_ray_bb_with_blocker =
        bitboard.exclusive_or(north_mask_bb, first_blocker_north_mask_bb)
      let west_ray_bb_with_blocker =
        bitboard.exclusive_or(west_mask_bb, first_blocker_west_mask_bb)

      //Here we remove the first blocker from the ray if its our own piece
      let south_ray_bb = case color {
        White -> {
          bitboard.and(
            south_ray_bb_with_blocker,
            bitboard.not(occupied_squares_white(game_state.board)),
          )
        }
        Black -> {
          bitboard.and(
            south_ray_bb_with_blocker,
            bitboard.not(occupied_squares_black(game_state.board)),
          )
        }
      }
      let east_ray_bb = case color {
        White -> {
          bitboard.and(
            east_ray_bb_with_blocker,
            bitboard.not(occupied_squares_white(game_state.board)),
          )
        }
        Black -> {
          bitboard.and(
            east_ray_bb_with_blocker,
            bitboard.not(occupied_squares_black(game_state.board)),
          )
        }
      }
      let north_ray_bb = case color {
        White -> {
          bitboard.and(
            north_ray_bb_with_blocker,
            bitboard.not(occupied_squares_white(game_state.board)),
          )
        }
        Black -> {
          bitboard.and(
            north_ray_bb_with_blocker,
            bitboard.not(occupied_squares_black(game_state.board)),
          )
        }
      }
      let west_ray_bb = case color {
        White -> {
          bitboard.and(
            west_ray_bb_with_blocker,
            bitboard.not(occupied_squares_white(game_state.board)),
          )
        }
        Black -> {
          bitboard.and(
            west_ray_bb_with_blocker,
            bitboard.not(occupied_squares_black(game_state.board)),
          )
        }
      }
      let rook_moves =
        list.fold(
          [south_ray_bb, east_ray_bb, north_ray_bb, west_ray_bb],
          [],
          fn(collector, next) {
            let rook_captures = case color {
              White -> {
                //TODO: should probably add a occupied_squares_by_color function
                bitboard.and(next, occupied_squares_black(game_state.board))
              }
              Black -> {
                bitboard.and(next, occupied_squares_white(game_state.board))
              }
            }
            let rook_simple_moves = case color {
              White -> {
                bitboard.exclusive_or(next, rook_captures)
              }
              Black -> {
                bitboard.exclusive_or(next, rook_captures)
              }
            }

            let simple_moves =
              list.map(
                board.get_positions(rook_simple_moves),
                fn(dest) -> Move {
                  move.Normal(
                    from: rook_origin_square,
                    to: dest,
                    captured: None,
                    promotion: None,
                  )
                },
              )

            let captures =
              list.map(
                board.get_positions(rook_captures),
                fn(dest) -> Move {
                  move.Normal(
                    from: rook_origin_square,
                    to: dest,
                    captured: {
                      let assert Some(piece) =
                        piece_at_position(game_state, dest)
                      Some(piece)
                    },
                    promotion: None,
                  )
                },
              )
            let simple_moves = list.append(collector, simple_moves)
            let all_moves = list.append(simple_moves, captures)
            all_moves
          },
        )
      list.append(collector, rook_moves)
    },
  )
}

fn piece_at_position(
  game_state: Game,
  position: Position,
) -> Option(piece.Piece) {
  let position_bb_masked =
    bitboard.and(
      position.to_bitboard(position),
      occupied_squares(game_state.board),
    )

  let position_white_king =
    bitboard.and(position_bb_masked, game_state.board.white_king_bitboard)
  let position_white_queen =
    bitboard.and(position_bb_masked, game_state.board.white_queen_bitboard)
  let position_white_rook =
    bitboard.and(position_bb_masked, game_state.board.white_rook_bitboard)
  let position_white_bishop =
    bitboard.and(position_bb_masked, game_state.board.white_bishop_bitboard)
  let position_white_knight =
    bitboard.and(position_bb_masked, game_state.board.white_knight_bitboard)
  let position_white_pawn =
    bitboard.and(position_bb_masked, game_state.board.white_pawns_bitboard)
  let position_black_king =
    bitboard.and(position_bb_masked, game_state.board.black_king_bitboard)
  let position_black_queen =
    bitboard.and(position_bb_masked, game_state.board.black_queen_bitboard)
  let position_black_rook =
    bitboard.and(position_bb_masked, game_state.board.black_rook_bitboard)
  let position_black_bishop =
    bitboard.and(position_bb_masked, game_state.board.black_bishop_bitboard)
  let position_black_knight =
    bitboard.and(position_bb_masked, game_state.board.black_knight_bitboard)
  let position_black_pawn =
    bitboard.and(position_bb_masked, game_state.board.black_pawns_bitboard)

  case position_bb_masked {
    bitboard.Bitboard(bitboard: 0) -> option.None
    _ if position_white_king.bitboard != 0 ->
      option.Some(piece.Piece(White, King))
    _ if position_white_queen.bitboard != 0 ->
      option.Some(piece.Piece(White, Queen))
    _ if position_white_rook.bitboard != 0 ->
      option.Some(piece.Piece(White, Rook))
    _ if position_white_bishop.bitboard != 0 ->
      option.Some(piece.Piece(White, Bishop))
    _ if position_white_knight.bitboard != 0 ->
      option.Some(piece.Piece(White, Knight))
    _ if position_white_pawn.bitboard != 0 ->
      option.Some(piece.Piece(White, Pawn))
    _ if position_black_king.bitboard != 0 ->
      option.Some(piece.Piece(Black, King))
    _ if position_black_queen.bitboard != 0 ->
      option.Some(piece.Piece(Black, Queen))
    _ if position_black_rook.bitboard != 0 ->
      option.Some(piece.Piece(Black, Rook))
    _ if position_black_bishop.bitboard != 0 ->
      option.Some(piece.Piece(Black, Bishop))
    _ if position_black_knight.bitboard != 0 ->
      option.Some(piece.Piece(Black, Knight))
    _ if position_black_pawn.bitboard != 0 ->
      option.Some(piece.Piece(Black, Pawn))
  }
}

fn generate_bishop_pseudo_legal_move_list(
  color: Color,
  game_state: Game,
) -> List(Move) {
  let bishop_bitboard = case color {
    White -> game_state.board.white_bishop_bitboard
    Black -> game_state.board.black_bishop_bitboard
  }

  let bishop_origin_squares = board.get_positions(bishop_bitboard)

  list.fold(
    bishop_origin_squares,
    [],
    fn(collector, bishop_origin_square) {
      let south_west_mask_bb = look_up_south_west_ray_bb(bishop_origin_square)
      let south_east_mask_bb = look_up_south_east_ray_bb(bishop_origin_square)
      let north_east_mask_bb = look_up_north_east_ray_bb(bishop_origin_square)
      let north_west_mask_bb = look_up_north_west_ray_bb(bishop_origin_square)

      let occupied_squares_bb = occupied_squares(game_state.board)

      let south_west_blockers_bb =
        bitboard.and(south_west_mask_bb, occupied_squares_bb)
      let south_east_blockers_bb =
        bitboard.and(south_east_mask_bb, occupied_squares_bb)
      let north_east_blockers_bb =
        bitboard.and(north_east_mask_bb, occupied_squares_bb)
      let north_west_blockers_bb =
        bitboard.and(north_west_mask_bb, occupied_squares_bb)

      let first_blocker_south_west =
        position.from_int(bitboard.bitscan_backward(south_west_blockers_bb))
      let first_blocker_south_east =
        position.from_int(bitboard.bitscan_backward(south_east_blockers_bb))
      let first_blocker_north_east =
        position.from_int(bitboard.bitscan_forward(north_east_blockers_bb))
      let first_blocker_north_west =
        position.from_int(bitboard.bitscan_forward(north_west_blockers_bb))

      let first_blocker_south_west_mask_bb = case first_blocker_south_west {
        None -> bitboard.Bitboard(bitboard: 0)
        Some(position) -> look_up_south_west_ray_bb(position)
      }
      let first_blocker_south_east_mask_bb = case first_blocker_south_east {
        None -> bitboard.Bitboard(bitboard: 0)
        Some(position) -> look_up_south_east_ray_bb(position)
      }
      let first_blocker_north_east_mask_bb = case first_blocker_north_east {
        None -> bitboard.Bitboard(bitboard: 0)
        Some(position) -> look_up_north_east_ray_bb(position)
      }
      let first_blocker_north_west_mask_bb = case first_blocker_north_west {
        None -> bitboard.Bitboard(bitboard: 0)
        Some(position) -> look_up_north_west_ray_bb(position)
      }

      //Here we create the rays of the bishop with only the first first blocker
      //included. Next we need to remove the first blocker from the ray
      //if its our own piece, and include it if its an enemy piece.
      let south_west_ray_bb_with_blocker =
        bitboard.exclusive_or(
          south_west_mask_bb,
          first_blocker_south_west_mask_bb,
        )
      let south_east_ray_bb_with_blocker =
        bitboard.exclusive_or(
          south_east_mask_bb,
          first_blocker_south_east_mask_bb,
        )
      let north_east_ray_bb_with_blocker =
        bitboard.exclusive_or(
          north_east_mask_bb,
          first_blocker_north_east_mask_bb,
        )
      let north_west_ray_bb_with_blocker =
        bitboard.exclusive_or(
          north_west_mask_bb,
          first_blocker_north_west_mask_bb,
        )

      //Here we remove the first blocker from the ray if its our own piece
      let south_west_ray_bb = case color {
        White -> {
          bitboard.and(
            south_west_ray_bb_with_blocker,
            bitboard.not(occupied_squares_white(game_state.board)),
          )
        }
        Black -> {
          bitboard.and(
            south_west_ray_bb_with_blocker,
            bitboard.not(occupied_squares_black(game_state.board)),
          )
        }
      }
      let south_east_ray_bb = case color {
        White -> {
          bitboard.and(
            south_east_ray_bb_with_blocker,
            bitboard.not(occupied_squares_white(game_state.board)),
          )
        }
        Black -> {
          bitboard.and(
            south_east_ray_bb_with_blocker,
            bitboard.not(occupied_squares_black(game_state.board)),
          )
        }
      }
      let north_east_ray_bb = case color {
        White -> {
          bitboard.and(
            north_east_ray_bb_with_blocker,
            bitboard.not(occupied_squares_white(game_state.board)),
          )
        }
        Black -> {
          bitboard.and(
            north_east_ray_bb_with_blocker,
            bitboard.not(occupied_squares_black(game_state.board)),
          )
        }
      }
      let north_west_ray_bb = case color {
        White -> {
          bitboard.and(
            north_west_ray_bb_with_blocker,
            bitboard.not(occupied_squares_white(game_state.board)),
          )
        }
        Black -> {
          bitboard.and(
            north_west_ray_bb_with_blocker,
            bitboard.not(occupied_squares_black(game_state.board)),
          )
        }
      }
      let bishop_moves =
        list.fold(
          [
            south_west_ray_bb,
            south_east_ray_bb,
            north_east_ray_bb,
            north_west_ray_bb,
          ],
          [],
          fn(collector, next) {
            let captures = case color {
              White -> {
                //TODO: should probably add a occupied_squares_by_color function
                bitboard.and(next, occupied_squares_black(game_state.board))
              }
              Black -> {
                bitboard.and(next, occupied_squares_white(game_state.board))
              }
            }
            let rook_simple_moves = case color {
              White -> {
                bitboard.exclusive_or(next, captures)
              }
              Black -> {
                bitboard.exclusive_or(next, captures)
              }
            }

            let simple_moves =
              list.map(
                board.get_positions(rook_simple_moves),
                fn(dest) -> Move {
                  move.Normal(
                    from: bishop_origin_square,
                    to: dest,
                    captured: None,
                    promotion: None,
                  )
                },
              )

            let captures =
              list.map(
                board.get_positions(captures),
                fn(dest) -> Move {
                  move.Normal(
                    from: bishop_origin_square,
                    to: dest,
                    captured: {
                      let assert Some(piece) =
                        piece_at_position(game_state, dest)
                      Some(piece)
                    },
                    promotion: None,
                  )
                },
              )
            let simple_moves = list.append(collector, simple_moves)
            let all_moves = list.append(simple_moves, captures)
            all_moves
          },
        )
      list.append(collector, bishop_moves)
    },
  )
}

fn generate_knight_pseudo_legal_move_list(
  color: Color,
  game_state: Game,
) -> List(Move) {
  let knight_bitboard = case color {
    White -> game_state.board.white_knight_bitboard
    Black -> game_state.board.black_knight_bitboard
  }

  let knight_origin_squares = board.get_positions(knight_bitboard)

  list.fold(
    knight_origin_squares,
    [],
    fn(collector, origin) {
      let knight_bitboard = board.from_position(origin)
      let north_target_squares =
        bitboard.or(
          bitboard.and(bitboard.shift_left(knight_bitboard, 17), not_a_file),
          bitboard.and(bitboard.shift_left(knight_bitboard, 15), not_h_file),
        )

      let south_target_squares =
        bitboard.or(
          bitboard.and(bitboard.shift_right(knight_bitboard, 17), not_h_file),
          bitboard.and(bitboard.shift_right(knight_bitboard, 15), not_a_file),
        )

      let west_target_squares =
        bitboard.or(
          bitboard.and(
            bitboard.and(bitboard.shift_right(knight_bitboard, 10), not_h_file),
            not_g_file,
          ),
          bitboard.and(
            bitboard.and(bitboard.shift_left(knight_bitboard, 6), not_h_file),
            not_g_file,
          ),
        )

      let east_target_squares =
        bitboard.or(
          bitboard.and(
            bitboard.and(bitboard.shift_right(knight_bitboard, 6), not_a_file),
            not_b_file,
          ),
          bitboard.and(
            bitboard.and(bitboard.shift_left(knight_bitboard, 10), not_a_file),
            not_b_file,
          ),
        )

      let knight_target_squares =
        bitboard.or(
          bitboard.or(north_target_squares, south_target_squares),
          bitboard.or(west_target_squares, east_target_squares),
        )

      let list_of_friendly_piece_bitboards = case color {
        White -> [
          game_state.board.white_king_bitboard,
          game_state.board.white_queen_bitboard,
          game_state.board.white_rook_bitboard,
          game_state.board.white_bishop_bitboard,
          game_state.board.white_knight_bitboard,
          game_state.board.white_pawns_bitboard,
        ]
        Black -> [
          game_state.board.black_king_bitboard,
          game_state.board.black_queen_bitboard,
          game_state.board.black_rook_bitboard,
          game_state.board.black_bishop_bitboard,
          game_state.board.black_knight_bitboard,
          game_state.board.black_pawns_bitboard,
        ]
      }

      let friendly_pieces =
        list.fold(
          list_of_friendly_piece_bitboards,
          bitboard.Bitboard(bitboard: 0),
          fn(collector, next) -> Bitboard { bitboard.or(collector, next) },
        )

      //Get bitboard for target squares that are not occupied by friendly pieces
      let knight_unblocked_target_square_bb =
        bitboard.and(knight_target_squares, bitboard.not(friendly_pieces))

      let captures = case color {
        White -> {
          //TODO: should probably add a occupied_squares_by_color function
          bitboard.and(
            knight_unblocked_target_square_bb,
            occupied_squares_black(game_state.board),
          )
        }
        Black -> {
          bitboard.and(
            knight_unblocked_target_square_bb,
            occupied_squares_white(game_state.board),
          )
        }
      }
      let simple_moves = case color {
        White -> {
          bitboard.exclusive_or(knight_unblocked_target_square_bb, captures)
        }
        Black -> {
          bitboard.exclusive_or(knight_unblocked_target_square_bb, captures)
        }
      }

      let simple_moves =
        list.map(
          board.get_positions(simple_moves),
          fn(dest) -> Move {
            move.Normal(from: origin, to: dest, captured: None, promotion: None)
          },
        )

      let captures =
        list.map(
          board.get_positions(captures),
          fn(dest) -> Move {
            move.Normal(
              from: origin,
              to: dest,
              captured: {
                let assert Some(piece) = piece_at_position(game_state, dest)
                Some(piece)
              },
              promotion: None,
            )
          },
        )
      let all_moves = list.append(simple_moves, captures)
      list.append(collector, all_moves)
    },
  )
}

fn generate_pawn_pseudo_legal_move_list(
  color: Color,
  game_state: Game,
) -> List(Move) {
  let capture_list = generate_pawn_capture_move_list(color, game_state)
  let moves_no_captures =
    generate_pawn_non_capture_move_bitboard(color, game_state)

  let non_capture_dest_list = board.get_positions(moves_no_captures)

  let non_capture_move_list =
    list.fold(
      non_capture_dest_list,
      [],
      fn(acc, dest) -> List(Move) {
        let origin = position.get_rear_position(dest, color)
        let moves = case dest {
          position.Position(file: _, rank: position.Eight) if color == White -> {
            [
              move.Normal(
                from: origin,
                to: dest,
                captured: None,
                promotion: Some(piece.Piece(color, Queen)),
              ),
              move.Normal(
                from: origin,
                to: dest,
                captured: None,
                promotion: Some(piece.Piece(color, Rook)),
              ),
              move.Normal(
                from: origin,
                to: dest,
                captured: None,
                promotion: Some(piece.Piece(color, Bishop)),
              ),
              move.Normal(
                from: origin,
                to: dest,
                captured: None,
                promotion: Some(piece.Piece(color, Knight)),
              ),
            ]
          }
          position.Position(file: _, rank: position.One) if color == Black -> {
            [
              move.Normal(
                from: origin,
                to: dest,
                captured: None,
                promotion: Some(piece.Piece(color, Queen)),
              ),
              move.Normal(
                from: origin,
                to: dest,
                captured: None,
                promotion: Some(piece.Piece(color, Rook)),
              ),
              move.Normal(
                from: origin,
                to: dest,
                captured: None,
                promotion: Some(piece.Piece(color, Bishop)),
              ),
              move.Normal(
                from: origin,
                to: dest,
                captured: None,
                promotion: Some(piece.Piece(color, Knight)),
              ),
            ]
          }
          _ -> {
            [
              move.Normal(
                from: origin,
                to: dest,
                captured: None,
                promotion: None,
              ),
            ]
          }
        }
        list.append(acc, moves)
      },
    )

  let initial_rank_double_move_list =
    generate_pawn_starting_rank_double_move_bitboard(color, game_state)

  let initial_rank_double_dest_list =
    board.get_positions(initial_rank_double_move_list)

  let initial_rank_double_move_list =
    list.map(
      initial_rank_double_dest_list,
      fn(dest) -> Move {
        case color {
          White -> {
            case dest.file {
              position.A ->
                move.Normal(
                  from: position.Position(file: position.A, rank: position.Two),
                  to: dest,
                  captured: None,
                  promotion: None,
                )
              position.B -> {
                move.Normal(
                  from: position.Position(file: position.B, rank: position.Two),
                  to: dest,
                  captured: None,
                  promotion: None,
                )
              }
              position.C -> {
                move.Normal(
                  from: position.Position(file: position.C, rank: position.Two),
                  to: dest,
                  captured: None,
                  promotion: None,
                )
              }
              position.D -> {
                move.Normal(
                  from: position.Position(file: position.D, rank: position.Two),
                  to: dest,
                  captured: None,
                  promotion: None,
                )
              }
              position.E -> {
                move.Normal(
                  from: position.Position(file: position.E, rank: position.Two),
                  to: dest,
                  captured: None,
                  promotion: None,
                )
              }
              position.F -> {
                move.Normal(
                  from: position.Position(file: position.F, rank: position.Two),
                  to: dest,
                  captured: None,
                  promotion: None,
                )
              }
              position.G -> {
                move.Normal(
                  from: position.Position(file: position.G, rank: position.Two),
                  to: dest,
                  captured: None,
                  promotion: None,
                )
              }
              position.H -> {
                move.Normal(
                  from: position.Position(file: position.H, rank: position.Two),
                  to: dest,
                  captured: None,
                  promotion: None,
                )
              }
            }
          }

          Black -> {
            case dest.file {
              position.A ->
                move.Normal(
                  from: position.Position(
                    file: position.A,
                    rank: position.Seven,
                  ),
                  to: dest,
                  captured: None,
                  promotion: None,
                )
              position.B -> {
                move.Normal(
                  from: position.Position(
                    file: position.B,
                    rank: position.Seven,
                  ),
                  to: dest,
                  captured: None,
                  promotion: None,
                )
              }
              position.C -> {
                move.Normal(
                  from: position.Position(
                    file: position.C,
                    rank: position.Seven,
                  ),
                  to: dest,
                  captured: None,
                  promotion: None,
                )
              }
              position.D -> {
                move.Normal(
                  from: position.Position(
                    file: position.D,
                    rank: position.Seven,
                  ),
                  to: dest,
                  captured: None,
                  promotion: None,
                )
              }
              position.E -> {
                move.Normal(
                  from: position.Position(
                    file: position.E,
                    rank: position.Seven,
                  ),
                  to: dest,
                  captured: None,
                  promotion: None,
                )
              }
              position.F -> {
                move.Normal(
                  from: position.Position(
                    file: position.F,
                    rank: position.Seven,
                  ),
                  to: dest,
                  captured: None,
                  promotion: None,
                )
              }
              position.G -> {
                move.Normal(
                  from: position.Position(
                    file: position.G,
                    rank: position.Seven,
                  ),
                  to: dest,
                  captured: None,
                  promotion: None,
                )
              }
              position.H -> {
                move.Normal(
                  from: position.Position(
                    file: position.H,
                    rank: position.Seven,
                  ),
                  to: dest,
                  captured: None,
                  promotion: None,
                )
              }
            }
          }
        }
      },
    )

  list.append(
    list.append(capture_list, non_capture_move_list),
    initial_rank_double_move_list,
  )
}

fn generate_pawn_starting_rank_double_move_bitboard(
  color: Color,
  game_state: Game,
) -> bitboard.Bitboard {
  case color {
    White -> {
      let white_pawn_target_squares =
        bitboard.and(game_state.board.white_pawns_bitboard, rank_2)

      let white_pawn_target_squares =
        bitboard.or(
          bitboard.shift_left(white_pawn_target_squares, 16),
          bitboard.shift_left(white_pawn_target_squares, 8),
        )

      let occupied_squares = occupied_squares(game_state.board)

      let moves = bitboard.and(occupied_squares, white_pawn_target_squares)
      let moves =
        bitboard.or(bitboard.shift_left(bitboard.and(moves, rank_3), 8), moves)
      let moves = bitboard.exclusive_or(moves, white_pawn_target_squares)
      let moves = bitboard.and(moves, bitboard.not(rank_3))
      moves
    }
    Black -> {
      let black_pawn_target_squares =
        bitboard.and(game_state.board.black_pawns_bitboard, rank_7)

      let black_pawn_target_squares =
        bitboard.or(
          bitboard.shift_right(black_pawn_target_squares, 16),
          bitboard.shift_right(black_pawn_target_squares, 8),
        )

      let occupied_squares = occupied_squares(game_state.board)

      let moves = bitboard.and(occupied_squares, black_pawn_target_squares)
      let moves =
        bitboard.or(bitboard.shift_right(bitboard.and(moves, rank_6), 8), moves)
      let moves = bitboard.exclusive_or(moves, black_pawn_target_squares)
      let moves = bitboard.and(moves, bitboard.not(rank_6))
      moves
    }
  }
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

      let occupied_squares_white = occupied_squares_white(game_state.board)

      let enemy_pieces =
        list.fold(
          list_of_enemy_piece_bitboards,
          bitboard.Bitboard(bitboard: 0),
          fn(collector, next) -> Bitboard { bitboard.or(collector, next) },
        )
      let moves = bitboard.exclusive_or(white_pawn_target_squares, enemy_pieces)
      let moves = bitboard.and(moves, white_pawn_target_squares)
      let moves = bitboard.and(moves, bitboard.not(occupied_squares_white))
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

      let occupied_squares_black = occupied_squares_black(game_state.board)

      let enemy_pieces =
        list.fold(
          list_of_enemy_piece_bitboards,
          bitboard.Bitboard(bitboard: 0),
          fn(collector, next) { bitboard.or(collector, next) },
        )
      let moves = bitboard.exclusive_or(black_pawn_target_squares, enemy_pieces)
      let moves = bitboard.and(moves, black_pawn_target_squares)
      let moves = bitboard.and(moves, bitboard.not(occupied_squares_black))
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
      fn(collector, next) { bitboard.or(collector, next) },
    )
  let pawn_capture_destination_set = bitboard.and(pawn_attack_set, enemy_pieces)

  let [east_origins, west_origins] = case color {
    White -> {
      let east_origins =
        bitboard.and(
          bitboard.shift_right(pawn_capture_destination_set, 9),
          not_h_file,
        )
      let west_origins =
        bitboard.and(
          bitboard.shift_right(pawn_capture_destination_set, 7),
          not_a_file,
        )
      [
        bitboard.and(east_origins, game_state.board.white_pawns_bitboard),
        bitboard.and(west_origins, game_state.board.white_pawns_bitboard),
      ]
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
      [
        bitboard.and(east_origins, game_state.board.black_pawns_bitboard),
        bitboard.and(west_origins, game_state.board.black_pawns_bitboard),
      ]
    }
  }

  let pawn_capture_origin_set = bitboard.or(east_origins, west_origins)

  let pawn_capture_origin_list = board.get_positions(pawn_capture_origin_set)

  let pawn_capture_destination_list =
    board.get_positions(pawn_capture_destination_set)

  // we need to go through the list of origins and for each origin
  // if one or both of its attack squares are in the destination list,
  // then we combine the origin and dest into a move and add that move to the list of moves
  let pawn_capture_move_list =
    list.fold(
      pawn_capture_origin_list,
      [],
      fn(collector, position) -> List(Move) {
        let east_attack = case color {
          White ->
            board.get_positions(bitboard.and(
              bitboard.shift_left(position.to_bitboard(position), 9),
              not_a_file,
            ))

          Black ->
            board.get_positions(bitboard.and(
              bitboard.shift_right(position.to_bitboard(position), 7),
              not_a_file,
            ))
        }

        let east_moves = case east_attack {
          [] -> []
          [east_attack] -> {
            let east_attack_in_dest_list =
              list.contains(pawn_capture_destination_list, east_attack)

            let east_moves = case east_attack_in_dest_list {
              False -> []
              True -> {
                let east_moves = case east_attack {
                  position.Position(file: _, rank: position.Eight) if color == White -> [
                    move.Normal(
                      from: position,
                      to: east_attack,
                      captured: {
                        let assert Some(piece) =
                          piece_at_position(game_state, east_attack)
                        Some(piece)
                      },
                      promotion: Some(piece.Piece(color, Queen)),
                    ),
                    move.Normal(
                      from: position,
                      to: east_attack,
                      captured: {
                        let assert Some(piece) =
                          piece_at_position(game_state, east_attack)
                        Some(piece)
                      },
                      promotion: Some(piece.Piece(color, Rook)),
                    ),
                    move.Normal(
                      from: position,
                      to: east_attack,
                      captured: {
                        let assert Some(piece) =
                          piece_at_position(game_state, east_attack)
                        Some(piece)
                      },
                      promotion: Some(piece.Piece(color, Bishop)),
                    ),
                    move.Normal(
                      from: position,
                      to: east_attack,
                      captured: {
                        let assert Some(piece) =
                          piece_at_position(game_state, east_attack)
                        Some(piece)
                      },
                      promotion: Some(piece.Piece(color, Knight)),
                    ),
                  ]
                  position.Position(file: _, rank: position.One) if color == Black -> [
                    move.Normal(
                      from: position,
                      to: east_attack,
                      captured: {
                        let assert Some(piece) =
                          piece_at_position(game_state, east_attack)
                        Some(piece)
                      },
                      promotion: Some(piece.Piece(color, Queen)),
                    ),
                    move.Normal(
                      from: position,
                      to: east_attack,
                      captured: {
                        let assert Some(piece) =
                          piece_at_position(game_state, east_attack)
                        Some(piece)
                      },
                      promotion: Some(piece.Piece(color, Rook)),
                    ),
                    move.Normal(
                      from: position,
                      to: east_attack,
                      captured: {
                        let assert Some(piece) =
                          piece_at_position(game_state, east_attack)
                        Some(piece)
                      },
                      promotion: Some(piece.Piece(color, Bishop)),
                    ),
                    move.Normal(
                      from: position,
                      to: east_attack,
                      captured: {
                        let assert Some(piece) =
                          piece_at_position(game_state, east_attack)
                        Some(piece)
                      },
                      promotion: Some(piece.Piece(color, Knight)),
                    ),
                  ]
                  _ -> [
                    move.Normal(
                      from: position,
                      to: east_attack,
                      captured: {
                        let assert Some(piece) =
                          piece_at_position(game_state, east_attack)
                        Some(piece)
                      },
                      promotion: None,
                    ),
                  ]
                }
                east_moves
              }
            }
            east_moves
          }
        }
        let west_attack = case color {
          White ->
            board.get_positions(bitboard.and(
              bitboard.shift_left(position.to_bitboard(position), 7),
              not_h_file,
            ))

          Black ->
            board.get_positions(bitboard.and(
              bitboard.shift_right(position.to_bitboard(position), 9),
              not_h_file,
            ))
        }

        let west_moves = case west_attack {
          [] -> []
          [west_attack] -> {
            let west_attack_in_dest_list =
              list.contains(pawn_capture_destination_list, west_attack)

            let west_moves = case west_attack_in_dest_list {
              False -> []
              True -> {
                let west_moves = case west_attack {
                  position.Position(file: _, rank: position.Eight) -> [
                    move.Normal(
                      from: position,
                      to: west_attack,
                      captured: {
                        let assert Some(piece) =
                          piece_at_position(game_state, west_attack)
                        Some(piece)
                      },
                      promotion: Some(piece.Piece(color, Queen)),
                    ),
                    move.Normal(
                      from: position,
                      to: west_attack,
                      captured: {
                        let assert Some(piece) =
                          piece_at_position(game_state, west_attack)
                        Some(piece)
                      },
                      promotion: Some(piece.Piece(color, Rook)),
                    ),
                    move.Normal(
                      from: position,
                      to: west_attack,
                      captured: {
                        let assert Some(piece) =
                          piece_at_position(game_state, west_attack)
                        Some(piece)
                      },
                      promotion: Some(piece.Piece(color, Bishop)),
                    ),
                    move.Normal(
                      from: position,
                      to: west_attack,
                      captured: {
                        let assert Some(piece) =
                          piece_at_position(game_state, west_attack)
                        Some(piece)
                      },
                      promotion: Some(piece.Piece(color, Knight)),
                    ),
                  ]
                  _ -> [
                    move.Normal(
                      from: position,
                      to: west_attack,
                      captured: {
                        let assert Some(piece) =
                          piece_at_position(game_state, west_attack)
                        Some(piece)
                      },
                      promotion: None,
                    ),
                  ]
                }
                west_moves
              }
            }
            west_moves
          }
        }

        list.append(list.append(collector, east_moves), west_moves)
      },
    )
  pawn_capture_move_list
}

fn generate_pawn_attack_set(pawn_bitboard: bitboard.Bitboard, color: Color) {
  case color {
    White -> {
      let east_attack =
        bitboard.and(bitboard.shift_left(pawn_bitboard, 9), not_a_file)
      let west_attack =
        bitboard.and(bitboard.shift_left(pawn_bitboard, 7), not_h_file)
      let all_attacks = bitboard.or(east_attack, west_attack)
      all_attacks
    }
    Black -> {
      let east_attack =
        bitboard.and(bitboard.shift_right(pawn_bitboard, 7), not_a_file)
      let west_attack =
        bitboard.and(bitboard.shift_right(pawn_bitboard, 9), not_h_file)
      let all_attacks = bitboard.or(east_attack, west_attack)
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

  let board_map: map.Map(position.Position, Option(piece.Piece)) =
    map.from_list([
      #(position.Position(file: position.A, rank: position.One), None),
      #(position.Position(file: position.B, rank: position.One), None),
      #(position.Position(file: position.C, rank: position.One), None),
      #(position.Position(file: position.D, rank: position.One), None),
      #(position.Position(file: position.E, rank: position.One), None),
      #(position.Position(file: position.F, rank: position.One), None),
      #(position.Position(file: position.G, rank: position.One), None),
      #(position.Position(file: position.H, rank: position.One), None),
      #(position.Position(file: position.A, rank: position.Two), None),
      #(position.Position(file: position.B, rank: position.Two), None),
      #(position.Position(file: position.C, rank: position.Two), None),
      #(position.Position(file: position.D, rank: position.Two), None),
      #(position.Position(file: position.E, rank: position.Two), None),
      #(position.Position(file: position.F, rank: position.Two), None),
      #(position.Position(file: position.G, rank: position.Two), None),
      #(position.Position(file: position.H, rank: position.Two), None),
      #(position.Position(file: position.A, rank: position.Three), None),
      #(position.Position(file: position.B, rank: position.Three), None),
      #(position.Position(file: position.C, rank: position.Three), None),
      #(position.Position(file: position.D, rank: position.Three), None),
      #(position.Position(file: position.E, rank: position.Three), None),
      #(position.Position(file: position.F, rank: position.Three), None),
      #(position.Position(file: position.G, rank: position.Three), None),
      #(position.Position(file: position.H, rank: position.Three), None),
      #(position.Position(file: position.A, rank: position.Four), None),
      #(position.Position(file: position.B, rank: position.Four), None),
      #(position.Position(file: position.C, rank: position.Four), None),
      #(position.Position(file: position.D, rank: position.Four), None),
      #(position.Position(file: position.E, rank: position.Four), None),
      #(position.Position(file: position.F, rank: position.Four), None),
      #(position.Position(file: position.G, rank: position.Four), None),
      #(position.Position(file: position.H, rank: position.Four), None),
      #(position.Position(file: position.A, rank: position.Five), None),
      #(position.Position(file: position.B, rank: position.Five), None),
      #(position.Position(file: position.C, rank: position.Five), None),
      #(position.Position(file: position.D, rank: position.Five), None),
      #(position.Position(file: position.E, rank: position.Five), None),
      #(position.Position(file: position.F, rank: position.Five), None),
      #(position.Position(file: position.G, rank: position.Five), None),
      #(position.Position(file: position.H, rank: position.Five), None),
      #(position.Position(file: position.A, rank: position.Six), None),
      #(position.Position(file: position.B, rank: position.Six), None),
      #(position.Position(file: position.C, rank: position.Six), None),
      #(position.Position(file: position.D, rank: position.Six), None),
      #(position.Position(file: position.E, rank: position.Six), None),
      #(position.Position(file: position.F, rank: position.Six), None),
      #(position.Position(file: position.G, rank: position.Six), None),
      #(position.Position(file: position.H, rank: position.Six), None),
      #(position.Position(file: position.A, rank: position.Seven), None),
      #(position.Position(file: position.B, rank: position.Seven), None),
      #(position.Position(file: position.C, rank: position.Seven), None),
      #(position.Position(file: position.D, rank: position.Seven), None),
      #(position.Position(file: position.E, rank: position.Seven), None),
      #(position.Position(file: position.F, rank: position.Seven), None),
      #(position.Position(file: position.G, rank: position.Seven), None),
      #(position.Position(file: position.H, rank: position.Seven), None),
      #(position.Position(file: position.A, rank: position.Eight), None),
      #(position.Position(file: position.B, rank: position.Eight), None),
      #(position.Position(file: position.C, rank: position.Eight), None),
      #(position.Position(file: position.D, rank: position.Eight), None),
      #(position.Position(file: position.E, rank: position.Eight), None),
      #(position.Position(file: position.F, rank: position.Eight), None),
      #(position.Position(file: position.G, rank: position.Eight), None),
      #(position.Position(file: position.H, rank: position.Eight), None),
    ])

  let white_king_positions = board.get_positions(white_king_bitboard)
  let white_queen_positions = board.get_positions(white_queen_bitboard)
  let white_rook_positions = board.get_positions(white_rook_bitboard)
  let white_bishop_positions = board.get_positions(white_bishop_bitboard)
  let white_knight_positions = board.get_positions(white_knight_bitboard)
  let white_pawns_positions = board.get_positions(white_pawns_bitboard)
  let black_king_positions = board.get_positions(black_king_bitboard)
  let black_queen_positions = board.get_positions(black_queen_bitboard)
  let black_rook_positions = board.get_positions(black_rook_bitboard)
  let black_bishop_positions = board.get_positions(black_bishop_bitboard)
  let black_knight_positions = board.get_positions(black_knight_bitboard)
  let black_pawns_positions = board.get_positions(black_pawns_bitboard)

  let board_map =
    list.fold(
      white_king_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(piece.Piece(White, King)))
      },
    )

  let board_map =
    list.fold(
      white_queen_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(piece.Piece(White, Queen)))
      },
    )

  let board_map =
    list.fold(
      white_rook_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(piece.Piece(White, Rook)))
      },
    )

  let board_map =
    list.fold(
      white_bishop_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(piece.Piece(White, Bishop)))
      },
    )

  let board_map =
    list.fold(
      white_knight_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(piece.Piece(White, Knight)))
      },
    )

  let board_map =
    list.fold(
      white_pawns_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(piece.Piece(White, Pawn)))
      },
    )

  let board_map =
    list.fold(
      black_king_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(piece.Piece(Black, King)))
      },
    )

  let board_map =
    list.fold(
      black_queen_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(piece.Piece(Black, Queen)))
      },
    )

  let board_map =
    list.fold(
      black_rook_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(piece.Piece(Black, Rook)))
      },
    )

  let board_map =
    list.fold(
      black_bishop_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(piece.Piece(Black, Bishop)))
      },
    )

  let board_map =
    list.fold(
      black_knight_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(piece.Piece(Black, Knight)))
      },
    )

  let board_map =
    list.fold(
      black_pawns_positions,
      board_map,
      fn(board_map, position) {
        map.insert(board_map, position, Some(piece.Piece(Black, Pawn)))
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
    positions_in_printing_order,
    fn(pos) {
      let piece_to_print = result.unwrap(map.get(board_map, pos), None)
      case pos.file {
        position.A -> {
          io.print("\n")
          io.print(
            " " <> int.to_string(position.rank_to_int(pos.rank) + 1) <> " | ",
          )
          io.print(case piece_to_print {
            Some(piece.Piece(White, Pawn)) -> "♙"
            Some(piece.Piece(White, Knight)) -> "♘"
            Some(piece.Piece(White, Bishop)) -> "♗"
            Some(piece.Piece(White, Rook)) -> "♖"
            Some(piece.Piece(White, Queen)) -> "♕"
            Some(piece.Piece(White, King)) -> "♔"
            Some(piece.Piece(Black, Pawn)) -> "♟"
            Some(piece.Piece(Black, Knight)) -> "♞"
            Some(piece.Piece(Black, Bishop)) -> "♝"
            Some(piece.Piece(Black, Rook)) -> "♜"
            Some(piece.Piece(Black, Queen)) -> "♛"
            Some(piece.Piece(Black, King)) -> "♚"
            None -> " "
          })
          io.print(" | ")
        }

        position.H -> {
          io.print(case piece_to_print {
            Some(piece.Piece(White, Pawn)) -> "♙"
            Some(piece.Piece(White, Knight)) -> "♘"
            Some(piece.Piece(White, Bishop)) -> "♗"
            Some(piece.Piece(White, Rook)) -> "♖"
            Some(piece.Piece(White, Queen)) -> "♕"
            Some(piece.Piece(White, King)) -> "♔"
            Some(piece.Piece(Black, Pawn)) -> "♟"
            Some(piece.Piece(Black, Knight)) -> "♞"
            Some(piece.Piece(Black, Bishop)) -> "♝"
            Some(piece.Piece(Black, Rook)) -> "♜"
            Some(piece.Piece(Black, Queen)) -> "♛"
            Some(piece.Piece(Black, King)) -> "♚"
            None -> " "
          })

          io.print(" | ")
          io.print("\n")
          io.print("   +---+---+---+---+---+---+---+---+")
        }

        _ -> {
          io.print(case piece_to_print {
            Some(piece.Piece(White, Pawn)) -> "♙"
            Some(piece.Piece(White, Knight)) -> "♘"
            Some(piece.Piece(White, Bishop)) -> "♗"
            Some(piece.Piece(White, Rook)) -> "♖"
            Some(piece.Piece(White, Queen)) -> "♕"
            Some(piece.Piece(White, King)) -> "♔"
            Some(piece.Piece(Black, Pawn)) -> "♟"
            Some(piece.Piece(Black, Knight)) -> "♞"
            Some(piece.Piece(Black, Bishop)) -> "♝"
            Some(piece.Piece(Black, Rook)) -> "♜"
            Some(piece.Piece(Black, Queen)) -> "♛"
            Some(piece.Piece(Black, King)) -> "♚"
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
    positions_in_printing_order,
    fn(pos) {
      let piece_to_print = result.unwrap(map.get(board_map, pos), None)
      case pos.file {
        position.A -> {
          io.print("\n")
          io.print(
            " " <> int.to_string(position.rank_to_int(pos.rank) + 1) <> " | ",
          )
          io.print(case piece_to_print {
            Some(piece.Piece(White, Pawn)) -> "♙"
            Some(piece.Piece(White, Knight)) -> "♘"
            Some(piece.Piece(White, Bishop)) -> "♗"
            Some(piece.Piece(White, Rook)) -> "♖"
            Some(piece.Piece(White, Queen)) -> "♕"
            Some(piece.Piece(White, King)) -> "♔"
            Some(piece.Piece(Black, Pawn)) -> "♟"
            Some(piece.Piece(Black, Knight)) -> "♞"
            Some(piece.Piece(Black, Bishop)) -> "♝"
            Some(piece.Piece(Black, Rook)) -> "♜"
            Some(piece.Piece(Black, Queen)) -> "♛"
            Some(piece.Piece(Black, King)) -> "♚"
            None -> " "
          })
          io.print(" | ")
        }

        position.H -> {
          io.print(case piece_to_print {
            Some(piece.Piece(White, Pawn)) -> "♙"
            Some(piece.Piece(White, Knight)) -> "♘"
            Some(piece.Piece(White, Bishop)) -> "♗"
            Some(piece.Piece(White, Rook)) -> "♖"
            Some(piece.Piece(White, Queen)) -> "♕"
            Some(piece.Piece(White, King)) -> "♔"
            Some(piece.Piece(Black, Pawn)) -> "♟"
            Some(piece.Piece(Black, Knight)) -> "♞"
            Some(piece.Piece(Black, Bishop)) -> "♝"
            Some(piece.Piece(Black, Rook)) -> "♜"
            Some(piece.Piece(Black, Queen)) -> "♛"
            Some(piece.Piece(Black, King)) -> "♚"
            None -> " "
          })

          io.print(" | ")
          io.print("\n")
          io.print("   +---+---+---+---+---+---+---+---+")
        }

        _ -> {
          io.print(case piece_to_print {
            Some(piece.Piece(White, Pawn)) -> "♙"
            Some(piece.Piece(White, Knight)) -> "♘"
            Some(piece.Piece(White, Bishop)) -> "♗"
            Some(piece.Piece(White, Rook)) -> "♖"
            Some(piece.Piece(White, Queen)) -> "♕"
            Some(piece.Piece(White, King)) -> "♔"
            Some(piece.Piece(Black, Pawn)) -> "♟"
            Some(piece.Piece(Black, Knight)) -> "♞"
            Some(piece.Piece(Black, Bishop)) -> "♝"
            Some(piece.Piece(Black, Rook)) -> "♜"
            Some(piece.Piece(Black, Queen)) -> "♛"
            Some(piece.Piece(Black, King)) -> "♚"
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

pub fn new_game_from_fen(fen_string: String) {
  let fen = fen.from_string(fen_string)

  let status = InProgress

  let ply = case fen.turn {
    White -> {
      { fen.fullmove - 1 } * 2
    }
    Black -> {
      { fen.fullmove - 1 } * 2 + 1
    }
  }

  let game_state =
    Game(
      board: fen.board,
      turn: fen.turn,
      history: [],
      status: status,
      ply: ply,
      white_king_castle: fen.castling.white_kingside,
      white_queen_castle: fen.castling.white_queenside,
      black_king_castle: fen.castling.black_kingside,
      black_queen_castle: fen.castling.black_queenside,
      en_passant: fen.en_passant,
    )
  let assert Ok(actor) = actor.start(game_state, handle_message)
  actor
}

pub fn new_game() {
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
    board.BoardBB(
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

  let turn = White

  let history = []

  let status = InProgress

  let ply = 0

  let assert Ok(actor) =
    actor.start(
      Game(board, turn, history, status, ply, True, True, True, True, None),
      handle_message,
    )
  actor
}
