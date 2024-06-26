import bitboard.{type Bitboard}
import board.{type BoardBB}
import board_dict.{type BoardDict}
import castle_rights.{type CastleRights, No, Yes}
import color.{type Color, Black, White}
import fen
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string.{length}
import knight_target
import move.{type Move, type MoveWithCapture}
import move_san
import pgn
import piece.{type Piece, Bishop, King, Knight, Pawn, Queen, Rook}
import position.{
  type Position, A, B, C, D, E, Eight, F, Five, Four, G, H, One, Seven, Six,
  Three, Two,
}
import ray
import status.{
  type Status, Draw, FiftyMoveRule, InProgress, ThreefoldRepetition, Win,
}

pub type Game {
  Game(
    board: BoardBB,
    turn: Color,
    history: List(MoveWithCapture),
    status: Option(Status),
    ply: Int,
    white_kingside_castle: CastleRights,
    white_queenside_castle: CastleRights,
    black_kingside_castle: CastleRights,
    black_queenside_castle: CastleRights,
    en_passant: Option(Position),
  )
}

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

const a_file = 0b00000001_00000001_00000001_00000001_00000001_00000001_00000001_00000001

const h_file = 0b10000000_10000000_10000000_10000000_10000000_10000000_10000000_10000000

const not_a_file = 0b11111110_11111110_11111110_11111110_11111110_11111110_11111110_11111110

const not_b_file = 0b11111101_11111101_11111101_11111101_11111101_11111101_11111101_11111101

const not_g_file = 0b10111111_10111111_10111111_10111111_10111111_10111111_10111111_10111111

const not_h_file = 0b01111111_01111111_01111111_01111111_01111111_01111111_01111111_01111111

const rank_1 = 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_11111111

const rank_2 = 0b00000000_00000000_00000000_00000000_00000000_00000000_11111111_00000000

const rank_3 = 0b00000000_00000000_00000000_00000000_00000000_11111111_00000000_00000000

const rank_6 = 0b00000000_00000000_11111111_00000000_00000000_00000000_00000000_00000000

const rank_7 = 0b00000000_11111111_00000000_00000000_00000000_00000000_00000000_00000000

const rank_8 = 0b11111111_00000000_00000000_00000000_00000000_00000000_00000000_00000000

pub fn to_fen(game: Game) -> String {
  let halfmove = case game.status {
    None -> 0
    Some(InProgress(fifty_move_rule: halfmove, threefold_repetition_rule: _)) ->
      halfmove
    Some(Draw(_)) -> 0
    Some(_) -> 0
  }
  let game_fen =
    fen.Fen(
      board: game.board,
      turn: game.turn,
      en_passant: game.en_passant,
      castling: fen.CastlingStatus(
        white_kingside: castle_rights.to_bool(game.white_kingside_castle),
        white_queenside: castle_rights.to_bool(game.white_queenside_castle),
        black_kingside: castle_rights.to_bool(game.black_kingside_castle),
        black_queenside: castle_rights.to_bool(game.black_queenside_castle),
      ),
      fullmove: game.ply / 2 + 1,
      halfmove: halfmove,
    )
  fen.to_string(game_fen)
}

pub fn new_game_without_status() -> Game {
  let white_king_bitboard =
    0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00001000

  let white_queen_bitboard =
    0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00010000

  let white_rook_bitboard =
    0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_10000001

  let white_bishop_bitboard =
    0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00100100

  let white_knight_bitboard =
    0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_01000010

  let white_pawns_bitboard =
    0b00000000_00000000_00000000_00000000_00000000_00000000_11111111_00000000

  let black_king_bitboard =
    0b00001000_00000000_00000000_00000000_00000000_00000000_00000000_00000000

  let black_queen_bitboard =
    0b00010000_00000000_00000000_00000000_00000000_00000000_00000000_00000000

  let black_rook_bitboard =
    0b10000001_00000000_00000000_00000000_00000000_00000000_00000000_00000000

  let black_bishop_bitboard =
    0b00100100_00000000_00000000_00000000_00000000_00000000_00000000_00000000

  let black_knight_bitboard =
    0b01000010_00000000_00000000_00000000_00000000_00000000_00000000_00000000

  let black_pawns_bitboard =
    0b00000000_11111111_00000000_00000000_00000000_00000000_00000000_00000000

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

  let status = None

  let ply = 0

  Game(
    board: board,
    turn: turn,
    history: history,
    status: status,
    ply: ply,
    white_kingside_castle: Yes,
    white_queenside_castle: Yes,
    black_kingside_castle: Yes,
    black_queenside_castle: Yes,
    en_passant: None,
  )
}

pub fn new_game() -> Game {
  let white_king_bitboard =
    0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00010000

  let white_queen_bitboard =
    0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00001000

  let white_rook_bitboard =
    0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_10000001

  let white_bishop_bitboard =
    0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00100100

  let white_knight_bitboard =
    0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_01000010

  let white_pawns_bitboard =
    0b00000000_00000000_00000000_00000000_00000000_00000000_11111111_00000000

  let black_king_bitboard =
    0b00010000_00000000_00000000_00000000_00000000_00000000_00000000_00000000

  let black_queen_bitboard =
    0b00001000_00000000_00000000_00000000_00000000_00000000_00000000_00000000

  let black_rook_bitboard =
    0b10000001_00000000_00000000_00000000_00000000_00000000_00000000_00000000

  let black_bishop_bitboard =
    0b00100100_00000000_00000000_00000000_00000000_00000000_00000000_00000000

  let black_knight_bitboard =
    0b01000010_00000000_00000000_00000000_00000000_00000000_00000000_00000000

  let black_pawns_bitboard =
    0b00000000_11111111_00000000_00000000_00000000_00000000_00000000_00000000

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

  let status =
    InProgress(fifty_move_rule: 0, threefold_repetition_rule: dict.new())

  let ply = 0

  Game(
    board: board,
    turn: turn,
    history: history,
    status: Some(status),
    ply: ply,
    white_kingside_castle: Yes,
    white_queenside_castle: Yes,
    black_kingside_castle: Yes,
    black_queenside_castle: Yes,
    en_passant: None,
  )
}

pub fn from_fen_string(fen_string: String) -> Result(Game, _) {
  let fen = fen.from_string(fen_string)

  let status =
    InProgress(
      fifty_move_rule: fen.halfmove,
      threefold_repetition_rule: dict.new(),
    )

  let ply = case fen.turn {
    White -> {
      { fen.fullmove - 1 } * 2
    }
    Black -> {
      { fen.fullmove - 1 } * 2 + 1
    }
  }

  let white_kingside_castle = case fen.castling.white_kingside {
    True -> Yes
    False -> No(1)
  }

  let white_queenside_castle = case fen.castling.white_queenside {
    True -> Yes
    False -> No(1)
  }

  let black_kingside_castle = case fen.castling.black_kingside {
    True -> Yes
    False -> No(2)
  }

  let black_queenside_castle = case fen.castling.black_queenside {
    True -> Yes
    False -> No(2)
  }

  Ok(Game(
    board: fen.board,
    turn: fen.turn,
    history: [],
    status: Some(status),
    ply: ply,
    white_kingside_castle: white_kingside_castle,
    white_queenside_castle: white_queenside_castle,
    black_kingside_castle: black_kingside_castle,
    black_queenside_castle: black_queenside_castle,
    en_passant: fen.en_passant,
  ))
}

pub fn load_pgn(pgn: String) -> Result(Game, String) {
  let game = new_game()
  let pgn = string.trim(pgn)
  let pgn = pgn.remove_tags(pgn)
  let list_of_movetext = pgn.split_movetext(pgn)
  list.fold(list_of_movetext, Ok(game), fn(game, movetext) {
    use game <- result.try(game)
    let game = case string.split(movetext, " ") {
      [white_ply, black_ply] -> {
        let game = apply_move_san_string(game, white_ply)
        case game {
          Ok(game) -> {
            apply_move_san_string(game, black_ply)
          }
          Error(message) -> Error(message)
        }
      }
      [white_ply] -> {
        let game = apply_move_san_string(game, white_ply)
        game
      }
      [] -> {
        Error("Invalid PGN")
      }
      _ -> Error("Invalid PGN")
    }
    game
  })
}

fn is_move_legal(game: Game, move: Move) -> Result(Bool, _) {
  use new_game_state <- result.try(apply_move_raw(game, move))
  case move {
    move.Normal(from: _, to: _, promotion: _) | move.EnPassant(from: _, to: _) -> {
      use is_king_in_check <- result.try(is_king_in_check(
        new_game_state,
        game.turn,
      ))
      Ok(!is_king_in_check)
    }
    move.Castle(from: _from, to: to) -> {
      use is_king_in_check_ok <- result.try(is_king_in_check(game, game.turn))
      //First determine if the king is in check,
      //If so then the king cannot castle
      case is_king_in_check_ok {
        True -> Ok(False)
        False -> {
          use is_king_in_check_ok <- result.try(is_king_in_check(
            new_game_state,
            game.turn,
          ))
          case is_king_in_check_ok {
            True -> Ok(False)
            False -> {
              //Then determine if the king is attacked while traversing the castling squares
              //Example: If the king is on E1 and castling to G1, then we need to check if
              //the king is attacked while traversing F1 and G1
              let king_castling_target_square = case to {
                position.Position(file: G, rank: One) ->
                  Ok(position.Position(file: F, rank: One))
                position.Position(file: G, rank: Eight) ->
                  Ok(position.Position(file: F, rank: Eight))
                position.Position(file: C, rank: One) ->
                  Ok(position.Position(file: D, rank: One))
                position.Position(file: C, rank: Eight) ->
                  Ok(position.Position(file: D, rank: Eight))
                _ -> Error("Invalid castle move")
              }

              case king_castling_target_square {
                Error(_) -> Ok(False)
                Ok(king_castling_target_square) -> {
                  let new_game_state =
                    Game(
                      ..new_game_state,
                      board: board.set_piece_at_position(
                        new_game_state.board,
                        king_castling_target_square,
                        piece.Piece(color: game.turn, kind: King),
                      ),
                    )

                  use new_board <- result.try(board.remove_piece_at_position(
                    new_game_state.board,
                    to,
                  ))
                  let new_game_state = Game(..new_game_state, board: new_board)
                  use is_king_in_check_ok <- result.try(is_king_in_check(
                    new_game_state,
                    game.turn,
                  ))
                  case is_king_in_check_ok {
                    True -> Ok(False)
                    False -> Ok(True)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

// Apply move to the board. This function is not concerned with whether 
// the move is possible, it just attempts to apply a move to the board.
// This function is used for check detection and speeding up move application
// during tests. 
pub fn apply_move_raw(game: Game, move: Move) -> Result(Game, _) {
  case move {
    move.Normal(from: from, to: to, promotion: promo_piece) -> {
      use moving_piece <- result.try(case
        board.get_piece_at_position(game.board, from)
      {
        Some(piece) -> Ok(piece)
        None -> {
          Error("No piece at from position")
        }
      })
      let captured_piece = piece_at_position(game, to)

      use new_board <- result.try(board.remove_piece_at_position(
        game.board,
        from,
      ))
      let new_game_state = Game(..game, board: new_board)
      use new_game_state <- result.try(case captured_piece {
        None -> Ok(new_game_state)
        Some(_) -> {
          use new_board <- result.try(board.remove_piece_at_position(
            new_game_state.board,
            to,
          ))
          Ok(Game(..new_game_state, board: new_board))
        }
      })

      let new_game_state = case promo_piece {
        None ->
          Game(
            ..new_game_state,
            board: board.set_piece_at_position(
              new_game_state.board,
              to,
              moving_piece,
            ),
          )
        Some(promo_piece) -> {
          Game(
            ..new_game_state,
            board: board.set_piece_at_position(
              new_game_state.board,
              to,
              promo_piece,
            ),
          )
        }
      }

      let new_ply = new_game_state.ply + 1
      let new_white_king_castle = case game.turn {
        White -> {
          case game.white_kingside_castle {
            Yes ->
              case from {
                position.Position(file: E, rank: One) -> No(new_ply)
                position.Position(file: H, rank: One) -> No(new_ply)
                _ -> Yes
              }
            No(some_ply) -> No(some_ply)
          }
        }
        Black -> game.white_kingside_castle
      }
      let new_white_queen_castle = case game.turn {
        White -> {
          case game.white_queenside_castle {
            Yes ->
              case from {
                position.Position(file: E, rank: One) -> No(new_ply)
                position.Position(file: A, rank: One) -> No(new_ply)
                _ -> Yes
              }
            No(some_ply) -> No(some_ply)
          }
        }
        Black -> game.white_queenside_castle
      }
      let new_black_king_castle = case game.turn {
        White -> game.black_kingside_castle
        Black -> {
          case game.black_kingside_castle {
            Yes ->
              case from {
                position.Position(file: E, rank: Eight) -> No(new_ply)
                position.Position(file: H, rank: Eight) -> No(new_ply)
                _ -> Yes
              }
            No(some_ply) -> No(some_ply)
          }
        }
      }
      let new_black_queen_castle = case game.turn {
        White -> game.black_queenside_castle
        Black -> {
          case game.black_queenside_castle {
            Yes ->
              case from {
                position.Position(file: E, rank: Eight) -> No(new_ply)
                position.Position(file: A, rank: Eight) -> No(new_ply)
                _ -> Yes
              }
            No(some_ply) -> No(some_ply)
          }
        }
      }
      let new_turn = {
        case game.turn {
          White -> Black
          Black -> White
        }
      }
      let move_with_capture = move.MoveWithCapture(move, captured_piece)
      let new_history = [move_with_capture, ..game.history]

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
          white_kingside_castle: new_white_king_castle,
          white_queenside_castle: new_white_queen_castle,
          black_kingside_castle: new_black_king_castle,
          black_queenside_castle: new_black_queen_castle,
          en_passant: new_en_passant,
        )
      Ok(new_game_state)
    }
    move.Castle(from: from, to: to) -> {
      use new_board <- result.try(board.remove_piece_at_position(
        game.board,
        from,
      ))
      let new_game_state = Game(..game, board: new_board)
      let new_game_state =
        Game(
          ..new_game_state,
          board: board.set_piece_at_position(
            new_game_state.board,
            to,
            piece.Piece(color: new_game_state.turn, kind: King),
          ),
        )
      result.try(
        case to {
          position.Position(file: G, rank: One) ->
            Ok(position.Position(file: F, rank: One))
          position.Position(file: G, rank: Eight) ->
            Ok(position.Position(file: F, rank: Eight))
          position.Position(file: C, rank: One) ->
            Ok(position.Position(file: D, rank: One))
          position.Position(file: C, rank: Eight) ->
            Ok(position.Position(file: D, rank: Eight))
          _ -> Error("Invalid castle move")
        },
        fn(rook_castling_target_square) {
          let new_turn = {
            case game.turn {
              White -> Black
              Black -> White
            }
          }
          let new_game_state =
            Game(
              ..new_game_state,
              board: board.set_piece_at_position(
                new_game_state.board,
                rook_castling_target_square,
                piece.Piece(color: game.turn, kind: Rook),
              ),
            )

          use rook_castling_origin_square <- result.try(case to {
            position.Position(file: G, rank: One) ->
              Ok(position.Position(file: H, rank: One))
            position.Position(file: G, rank: Eight) ->
              Ok(position.Position(file: H, rank: Eight))
            position.Position(file: C, rank: One) ->
              Ok(position.Position(file: A, rank: One))
            position.Position(file: C, rank: Eight) ->
              Ok(position.Position(file: A, rank: Eight))
            _ -> Error("Invalid castle move")
          })

          use new_board <- result.try(board.remove_piece_at_position(
            new_game_state.board,
            rook_castling_origin_square,
          ))

          let new_game_state = Game(..new_game_state, board: new_board)

          let new_ply = new_game_state.ply + 1

          use
            #(
              new_white_king_castle,
              new_white_queen_castle,
              new_black_king_castle,
              new_black_queen_castle,
            )
          <- result.try(case game.turn {
            White ->
              Ok(#(
                No(new_ply),
                No(new_ply),
                game.black_kingside_castle,
                game.black_queenside_castle,
              ))
            Black ->
              Ok(#(
                game.white_kingside_castle,
                game.white_queenside_castle,
                No(new_ply),
                No(new_ply),
              ))
          })

          let move_with_capture = move.MoveWithCapture(move, None)

          let new_history = [move_with_capture, ..game.history]

          let new_en_passant = None

          let new_game_state =
            Game(
              ..new_game_state,
              turn: new_turn,
              history: new_history,
              ply: new_ply,
              en_passant: new_en_passant,
              white_kingside_castle: new_white_king_castle,
              white_queenside_castle: new_white_queen_castle,
              black_kingside_castle: new_black_king_castle,
              black_queenside_castle: new_black_queen_castle,
            )
          Ok(new_game_state)
        },
      )
    }
    move.EnPassant(from: from, to: to) -> {
      let new_game_state =
        Game(
          ..game,
          board: board.set_piece_at_position(
            game.board,
            to,
            piece.Piece(color: game.turn, kind: Pawn),
          ),
        )

      use new_board <- result.try(board.remove_piece_at_position(
        new_game_state.board,
        from,
      ))
      let new_game_state = Game(..new_game_state, board: new_board)

      use captured_pawn_square <- result.try(case to {
        position.Position(file: A, rank: Three) ->
          Ok(position.Position(file: A, rank: Four))
        position.Position(file: A, rank: Six) ->
          Ok(position.Position(file: A, rank: Five))
        position.Position(file: B, rank: Three) ->
          Ok(position.Position(file: B, rank: Four))
        position.Position(file: B, rank: Six) ->
          Ok(position.Position(file: B, rank: Five))
        position.Position(file: C, rank: Three) ->
          Ok(position.Position(file: C, rank: Four))
        position.Position(file: C, rank: Six) ->
          Ok(position.Position(file: C, rank: Five))
        position.Position(file: D, rank: Three) ->
          Ok(position.Position(file: D, rank: Four))
        position.Position(file: D, rank: Six) ->
          Ok(position.Position(file: D, rank: Five))
        position.Position(file: E, rank: Three) ->
          Ok(position.Position(file: E, rank: Four))
        position.Position(file: E, rank: Six) ->
          Ok(position.Position(file: E, rank: Five))
        position.Position(file: F, rank: Three) ->
          Ok(position.Position(file: F, rank: Four))
        position.Position(file: F, rank: Six) ->
          Ok(position.Position(file: F, rank: Five))
        position.Position(file: G, rank: Three) ->
          Ok(position.Position(file: G, rank: Four))
        position.Position(file: G, rank: Six) ->
          Ok(position.Position(file: G, rank: Five))
        position.Position(file: H, rank: Three) ->
          Ok(position.Position(file: H, rank: Four))
        position.Position(file: H, rank: Six) ->
          Ok(position.Position(file: H, rank: Five))
        _ -> Error("Invalid en passant move")
      })

      use new_board <- result.try(case
        board.remove_piece_at_position(
          new_game_state.board,
          captured_pawn_square,
        )
      {
        Ok(new_board) -> Ok(new_board)
        Error(_) -> {
          Error("Invalid en passant move")
        }
      })

      let new_ply = new_game_state.ply + 1

      let new_turn = {
        case game.turn {
          White -> Black
          Black -> White
        }
      }

      let new_game_state = Game(..new_game_state, board: new_board)
      let move_with_capture =
        move.MoveWithCapture(
          move,
          Some(piece.Piece(color: new_turn, kind: Pawn)),
        )
      let new_history = [move_with_capture, ..game.history]

      let new_en_passant = None

      let new_game_state =
        Game(
          ..new_game_state,
          history: new_history,
          turn: new_turn,
          ply: new_ply,
          en_passant: new_en_passant,
        )
      Ok(new_game_state)
    }
  }
}

fn has_moves(game: Game) -> Result(Bool, _) {
  use move_list <- result.try(all_legal_moves(game))
  Ok(!list.is_empty(move_list))
}

fn is_king_in_check(game: Game, color: Color) -> Result(Bool, _) {
  let enemy_color = {
    case color {
      White -> Black
      Black -> White
    }
  }
  use enemy_move_list <- result.try({
    let king_bb = case color {
      White -> game.board.white_king_bitboard
      Black -> game.board.black_king_bitboard
    }
    use king_pos <- result.try(case board.get_positions(king_bb) {
      Ok([king_pos]) -> Ok(king_pos)
      _ -> Error("Invalid king position")
    })
    let rook_bb = case color {
      White -> game.board.black_rook_bitboard
      Black -> game.board.white_rook_bitboard
    }

    let king_rook_ray_bb =
      bitboard.or(look_up_east_ray_bb(king_pos), look_up_west_ray_bb(king_pos))
      |> bitboard.or(look_up_north_ray_bb(king_pos))
      |> bitboard.or(look_up_south_ray_bb(king_pos))
    let viable_attacking_rook_bb = bitboard.and(rook_bb, king_rook_ray_bb)
    use rook_move_list <- result.try(case viable_attacking_rook_bb {
      0 -> Ok([])
      _ -> generate_rook_pseudo_legal_move_list(enemy_color, game)
    })

    let bishop_bb = case color {
      White -> game.board.black_bishop_bitboard
      Black -> game.board.white_bishop_bitboard
    }
    let king_bishop_ray_bb =
      bitboard.or(
        look_up_north_east_ray_bb(king_pos),
        look_up_north_west_ray_bb(king_pos),
      )
      |> bitboard.or(look_up_south_east_ray_bb(king_pos))
      |> bitboard.or(look_up_south_west_ray_bb(king_pos))
    let viable_attacking_bishop_bb = bitboard.and(bishop_bb, king_bishop_ray_bb)
    use bishop_move_list <- result.try(case viable_attacking_bishop_bb {
      0 -> Ok([])
      _ -> generate_bishop_pseudo_legal_move_list(enemy_color, game)
    })

    let queen_bb = case color {
      White -> game.board.black_queen_bitboard
      Black -> game.board.white_queen_bitboard
    }

    let king_queen_ray_bb = bitboard.or(king_rook_ray_bb, king_bishop_ray_bb)

    let viable_attacking_queen_bb = bitboard.and(queen_bb, king_queen_ray_bb)

    use queen_move_list <- result.try(case viable_attacking_queen_bb {
      0 -> Ok([])
      _ -> generate_queen_pseudo_legal_move_list(enemy_color, game)
    })

    let knight_bb = case color {
      White -> game.board.black_knight_bitboard
      Black -> game.board.white_knight_bitboard
    }

    let king_knight_target_bb = look_up_knight_target_bb(king_pos)

    let viable_attacking_knight_bb =
      bitboard.and(knight_bb, king_knight_target_bb)

    use knight_move_list <- result.try(case viable_attacking_knight_bb {
      0 -> Ok([])
      _ -> generate_knight_pseudo_legal_move_list(enemy_color, game)
    })

    use pawn_move_list <- result.try(generate_pawn_pseudo_legal_move_list(
      enemy_color,
      game,
    ))

    use enemy_king_move_list <- result.try(generate_king_pseudo_legal_move_list(
      enemy_color,
      game,
    ))

    let list_of_move_lists = [
      rook_move_list,
      bishop_move_list,
      queen_move_list,
      knight_move_list,
      pawn_move_list,
      enemy_king_move_list,
    ]

    let move_list =
      list.fold(list_of_move_lists, [], fn(collector, next) {
        list.append(collector, next)
      })

    Ok(move_list)
  })
  use enemy_move_list <- result.try({
    Ok(
      enemy_move_list
      |> list.filter(fn(move) {
        let piece = piece_at_position(game, move.to)
        case piece {
          None -> False
          Some(piece) -> {
            piece.color == color && piece.kind == King
          }
        }
      }),
    )
  })
  Ok(list.length(enemy_move_list) > 0)
}

fn generate_pseudo_legal_move_list(
  game: Game,
  color: Color,
) -> Result(List(Move), _) {
  use queen_pseudo_legal_move_list <- result.try(
    generate_queen_pseudo_legal_move_list(color, game),
  )
  use king_pseudo_legal_move_list <- result.try(
    generate_king_pseudo_legal_move_list(color, game),
  )
  use castling_pseudo_legal_move_list <- result.try(
    generate_castling_pseudo_legal_move_list(color, game),
  )
  use en_passant_pseudo_legal_move_list <- result.try(
    generate_en_passant_pseudo_legal_move_list(color, game),
  )
  use rook_pseudo_legal_move_list <- result.try(
    generate_rook_pseudo_legal_move_list(color, game),
  )
  use pawn_pseudo_legal_move_list <- result.try(
    generate_pawn_pseudo_legal_move_list(color, game),
  )
  use knight_pseudo_legal_move_list <- result.try(
    generate_knight_pseudo_legal_move_list(color, game),
  )
  use bishop_pseudo_legal_move_list <- result.try(
    generate_bishop_pseudo_legal_move_list(color, game),
  )
  let list_of_move_lists = [
    rook_pseudo_legal_move_list,
    bishop_pseudo_legal_move_list,
    knight_pseudo_legal_move_list,
    pawn_pseudo_legal_move_list,
    queen_pseudo_legal_move_list,
    king_pseudo_legal_move_list,
    castling_pseudo_legal_move_list,
    en_passant_pseudo_legal_move_list,
  ]

  let move_list =
    list.fold(list_of_move_lists, [], fn(collector, next) {
      list.append(collector, next)
    })

  Ok(move_list)
}

fn look_up_knight_target_bb(origin_square: Position) -> Bitboard {
  case origin_square {
    position.Position(file: A, rank: One) -> knight_target.knight_target_bb_a1
    position.Position(file: A, rank: Two) -> knight_target.knight_target_bb_a2
    position.Position(file: A, rank: Three) -> knight_target.knight_target_bb_a3
    position.Position(file: A, rank: Four) -> knight_target.knight_target_bb_a4
    position.Position(file: A, rank: Five) -> knight_target.knight_target_bb_a5
    position.Position(file: A, rank: Six) -> knight_target.knight_target_bb_a6
    position.Position(file: A, rank: Seven) -> knight_target.knight_target_bb_a7
    position.Position(file: A, rank: Eight) -> knight_target.knight_target_bb_a8

    position.Position(file: B, rank: One) -> knight_target.knight_target_bb_b1
    position.Position(file: B, rank: Two) -> knight_target.knight_target_bb_b2
    position.Position(file: B, rank: Three) -> knight_target.knight_target_bb_b3
    position.Position(file: B, rank: Four) -> knight_target.knight_target_bb_b4
    position.Position(file: B, rank: Five) -> knight_target.knight_target_bb_b5
    position.Position(file: B, rank: Six) -> knight_target.knight_target_bb_b6
    position.Position(file: B, rank: Seven) -> knight_target.knight_target_bb_b7
    position.Position(file: B, rank: Eight) -> knight_target.knight_target_bb_b8

    position.Position(file: C, rank: One) -> knight_target.knight_target_bb_c1
    position.Position(file: C, rank: Two) -> knight_target.knight_target_bb_c2
    position.Position(file: C, rank: Three) -> knight_target.knight_target_bb_c3
    position.Position(file: C, rank: Four) -> knight_target.knight_target_bb_c4
    position.Position(file: C, rank: Five) -> knight_target.knight_target_bb_c5
    position.Position(file: C, rank: Six) -> knight_target.knight_target_bb_c6
    position.Position(file: C, rank: Seven) -> knight_target.knight_target_bb_c7
    position.Position(file: C, rank: Eight) -> knight_target.knight_target_bb_c8

    position.Position(file: D, rank: One) -> knight_target.knight_target_bb_d1
    position.Position(file: D, rank: Two) -> knight_target.knight_target_bb_d2
    position.Position(file: D, rank: Three) -> knight_target.knight_target_bb_d3
    position.Position(file: D, rank: Four) -> knight_target.knight_target_bb_d4
    position.Position(file: D, rank: Five) -> knight_target.knight_target_bb_d5
    position.Position(file: D, rank: Six) -> knight_target.knight_target_bb_d6
    position.Position(file: D, rank: Seven) -> knight_target.knight_target_bb_d7
    position.Position(file: D, rank: Eight) -> knight_target.knight_target_bb_d8

    position.Position(file: E, rank: One) -> knight_target.knight_target_bb_e1
    position.Position(file: E, rank: Two) -> knight_target.knight_target_bb_e2
    position.Position(file: E, rank: Three) -> knight_target.knight_target_bb_e3
    position.Position(file: E, rank: Four) -> knight_target.knight_target_bb_e4
    position.Position(file: E, rank: Five) -> knight_target.knight_target_bb_e5
    position.Position(file: E, rank: Six) -> knight_target.knight_target_bb_e6
    position.Position(file: E, rank: Seven) -> knight_target.knight_target_bb_e7
    position.Position(file: E, rank: Eight) -> knight_target.knight_target_bb_e8

    position.Position(file: F, rank: One) -> knight_target.knight_target_bb_f1
    position.Position(file: F, rank: Two) -> knight_target.knight_target_bb_f2
    position.Position(file: F, rank: Three) -> knight_target.knight_target_bb_f3
    position.Position(file: F, rank: Four) -> knight_target.knight_target_bb_f4
    position.Position(file: F, rank: Five) -> knight_target.knight_target_bb_f5
    position.Position(file: F, rank: Six) -> knight_target.knight_target_bb_f6
    position.Position(file: F, rank: Seven) -> knight_target.knight_target_bb_f7
    position.Position(file: F, rank: Eight) -> knight_target.knight_target_bb_f8

    position.Position(file: G, rank: One) -> knight_target.knight_target_bb_g1
    position.Position(file: G, rank: Two) -> knight_target.knight_target_bb_g2
    position.Position(file: G, rank: Three) -> knight_target.knight_target_bb_g3
    position.Position(file: G, rank: Four) -> knight_target.knight_target_bb_g4
    position.Position(file: G, rank: Five) -> knight_target.knight_target_bb_g5
    position.Position(file: G, rank: Six) -> knight_target.knight_target_bb_g6
    position.Position(file: G, rank: Seven) -> knight_target.knight_target_bb_g7
    position.Position(file: G, rank: Eight) -> knight_target.knight_target_bb_g8

    position.Position(file: H, rank: One) -> knight_target.knight_target_bb_h1
    position.Position(file: H, rank: Two) -> knight_target.knight_target_bb_h2
    position.Position(file: H, rank: Three) -> knight_target.knight_target_bb_h3
    position.Position(file: H, rank: Four) -> knight_target.knight_target_bb_h4
    position.Position(file: H, rank: Five) -> knight_target.knight_target_bb_h5
    position.Position(file: H, rank: Six) -> knight_target.knight_target_bb_h6
    position.Position(file: H, rank: Seven) -> knight_target.knight_target_bb_h7
    position.Position(file: H, rank: Eight) -> knight_target.knight_target_bb_h8
  }
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

  list.fold(list_of_all_piece_bitboards, 0, fn(collector, next) {
    bitboard.or(collector, next)
  })
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

  list.fold(list_of_all_piece_bitboards, 0, fn(collector, next) {
    bitboard.or(collector, next)
  })
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

  list.fold(list_of_all_piece_bitboards, 0, fn(collector, next) {
    bitboard.or(collector, next)
  })
}

fn pawn_squares(color: Color, board: BoardBB) -> Bitboard {
  case color {
    White -> board.white_pawns_bitboard
    Black -> board.black_pawns_bitboard
  }
}

fn generate_en_passant_pseudo_legal_move_list(
  color: Color,
  game: Game,
) -> Result(List(Move), _) {
  case game.en_passant {
    None -> Ok([])
    Some(ep_position) -> {
      let ep_bitboard = position.to_bitboard(ep_position)
      let pawn_bitboard = pawn_squares(color, game.board)

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

      use ep_attacker_positions <- result.try(board.get_positions(
        ep_attacker_bitboard,
      ))

      let ep_moves =
        list.map(ep_attacker_positions, fn(position) {
          move.EnPassant(from: position, to: ep_position)
        })

      Ok(ep_moves)
    }
  }
}

fn generate_castling_pseudo_legal_move_list(
  color: Color,
  game: Game,
) -> Result(List(Move), _) {
  let king_bitboard = case color {
    White -> game.board.white_king_bitboard
    Black -> game.board.black_king_bitboard
  }

  use king_position <- result.try(case board.get_positions(king_bitboard) {
    Ok([]) -> {
      Error("No king found on the board")
    }
    Ok([position]) -> Ok(position)
    _ -> {
      Error("More than one king found on the board")
    }
  })

  let king_position_flag = case king_position {
    position.Position(position.E, position.One) if color == White -> True
    position.Position(position.E, position.Eight) if color == Black -> True
    _ -> False
  }

  let rook_bitboard = case color {
    White -> game.board.white_rook_bitboard
    Black -> game.board.black_rook_bitboard
  }

  let queenside_rook_flag = case color {
    White ->
      case bitboard.and(bitboard.and(rook_bitboard, a_file), rank_1) {
        0 -> False
        _ -> True
      }
    Black ->
      case bitboard.and(bitboard.and(rook_bitboard, a_file), rank_8) {
        0 -> False
        _ -> True
      }
  }

  let kingside_rook_flag = case color {
    White ->
      case bitboard.and(bitboard.and(rook_bitboard, h_file), rank_1) {
        0 -> False
        _ -> True
      }
    Black ->
      case bitboard.and(bitboard.and(rook_bitboard, h_file), rank_8) {
        0 -> False
        _ -> True
      }
  }

  //check if there are no pieces between the king and the rook
  let queenside_clear_flag = case color {
    White ->
      case
        bitboard.and(
          0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00001110,
          occupied_squares(game.board),
        )
      {
        0 -> True
        _ -> False
      }
    Black ->
      case
        bitboard.and(
          0b00001110_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
          occupied_squares(game.board),
        )
      {
        0 -> True
        _ -> False
      }
  }

  let kingside_clear_flag = case color {
    White ->
      case
        bitboard.and(
          0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_01100000,
          occupied_squares(game.board),
        )
      {
        0 -> True
        _ -> False
      }
    Black ->
      case
        bitboard.and(
          0b01100000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
          occupied_squares(game.board),
        )
      {
        0 -> True
        _ -> False
      }
  }

  //check if king still has castling rights on each side
  let queenside_castle = case color {
    White -> game.white_queenside_castle
    Black -> game.black_queenside_castle
  }

  let kingside_castle = case color {
    White -> game.white_kingside_castle
    Black -> game.black_kingside_castle
  }
  let castling_moves =
    list.append(
      case queenside_rook_flag, queenside_clear_flag, king_position_flag {
        True, True, True if queenside_castle == Yes ->
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
        _, _, _ -> []
      },
      case kingside_rook_flag, kingside_clear_flag, king_position_flag {
        True, True, True if kingside_castle == Yes ->
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
        _, _, _ -> []
      },
    )
  Ok(castling_moves)
}

fn generate_king_pseudo_legal_move_list(
  color: Color,
  game: Game,
) -> Result(List(Move), _) {
  let king_bitboard = case color {
    White -> game.board.white_king_bitboard
    Black -> game.board.black_king_bitboard
  }

  use king_origin_squares <- result.try(board.get_positions(king_bitboard))

  list.fold(king_origin_squares, Ok([]), fn(collector, origin) {
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
        game.board.white_king_bitboard,
        game.board.white_queen_bitboard,
        game.board.white_rook_bitboard,
        game.board.white_bishop_bitboard,
        game.board.white_knight_bitboard,
        game.board.white_pawns_bitboard,
      ]
      Black -> [
        game.board.black_king_bitboard,
        game.board.black_queen_bitboard,
        game.board.black_rook_bitboard,
        game.board.black_bishop_bitboard,
        game.board.black_knight_bitboard,
        game.board.black_pawns_bitboard,
      ]
    }

    let friendly_pieces =
      list.fold(
        list_of_friendly_piece_bitboards,
        0,
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
          occupied_squares_black(game.board),
        )
      }
      Black -> {
        bitboard.and(
          king_unblocked_target_square_bb,
          occupied_squares_white(game.board),
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
    use simple_moves_positions <- result.try(board.get_positions(simple_moves))
    let simple_moves =
      list.map(simple_moves_positions, fn(dest) -> Move {
        move.Normal(from: origin, to: dest, promotion: None)
      })

    use captures_positions <- result.try(board.get_positions(captures))
    let captures =
      list.map(captures_positions, fn(dest) -> Move {
        move.Normal(from: origin, to: dest, promotion: None)
      })
    let all_moves = list.append(simple_moves, captures)
    use collector <- result.try(collector)
    Ok(list.append(collector, all_moves))
  })
}

fn generate_queen_pseudo_legal_move_list(
  color: Color,
  game: Game,
) -> Result(List(Move), _) {
  let queen_bitboard = case color {
    White -> game.board.white_queen_bitboard
    Black -> game.board.black_queen_bitboard
  }

  use queen_origin_squares <- result.try(board.get_positions(queen_bitboard))

  list.fold(queen_origin_squares, Ok([]), fn(collector, queen_origin_square) {
    let south_mask_bb = look_up_south_ray_bb(queen_origin_square)
    let east_mask_bb = look_up_east_ray_bb(queen_origin_square)
    let north_mask_bb = look_up_north_ray_bb(queen_origin_square)
    let west_mask_bb = look_up_west_ray_bb(queen_origin_square)

    let occupied_squares_bb = occupied_squares(game.board)

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
      Error(_) -> 0
      Ok(position) -> look_up_south_ray_bb(position)
    }
    let first_blocker_east_mask_bb = case first_blocker_east {
      Error(_) -> 0
      Ok(position) -> look_up_east_ray_bb(position)
    }
    let first_blocker_north_mask_bb = case first_blocker_north {
      Error(_) -> 0
      Ok(position) -> look_up_north_ray_bb(position)
    }
    let first_blocker_west_mask_bb = case first_blocker_west {
      Error(_) -> 0
      Ok(position) -> look_up_west_ray_bb(position)
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
          bitboard.not(occupied_squares_white(game.board)),
        )
      }
      Black -> {
        bitboard.and(
          south_ray_bb_with_blocker,
          bitboard.not(occupied_squares_black(game.board)),
        )
      }
    }
    let east_ray_bb = case color {
      White -> {
        bitboard.and(
          east_ray_bb_with_blocker,
          bitboard.not(occupied_squares_white(game.board)),
        )
      }
      Black -> {
        bitboard.and(
          east_ray_bb_with_blocker,
          bitboard.not(occupied_squares_black(game.board)),
        )
      }
    }
    let north_ray_bb = case color {
      White -> {
        bitboard.and(
          north_ray_bb_with_blocker,
          bitboard.not(occupied_squares_white(game.board)),
        )
      }
      Black -> {
        bitboard.and(
          north_ray_bb_with_blocker,
          bitboard.not(occupied_squares_black(game.board)),
        )
      }
    }
    let west_ray_bb = case color {
      White -> {
        bitboard.and(
          west_ray_bb_with_blocker,
          bitboard.not(occupied_squares_white(game.board)),
        )
      }
      Black -> {
        bitboard.and(
          west_ray_bb_with_blocker,
          bitboard.not(occupied_squares_black(game.board)),
        )
      }
    }
    let rook_moves =
      list.fold(
        [south_ray_bb, east_ray_bb, north_ray_bb, west_ray_bb],
        Ok([]),
        fn(collector, next) {
          let captures = case color {
            White -> {
              //TODO: should probably add a occupied_squares_by_color function
              bitboard.and(next, occupied_squares_black(game.board))
            }
            Black -> {
              bitboard.and(next, occupied_squares_white(game.board))
            }
          }

          // TODO: fix this abomination
          let rook_simple_moves = case color {
            White -> {
              bitboard.exclusive_or(next, captures)
            }
            Black -> {
              bitboard.exclusive_or(next, captures)
            }
          }

          use rook_simple_moves_positions <- result.try(board.get_positions(
            rook_simple_moves,
          ))

          let simple_moves =
            list.map(rook_simple_moves_positions, fn(dest) -> Move {
              move.Normal(from: queen_origin_square, to: dest, promotion: None)
            })

          use captures_positions <- result.try(board.get_positions(captures))

          let captures =
            list.map(captures_positions, fn(dest) -> Move {
              move.Normal(from: queen_origin_square, to: dest, promotion: None)
            })
          use collector <- result.try(collector)
          let simple_moves = list.append(collector, simple_moves)
          let all_moves = list.append(simple_moves, captures)
          Ok(all_moves)
        },
      )

    let south_west_mask_bb = look_up_south_west_ray_bb(queen_origin_square)
    let south_east_mask_bb = look_up_south_east_ray_bb(queen_origin_square)
    let north_east_mask_bb = look_up_north_east_ray_bb(queen_origin_square)
    let north_west_mask_bb = look_up_north_west_ray_bb(queen_origin_square)

    let occupied_squares_bb = occupied_squares(game.board)

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
      Error(_) -> 0
      Ok(position) -> look_up_south_west_ray_bb(position)
    }
    let first_blocker_south_east_mask_bb = case first_blocker_south_east {
      Error(_) -> 0
      Ok(position) -> look_up_south_east_ray_bb(position)
    }
    let first_blocker_north_east_mask_bb = case first_blocker_north_east {
      Error(_) -> 0
      Ok(position) -> look_up_north_east_ray_bb(position)
    }
    let first_blocker_north_west_mask_bb = case first_blocker_north_west {
      Error(_) -> 0
      Ok(position) -> look_up_north_west_ray_bb(position)
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
          bitboard.not(occupied_squares_white(game.board)),
        )
      }
      Black -> {
        bitboard.and(
          south_west_ray_bb_with_blocker,
          bitboard.not(occupied_squares_black(game.board)),
        )
      }
    }
    let south_east_ray_bb = case color {
      White -> {
        bitboard.and(
          south_east_ray_bb_with_blocker,
          bitboard.not(occupied_squares_white(game.board)),
        )
      }
      Black -> {
        bitboard.and(
          south_east_ray_bb_with_blocker,
          bitboard.not(occupied_squares_black(game.board)),
        )
      }
    }
    let north_east_ray_bb = case color {
      White -> {
        bitboard.and(
          north_east_ray_bb_with_blocker,
          bitboard.not(occupied_squares_white(game.board)),
        )
      }
      Black -> {
        bitboard.and(
          north_east_ray_bb_with_blocker,
          bitboard.not(occupied_squares_black(game.board)),
        )
      }
    }
    let north_west_ray_bb = case color {
      White -> {
        bitboard.and(
          north_west_ray_bb_with_blocker,
          bitboard.not(occupied_squares_white(game.board)),
        )
      }
      Black -> {
        bitboard.and(
          north_west_ray_bb_with_blocker,
          bitboard.not(occupied_squares_black(game.board)),
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
        Ok([]),
        fn(collector, next) {
          let captures = case color {
            White -> {
              //TODO: should probably add a occupied_squares_by_color function
              bitboard.and(next, occupied_squares_black(game.board))
            }
            Black -> {
              bitboard.and(next, occupied_squares_white(game.board))
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

          use rook_simple_moves_positions <- result.try(board.get_positions(
            rook_simple_moves,
          ))

          let simple_moves =
            list.map(rook_simple_moves_positions, fn(dest) -> Move {
              move.Normal(from: queen_origin_square, to: dest, promotion: None)
            })

          use captures_positions <- result.try(board.get_positions(captures))

          let captures =
            list.map(captures_positions, fn(dest) -> Move {
              move.Normal(from: queen_origin_square, to: dest, promotion: None)
            })
          use collector <- result.try(collector)
          let simple_moves = list.append(collector, simple_moves)
          let all_moves = list.append(simple_moves, captures)
          Ok(all_moves)
        },
      )
    use rook_moves <- result.try(rook_moves)
    use bishop_moves <- result.try(bishop_moves)
    use collector <- result.try(collector)
    let all_moves =
      list.append(list.append(collector, rook_moves), bishop_moves)

    Ok(all_moves)
  })
}

fn generate_rook_pseudo_legal_move_list(
  color: Color,
  game: Game,
) -> Result(List(Move), _) {
  let rook_bitboard = case color {
    White -> game.board.white_rook_bitboard
    Black -> game.board.black_rook_bitboard
  }

  use rook_origin_squares <- result.try(board.get_positions(rook_bitboard))

  list.fold(rook_origin_squares, Ok([]), fn(collector, rook_origin_square) {
    let south_mask_bb = look_up_south_ray_bb(rook_origin_square)
    let east_mask_bb = look_up_east_ray_bb(rook_origin_square)
    let north_mask_bb = look_up_north_ray_bb(rook_origin_square)
    let west_mask_bb = look_up_west_ray_bb(rook_origin_square)

    let occupied_squares_bb = occupied_squares(game.board)

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
      Error(_) -> 0
      Ok(position) -> look_up_south_ray_bb(position)
    }
    let first_blocker_east_mask_bb = case first_blocker_east {
      Error(_) -> 0
      Ok(position) -> look_up_east_ray_bb(position)
    }
    let first_blocker_north_mask_bb = case first_blocker_north {
      Error(_) -> 0
      Ok(position) -> look_up_north_ray_bb(position)
    }
    let first_blocker_west_mask_bb = case first_blocker_west {
      Error(_) -> 0
      Ok(position) -> look_up_west_ray_bb(position)
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
          bitboard.not(occupied_squares_white(game.board)),
        )
      }
      Black -> {
        bitboard.and(
          south_ray_bb_with_blocker,
          bitboard.not(occupied_squares_black(game.board)),
        )
      }
    }
    let east_ray_bb = case color {
      White -> {
        bitboard.and(
          east_ray_bb_with_blocker,
          bitboard.not(occupied_squares_white(game.board)),
        )
      }
      Black -> {
        bitboard.and(
          east_ray_bb_with_blocker,
          bitboard.not(occupied_squares_black(game.board)),
        )
      }
    }
    let north_ray_bb = case color {
      White -> {
        bitboard.and(
          north_ray_bb_with_blocker,
          bitboard.not(occupied_squares_white(game.board)),
        )
      }
      Black -> {
        bitboard.and(
          north_ray_bb_with_blocker,
          bitboard.not(occupied_squares_black(game.board)),
        )
      }
    }
    let west_ray_bb = case color {
      White -> {
        bitboard.and(
          west_ray_bb_with_blocker,
          bitboard.not(occupied_squares_white(game.board)),
        )
      }
      Black -> {
        bitboard.and(
          west_ray_bb_with_blocker,
          bitboard.not(occupied_squares_black(game.board)),
        )
      }
    }
    let rook_moves =
      list.fold(
        [south_ray_bb, east_ray_bb, north_ray_bb, west_ray_bb],
        Ok([]),
        fn(collector, next) {
          let rook_captures = case color {
            White -> {
              //TODO: should probably add a occupied_squares_by_color function
              bitboard.and(next, occupied_squares_black(game.board))
            }
            Black -> {
              bitboard.and(next, occupied_squares_white(game.board))
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
          use rook_simple_moves_positions <- result.try(board.get_positions(
            rook_simple_moves,
          ))
          let simple_moves =
            list.map(rook_simple_moves_positions, fn(dest) -> Move {
              move.Normal(from: rook_origin_square, to: dest, promotion: None)
            })

          use rook_captures_positions <- result.try(board.get_positions(
            rook_captures,
          ))
          let captures =
            list.map(rook_captures_positions, fn(dest) -> Move {
              move.Normal(from: rook_origin_square, to: dest, promotion: None)
            })
          use collector <- result.try(collector)
          let simple_moves = list.append(collector, simple_moves)
          let all_moves = list.append(simple_moves, captures)
          Ok(all_moves)
        },
      )
    use rook_moves <- result.try(rook_moves)
    use collector <- result.try(collector)
    Ok(list.append(collector, rook_moves))
  })
}

fn piece_at_position(game: Game, position: Position) -> Option(piece.Piece) {
  let position_bb_masked =
    bitboard.and(position.to_bitboard(position), occupied_squares(game.board))

  let position_white_king =
    bitboard.and(position_bb_masked, game.board.white_king_bitboard)
  let position_white_queen =
    bitboard.and(position_bb_masked, game.board.white_queen_bitboard)
  let position_white_rook =
    bitboard.and(position_bb_masked, game.board.white_rook_bitboard)
  let position_white_bishop =
    bitboard.and(position_bb_masked, game.board.white_bishop_bitboard)
  let position_white_knight =
    bitboard.and(position_bb_masked, game.board.white_knight_bitboard)
  let position_white_pawn =
    bitboard.and(position_bb_masked, game.board.white_pawns_bitboard)
  let position_black_king =
    bitboard.and(position_bb_masked, game.board.black_king_bitboard)
  let position_black_queen =
    bitboard.and(position_bb_masked, game.board.black_queen_bitboard)
  let position_black_rook =
    bitboard.and(position_bb_masked, game.board.black_rook_bitboard)
  let position_black_bishop =
    bitboard.and(position_bb_masked, game.board.black_bishop_bitboard)
  let position_black_knight =
    bitboard.and(position_bb_masked, game.board.black_knight_bitboard)
  let position_black_pawn =
    bitboard.and(position_bb_masked, game.board.black_pawns_bitboard)

  case position_bb_masked {
    0 -> option.None
    _ if position_white_king != 0 -> option.Some(piece.Piece(White, King))
    _ if position_white_queen != 0 -> option.Some(piece.Piece(White, Queen))
    _ if position_white_rook != 0 -> option.Some(piece.Piece(White, Rook))
    _ if position_white_bishop != 0 -> option.Some(piece.Piece(White, Bishop))
    _ if position_white_knight != 0 -> option.Some(piece.Piece(White, Knight))
    _ if position_white_pawn != 0 -> option.Some(piece.Piece(White, Pawn))
    _ if position_black_king != 0 -> option.Some(piece.Piece(Black, King))
    _ if position_black_queen != 0 -> option.Some(piece.Piece(Black, Queen))
    _ if position_black_rook != 0 -> option.Some(piece.Piece(Black, Rook))
    _ if position_black_bishop != 0 -> option.Some(piece.Piece(Black, Bishop))
    _ if position_black_knight != 0 -> option.Some(piece.Piece(Black, Knight))
    _ if position_black_pawn != 0 -> option.Some(piece.Piece(Black, Pawn))
    _ -> panic
  }
}

fn generate_bishop_pseudo_legal_move_list(
  color: Color,
  game: Game,
) -> Result(List(Move), _) {
  let bishop_bitboard = case color {
    White -> game.board.white_bishop_bitboard
    Black -> game.board.black_bishop_bitboard
  }

  use bishop_origin_squares <- result.try(board.get_positions(bishop_bitboard))

  list.fold(bishop_origin_squares, Ok([]), fn(collector, bishop_origin_square) {
    let south_west_mask_bb = look_up_south_west_ray_bb(bishop_origin_square)
    let south_east_mask_bb = look_up_south_east_ray_bb(bishop_origin_square)
    let north_east_mask_bb = look_up_north_east_ray_bb(bishop_origin_square)
    let north_west_mask_bb = look_up_north_west_ray_bb(bishop_origin_square)

    let occupied_squares_bb = occupied_squares(game.board)

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
      Error(_) -> 0
      Ok(position) -> look_up_south_west_ray_bb(position)
    }
    let first_blocker_south_east_mask_bb = case first_blocker_south_east {
      Error(_) -> 0
      Ok(position) -> look_up_south_east_ray_bb(position)
    }
    let first_blocker_north_east_mask_bb = case first_blocker_north_east {
      Error(_) -> 0
      Ok(position) -> look_up_north_east_ray_bb(position)
    }
    let first_blocker_north_west_mask_bb = case first_blocker_north_west {
      Error(_) -> 0
      Ok(position) -> look_up_north_west_ray_bb(position)
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
          bitboard.not(occupied_squares_white(game.board)),
        )
      }
      Black -> {
        bitboard.and(
          south_west_ray_bb_with_blocker,
          bitboard.not(occupied_squares_black(game.board)),
        )
      }
    }
    let south_east_ray_bb = case color {
      White -> {
        bitboard.and(
          south_east_ray_bb_with_blocker,
          bitboard.not(occupied_squares_white(game.board)),
        )
      }
      Black -> {
        bitboard.and(
          south_east_ray_bb_with_blocker,
          bitboard.not(occupied_squares_black(game.board)),
        )
      }
    }
    let north_east_ray_bb = case color {
      White -> {
        bitboard.and(
          north_east_ray_bb_with_blocker,
          bitboard.not(occupied_squares_white(game.board)),
        )
      }
      Black -> {
        bitboard.and(
          north_east_ray_bb_with_blocker,
          bitboard.not(occupied_squares_black(game.board)),
        )
      }
    }
    let north_west_ray_bb = case color {
      White -> {
        bitboard.and(
          north_west_ray_bb_with_blocker,
          bitboard.not(occupied_squares_white(game.board)),
        )
      }
      Black -> {
        bitboard.and(
          north_west_ray_bb_with_blocker,
          bitboard.not(occupied_squares_black(game.board)),
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
        Ok([]),
        fn(collector, next) {
          let captures = case color {
            White -> {
              //TODO: should probably add a occupied_squares_by_color function
              bitboard.and(next, occupied_squares_black(game.board))
            }
            Black -> {
              bitboard.and(next, occupied_squares_white(game.board))
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

          use rook_simple_moves_positions <- result.try(board.get_positions(
            rook_simple_moves,
          ))
          use captures_positions <- result.try(board.get_positions(captures))
          let simple_moves =
            list.map(rook_simple_moves_positions, fn(dest) -> Move {
              move.Normal(from: bishop_origin_square, to: dest, promotion: None)
            })

          let captures =
            list.map(captures_positions, fn(dest) -> Move {
              move.Normal(from: bishop_origin_square, to: dest, promotion: None)
            })
          use collector <- result.try(collector)
          let simple_moves = list.append(collector, simple_moves)
          let all_moves = list.append(simple_moves, captures)
          Ok(all_moves)
        },
      )
    use bishop_moves <- result.try(bishop_moves)
    use collector <- result.try(collector)
    Ok(list.append(collector, bishop_moves))
  })
}

fn generate_knight_pseudo_legal_move_list(
  color: Color,
  game: Game,
) -> Result(List(Move), _) {
  let knight_bitboard = case color {
    White -> game.board.white_knight_bitboard
    Black -> game.board.black_knight_bitboard
  }

  use knight_origin_squares <- result.try(board.get_positions(knight_bitboard))

  list.fold(knight_origin_squares, Ok([]), fn(collector, origin) {
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
        game.board.white_king_bitboard,
        game.board.white_queen_bitboard,
        game.board.white_rook_bitboard,
        game.board.white_bishop_bitboard,
        game.board.white_knight_bitboard,
        game.board.white_pawns_bitboard,
      ]
      Black -> [
        game.board.black_king_bitboard,
        game.board.black_queen_bitboard,
        game.board.black_rook_bitboard,
        game.board.black_bishop_bitboard,
        game.board.black_knight_bitboard,
        game.board.black_pawns_bitboard,
      ]
    }

    let friendly_pieces =
      list.fold(
        list_of_friendly_piece_bitboards,
        0,
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
          occupied_squares_black(game.board),
        )
      }
      Black -> {
        bitboard.and(
          knight_unblocked_target_square_bb,
          occupied_squares_white(game.board),
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
    use simple_moves_positions <- result.try(board.get_positions(simple_moves))
    let simple_moves =
      list.map(simple_moves_positions, fn(dest) -> Move {
        move.Normal(from: origin, to: dest, promotion: None)
      })
    use captures_positions <- result.try(board.get_positions(captures))
    let captures =
      list.map(captures_positions, fn(dest) -> Move {
        move.Normal(from: origin, to: dest, promotion: None)
      })
    let all_moves = list.append(simple_moves, captures)
    use collector <- result.try(collector)
    Ok(list.append(collector, all_moves))
  })
}

fn generate_pawn_pseudo_legal_move_list(
  color: Color,
  game: Game,
) -> Result(List(Move), _) {
  use capture_list <- result.try(generate_pawn_capture_move_list(color, game))
  let moves_no_captures = generate_pawn_non_capture_move_bitboard(color, game)

  use non_capture_dest_list <- result.try(board.get_positions(moves_no_captures))

  let non_capture_move_list =
    list.fold(non_capture_dest_list, [], fn(acc, dest) -> List(Move) {
      let origin = position.get_rear_position(dest, color)
      let moves = case dest {
        position.Position(file: _, rank: position.Eight) if color == White -> {
          [
            move.Normal(
              from: origin,
              to: dest,
              promotion: Some(piece.Piece(color, Queen)),
            ),
            move.Normal(
              from: origin,
              to: dest,
              promotion: Some(piece.Piece(color, Rook)),
            ),
            move.Normal(
              from: origin,
              to: dest,
              promotion: Some(piece.Piece(color, Bishop)),
            ),
            move.Normal(
              from: origin,
              to: dest,
              promotion: Some(piece.Piece(color, Knight)),
            ),
          ]
        }
        position.Position(file: _, rank: position.One) if color == Black -> {
          [
            move.Normal(
              from: origin,
              to: dest,
              promotion: Some(piece.Piece(color, Queen)),
            ),
            move.Normal(
              from: origin,
              to: dest,
              promotion: Some(piece.Piece(color, Rook)),
            ),
            move.Normal(
              from: origin,
              to: dest,
              promotion: Some(piece.Piece(color, Bishop)),
            ),
            move.Normal(
              from: origin,
              to: dest,
              promotion: Some(piece.Piece(color, Knight)),
            ),
          ]
        }
        _ -> {
          [move.Normal(from: origin, to: dest, promotion: None)]
        }
      }
      list.append(acc, moves)
    })

  let initial_rank_double_move_list =
    generate_pawn_starting_rank_double_move_bitboard(color, game)

  use initial_rank_double_dest_list <- result.try(board.get_positions(
    initial_rank_double_move_list,
  ))

  let initial_rank_double_move_list =
    list.map(initial_rank_double_dest_list, fn(dest) -> Move {
      case color {
        White -> {
          case dest.file {
            position.A ->
              move.Normal(
                from: position.Position(file: position.A, rank: position.Two),
                to: dest,
                promotion: None,
              )
            position.B -> {
              move.Normal(
                from: position.Position(file: position.B, rank: position.Two),
                to: dest,
                promotion: None,
              )
            }
            position.C -> {
              move.Normal(
                from: position.Position(file: position.C, rank: position.Two),
                to: dest,
                promotion: None,
              )
            }
            position.D -> {
              move.Normal(
                from: position.Position(file: position.D, rank: position.Two),
                to: dest,
                promotion: None,
              )
            }
            position.E -> {
              move.Normal(
                from: position.Position(file: position.E, rank: position.Two),
                to: dest,
                promotion: None,
              )
            }
            position.F -> {
              move.Normal(
                from: position.Position(file: position.F, rank: position.Two),
                to: dest,
                promotion: None,
              )
            }
            position.G -> {
              move.Normal(
                from: position.Position(file: position.G, rank: position.Two),
                to: dest,
                promotion: None,
              )
            }
            position.H -> {
              move.Normal(
                from: position.Position(file: position.H, rank: position.Two),
                to: dest,
                promotion: None,
              )
            }
          }
        }

        Black -> {
          case dest.file {
            position.A ->
              move.Normal(
                from: position.Position(file: position.A, rank: position.Seven),
                to: dest,
                promotion: None,
              )
            position.B -> {
              move.Normal(
                from: position.Position(file: position.B, rank: position.Seven),
                to: dest,
                promotion: None,
              )
            }
            position.C -> {
              move.Normal(
                from: position.Position(file: position.C, rank: position.Seven),
                to: dest,
                promotion: None,
              )
            }
            position.D -> {
              move.Normal(
                from: position.Position(file: position.D, rank: position.Seven),
                to: dest,
                promotion: None,
              )
            }
            position.E -> {
              move.Normal(
                from: position.Position(file: position.E, rank: position.Seven),
                to: dest,
                promotion: None,
              )
            }
            position.F -> {
              move.Normal(
                from: position.Position(file: position.F, rank: position.Seven),
                to: dest,
                promotion: None,
              )
            }
            position.G -> {
              move.Normal(
                from: position.Position(file: position.G, rank: position.Seven),
                to: dest,
                promotion: None,
              )
            }
            position.H -> {
              move.Normal(
                from: position.Position(file: position.H, rank: position.Seven),
                to: dest,
                promotion: None,
              )
            }
          }
        }
      }
    })

  Ok(list.append(
    list.append(capture_list, non_capture_move_list),
    initial_rank_double_move_list,
  ))
}

fn generate_pawn_starting_rank_double_move_bitboard(
  color: Color,
  game: Game,
) -> bitboard.Bitboard {
  case color {
    White -> {
      let white_pawn_target_squares =
        bitboard.and(game.board.white_pawns_bitboard, rank_2)

      let white_pawn_target_squares =
        bitboard.or(
          bitboard.shift_left(white_pawn_target_squares, 16),
          bitboard.shift_left(white_pawn_target_squares, 8),
        )

      let occupied_squares = occupied_squares(game.board)

      let moves = bitboard.and(occupied_squares, white_pawn_target_squares)
      let moves =
        bitboard.or(bitboard.shift_left(bitboard.and(moves, rank_3), 8), moves)
      let moves = bitboard.exclusive_or(moves, white_pawn_target_squares)
      let moves = bitboard.and(moves, bitboard.not(rank_3))
      moves
    }
    Black -> {
      let black_pawn_target_squares =
        bitboard.and(game.board.black_pawns_bitboard, rank_7)

      let black_pawn_target_squares =
        bitboard.or(
          bitboard.shift_right(black_pawn_target_squares, 16),
          bitboard.shift_right(black_pawn_target_squares, 8),
        )

      let occupied_squares = occupied_squares(game.board)

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
  game: Game,
) -> bitboard.Bitboard {
  case color {
    White -> {
      let white_pawn_target_squares =
        bitboard.shift_left(game.board.white_pawns_bitboard, 8)

      let list_of_enemy_piece_bitboards = [
        game.board.black_king_bitboard,
        game.board.black_queen_bitboard,
        game.board.black_rook_bitboard,
        game.board.black_bishop_bitboard,
        game.board.black_knight_bitboard,
        game.board.black_pawns_bitboard,
      ]

      let occupied_squares_white = occupied_squares_white(game.board)

      let enemy_pieces =
        list.fold(
          list_of_enemy_piece_bitboards,
          0,
          fn(collector, next) -> Bitboard { bitboard.or(collector, next) },
        )
      let moves = bitboard.exclusive_or(white_pawn_target_squares, enemy_pieces)
      let moves = bitboard.and(moves, white_pawn_target_squares)
      let moves = bitboard.and(moves, bitboard.not(occupied_squares_white))
      moves
    }

    Black -> {
      let black_pawn_target_squares =
        bitboard.shift_right(game.board.black_pawns_bitboard, 8)

      let list_of_enemy_piece_bitboards = [
        game.board.white_king_bitboard,
        game.board.white_queen_bitboard,
        game.board.white_rook_bitboard,
        game.board.white_bishop_bitboard,
        game.board.white_knight_bitboard,
        game.board.white_pawns_bitboard,
      ]

      let occupied_squares_black = occupied_squares_black(game.board)

      let enemy_pieces =
        list.fold(list_of_enemy_piece_bitboards, 0, fn(collector, next) {
          bitboard.or(collector, next)
        })
      let moves = bitboard.exclusive_or(black_pawn_target_squares, enemy_pieces)
      let moves = bitboard.and(moves, black_pawn_target_squares)
      let moves = bitboard.and(moves, bitboard.not(occupied_squares_black))
      moves
    }
  }
}

fn generate_pawn_capture_move_list(
  color: Color,
  game: Game,
) -> Result(List(Move), _) {
  let pawn_attack_set = case color {
    White -> {
      generate_pawn_attack_set(game.board.white_pawns_bitboard, color)
    }
    Black -> {
      generate_pawn_attack_set(game.board.black_pawns_bitboard, color)
    }
  }
  generate_pawn_attack_set(game.board.white_pawns_bitboard, color)
  let list_of_enemy_piece_bitboards = case color {
    White -> {
      [
        game.board.black_king_bitboard,
        game.board.black_queen_bitboard,
        game.board.black_rook_bitboard,
        game.board.black_bishop_bitboard,
        game.board.black_knight_bitboard,
        game.board.black_pawns_bitboard,
      ]
    }
    Black -> {
      [
        game.board.white_king_bitboard,
        game.board.white_queen_bitboard,
        game.board.white_rook_bitboard,
        game.board.white_bishop_bitboard,
        game.board.white_knight_bitboard,
        game.board.white_pawns_bitboard,
      ]
    }
  }
  let enemy_pieces =
    list.fold(list_of_enemy_piece_bitboards, 0, fn(collector, next) {
      bitboard.or(collector, next)
    })
  let pawn_capture_destination_set = bitboard.and(pawn_attack_set, enemy_pieces)

  let #(east_origins, west_origins) = case color {
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
      #(
        bitboard.and(east_origins, game.board.white_pawns_bitboard),
        bitboard.and(west_origins, game.board.white_pawns_bitboard),
      )
    }
    Black -> {
      let west_origins =
        bitboard.and(
          bitboard.shift_left(pawn_capture_destination_set, 9),
          not_a_file,
        )
      let east_origins =
        bitboard.and(
          bitboard.shift_left(pawn_capture_destination_set, 7),
          not_h_file,
        )
      #(
        bitboard.and(east_origins, game.board.black_pawns_bitboard),
        bitboard.and(west_origins, game.board.black_pawns_bitboard),
      )
    }
  }

  let pawn_capture_origin_set = bitboard.or(east_origins, west_origins)

  use pawn_capture_origin_list <- result.try(board.get_positions(
    pawn_capture_origin_set,
  ))

  use pawn_capture_destination_list <- result.try(board.get_positions(
    pawn_capture_destination_set,
  ))

  // we need to go through the list of origins and for each origin
  // if one or both of its attack squares are in the destination list,
  // then we combine the origin and dest into a move and add that move to the list of moves
  let pawn_capture_move_list =
    list.fold(pawn_capture_origin_list, Ok([]), fn(collector, position) {
      use east_attack <- result.try(case color {
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
      })

      let east_moves = case east_attack {
        [] -> []
        [east_attack] -> {
          let east_attack_in_dest_list =
            list.contains(pawn_capture_destination_list, east_attack)

          let east_moves = case east_attack_in_dest_list {
            False -> []
            True -> {
              let east_moves = case east_attack {
                position.Position(file: _, rank: position.Eight)
                  if color == White
                -> [
                  move.Normal(
                    from: position,
                    to: east_attack,
                    promotion: Some(piece.Piece(color, Queen)),
                  ),
                  move.Normal(
                    from: position,
                    to: east_attack,
                    promotion: Some(piece.Piece(color, Rook)),
                  ),
                  move.Normal(
                    from: position,
                    to: east_attack,
                    promotion: Some(piece.Piece(color, Bishop)),
                  ),
                  move.Normal(
                    from: position,
                    to: east_attack,
                    promotion: Some(piece.Piece(color, Knight)),
                  ),
                ]
                position.Position(file: _, rank: position.One)
                  if color == Black
                -> [
                  move.Normal(
                    from: position,
                    to: east_attack,
                    promotion: Some(piece.Piece(color, Queen)),
                  ),
                  move.Normal(
                    from: position,
                    to: east_attack,
                    promotion: Some(piece.Piece(color, Rook)),
                  ),
                  move.Normal(
                    from: position,
                    to: east_attack,
                    promotion: Some(piece.Piece(color, Bishop)),
                  ),
                  move.Normal(
                    from: position,
                    to: east_attack,
                    promotion: Some(piece.Piece(color, Knight)),
                  ),
                ]
                _ -> [
                  move.Normal(from: position, to: east_attack, promotion: None),
                ]
              }
              east_moves
            }
          }
          east_moves
        }
        _ -> panic
      }
      use west_attack <- result.try(case color {
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
      })

      let west_moves = case west_attack {
        [] -> []
        [west_attack] -> {
          let west_attack_in_dest_list =
            list.contains(pawn_capture_destination_list, west_attack)

          let west_moves = case west_attack_in_dest_list {
            False -> []
            True -> {
              let west_moves = case west_attack {
                position.Position(file: _, rank: position.Eight)
                  if color == White
                -> [
                  move.Normal(
                    from: position,
                    to: west_attack,
                    promotion: Some(piece.Piece(color, Queen)),
                  ),
                  move.Normal(
                    from: position,
                    to: west_attack,
                    promotion: Some(piece.Piece(color, Rook)),
                  ),
                  move.Normal(
                    from: position,
                    to: west_attack,
                    promotion: Some(piece.Piece(color, Bishop)),
                  ),
                  move.Normal(
                    from: position,
                    to: west_attack,
                    promotion: Some(piece.Piece(color, Knight)),
                  ),
                ]
                position.Position(file: _, rank: position.One)
                  if color == Black
                -> [
                  move.Normal(
                    from: position,
                    to: west_attack,
                    promotion: Some(piece.Piece(color, Queen)),
                  ),
                  move.Normal(
                    from: position,
                    to: west_attack,
                    promotion: Some(piece.Piece(color, Rook)),
                  ),
                  move.Normal(
                    from: position,
                    to: west_attack,
                    promotion: Some(piece.Piece(color, Bishop)),
                  ),
                  move.Normal(
                    from: position,
                    to: west_attack,
                    promotion: Some(piece.Piece(color, Knight)),
                  ),
                ]
                _ -> [
                  move.Normal(from: position, to: west_attack, promotion: None),
                ]
              }
              west_moves
            }
          }
          west_moves
        }
        _ -> panic
      }
      use collector <- result.try(collector)
      Ok(list.append(list.append(collector, east_moves), west_moves))
    })
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

fn bitboard_repr_to_map_repr(board: BoardBB) -> Result(BoardDict, _) {
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

  let board_map: dict.Dict(position.Position, Option(piece.Piece)) =
    dict.from_list([
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

  use white_king_positions <- result.try(board.get_positions(
    white_king_bitboard,
  ))
  use white_queen_positions <- result.try(board.get_positions(
    white_queen_bitboard,
  ))
  use white_rook_positions <- result.try(board.get_positions(
    white_rook_bitboard,
  ))
  use white_bishop_positions <- result.try(board.get_positions(
    white_bishop_bitboard,
  ))
  use white_knight_positions <- result.try(board.get_positions(
    white_knight_bitboard,
  ))
  use white_pawns_positions <- result.try(board.get_positions(
    white_pawns_bitboard,
  ))
  use black_king_positions <- result.try(board.get_positions(
    black_king_bitboard,
  ))
  use black_queen_positions <- result.try(board.get_positions(
    black_queen_bitboard,
  ))
  use black_rook_positions <- result.try(board.get_positions(
    black_rook_bitboard,
  ))
  use black_bishop_positions <- result.try(board.get_positions(
    black_bishop_bitboard,
  ))
  use black_knight_positions <- result.try(board.get_positions(
    black_knight_bitboard,
  ))
  use black_pawns_positions <- result.try(board.get_positions(
    black_pawns_bitboard,
  ))

  let board_map =
    list.fold(white_king_positions, board_map, fn(board_map, position) {
      dict.insert(board_map, position, Some(piece.Piece(White, King)))
    })

  let board_map =
    list.fold(white_queen_positions, board_map, fn(board_map, position) {
      dict.insert(board_map, position, Some(piece.Piece(White, Queen)))
    })

  let board_map =
    list.fold(white_rook_positions, board_map, fn(board_map, position) {
      dict.insert(board_map, position, Some(piece.Piece(White, Rook)))
    })

  let board_map =
    list.fold(white_bishop_positions, board_map, fn(board_map, position) {
      dict.insert(board_map, position, Some(piece.Piece(White, Bishop)))
    })

  let board_map =
    list.fold(white_knight_positions, board_map, fn(board_map, position) {
      dict.insert(board_map, position, Some(piece.Piece(White, Knight)))
    })

  let board_map =
    list.fold(white_pawns_positions, board_map, fn(board_map, position) {
      dict.insert(board_map, position, Some(piece.Piece(White, Pawn)))
    })

  let board_map =
    list.fold(black_king_positions, board_map, fn(board_map, position) {
      dict.insert(board_map, position, Some(piece.Piece(Black, King)))
    })

  let board_map =
    list.fold(black_queen_positions, board_map, fn(board_map, position) {
      dict.insert(board_map, position, Some(piece.Piece(Black, Queen)))
    })

  let board_map =
    list.fold(black_rook_positions, board_map, fn(board_map, position) {
      dict.insert(board_map, position, Some(piece.Piece(Black, Rook)))
    })

  let board_map =
    list.fold(black_bishop_positions, board_map, fn(board_map, position) {
      dict.insert(board_map, position, Some(piece.Piece(Black, Bishop)))
    })

  let board_map =
    list.fold(black_knight_positions, board_map, fn(board_map, position) {
      dict.insert(board_map, position, Some(piece.Piece(Black, Knight)))
    })

  let board_map =
    list.fold(black_pawns_positions, board_map, fn(board_map, position) {
      dict.insert(board_map, position, Some(piece.Piece(Black, Pawn)))
    })

  Ok(board_map)
}

pub fn print_board(game: Game) {
  use board_map <- result.try(bitboard_repr_to_map_repr(game.board))
  io.print("\n")
  io.print("\n")
  io.print("   +---+---+---+---+---+---+---+---+")
  list.each(positions_in_printing_order, fn(pos) {
    let piece_to_print = result.unwrap(dict.get(board_map, pos), None)
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
  })
  io.print("\n")
  io.print("     a   b   c   d   e   f   g   h\n")
  Ok("Successfully Printed Board")
}

pub fn disable_status(game: Game) -> Game {
  Game(..game, status: None)
}

pub fn apply_move(game: Game, move: Move) -> Result(Game, _) {
  case game.status {
    None -> {
      use legal_moves <- result.try({
        use pseudo_legal_move_list <- result.try(
          generate_pseudo_legal_move_list(game, game.turn),
        )
        Ok(
          pseudo_legal_move_list
          |> list.filter(fn(move) {
            case is_move_legal(game, move) {
              Ok(legality) -> legality
              Error(_) -> False
            }
          }),
        )
      })

      let new_game_state = case list.contains(legal_moves, move) {
        True -> {
          let new_game_state = apply_move_raw(game, move)
          new_game_state
        }
        False -> {
          Ok(game)
        }
      }

      new_game_state
    }
    Some(InProgress(_, _)) -> {
      use legal_moves <- result.try({
        use pseudo_legal_move_list <- result.try(
          generate_pseudo_legal_move_list(game, game.turn),
        )
        Ok(
          pseudo_legal_move_list
          |> list.filter(fn(move) {
            case is_move_legal(game, move) {
              Ok(legality) -> legality
              Error(_) -> False
            }
          }),
        )
      })

      let new_game_state = case list.contains(legal_moves, move) {
        True -> {
          let new_game_state = apply_move_raw(game, move)
          new_game_state
        }
        False -> {
          Ok(game)
        }
      }
      use new_game_state <- result.try(new_game_state)
      use has_moves <- result.try(has_moves(new_game_state))
      use is_king_in_check <- result.try(is_king_in_check(
        new_game_state,
        new_game_state.turn,
      ))
      let new_game_state = case is_king_in_check, has_moves {
        True, False -> {
          let winner = case new_game_state.turn {
            White -> Black
            Black -> White
          }
          Ok(
            Game(
              ..new_game_state,
              status: Some(Win(winner: winner, reason: "Checkmate")),
            ),
          )
        }
        True, True | False, True -> {
          let new_status = case move {
            move.Normal(from: from, to: to, promotion: _) -> {
              use moving_piece <- result.try(case
                board.get_piece_at_position(game.board, from)
              {
                Some(piece) -> Ok(piece)
                None -> Error("no piece at from position")
              })

              case game.status {
                None -> Ok(None)
                Some(InProgress(
                  fifty_move_rule: fifty_move_rule,
                  threefold_repetition_rule: threefold_repetition_rule,
                )) -> {
                  let captured_piece = piece_at_position(game, to)
                  let new_fifty_move_rule = case captured_piece {
                    Some(_) -> 0
                    None -> {
                      case moving_piece {
                        piece.Piece(color: _, kind: piece.Pawn) -> 0
                        _ -> fifty_move_rule + 1
                      }
                    }
                  }
                  let new_status = case new_fifty_move_rule / 2 + 1 {
                    50 -> Some(Draw(FiftyMoveRule))
                    _ ->
                      Some(InProgress(
                        fifty_move_rule: new_fifty_move_rule,
                        threefold_repetition_rule: threefold_repetition_rule,
                      ))
                  }

                  let #(new_threefold_repetition_rule, count) = case
                    captured_piece
                  {
                    Some(_) -> #(threefold_repetition_rule, 0)
                    None -> {
                      let new_threefold_position =
                        status.ThreeFoldPosition(
                          turn: game.turn,
                          board: game.board,
                          en_passant: game.en_passant,
                          white_kingside_castle: game.white_kingside_castle,
                          white_queenside_castle: game.white_queenside_castle,
                          black_kingside_castle: game.black_kingside_castle,
                          black_queenside_castle: game.black_queenside_castle,
                        )
                      let #(new_threefold_repetition_rule, count) = case
                        dict.get(
                          threefold_repetition_rule,
                          new_threefold_position,
                        )
                      {
                        Error(_) -> {
                          let new_threefold_repetition_rule =
                            dict.insert(
                              threefold_repetition_rule,
                              new_threefold_position,
                              1,
                            )

                          #(new_threefold_repetition_rule, 1)
                        }
                        Ok(count) -> {
                          let new_threefold_repetition_rule =
                            dict.insert(
                              threefold_repetition_rule,
                              new_threefold_position,
                              count + 1,
                            )

                          #(new_threefold_repetition_rule, count + 1)
                        }
                      }

                      #(new_threefold_repetition_rule, count)
                    }
                  }

                  let new_status = case new_status {
                    Some(InProgress(
                      fifty_move_rule: fifty_move_rule,
                      threefold_repetition_rule: _,
                    )) -> {
                      case count {
                        3 -> Some(Draw(ThreefoldRepetition))
                        _ ->
                          Some(InProgress(
                            fifty_move_rule: fifty_move_rule,
                            threefold_repetition_rule: new_threefold_repetition_rule,
                          ))
                      }
                    }
                    _ -> new_status
                  }
                  Ok(new_status)
                }
                Some(_) -> Error("game is over, unable to apply moves to board")
              }
            }
            move.Castle(from: _, to: _) -> {
              case game.status {
                None -> Ok(None)
                Some(InProgress(
                  fifty_move_rule: fifty_move_rule,
                  threefold_repetition_rule: threefold_repetition_rule,
                )) -> {
                  let new_fifty_move_rule = fifty_move_rule + 1
                  case new_fifty_move_rule / 2 + 1 {
                    50 -> Ok(Some(Draw(FiftyMoveRule)))
                    _ ->
                      Ok(
                        Some(InProgress(
                          fifty_move_rule: new_fifty_move_rule,
                          threefold_repetition_rule: threefold_repetition_rule,
                        )),
                      )
                  }
                }

                Some(_) ->
                  panic as "game is over, unable to apply moves to board"
              }
            }
            move.EnPassant(from: _, to: _) -> {
              case game.status {
                None -> Ok(None)
                Some(InProgress(
                  fifty_move_rule: _,
                  threefold_repetition_rule: threefold_repetition_rule,
                )) -> {
                  Ok(
                    Some(InProgress(
                      fifty_move_rule: 0,
                      threefold_repetition_rule: threefold_repetition_rule,
                    )),
                  )
                }
                Some(_) -> Error("game is over, unable to apply moves to board")
              }
            }
          }
          use new_status <- result.try(new_status)
          let new_game_state = Game(..new_game_state, status: new_status)
          Ok(new_game_state)
        }
        False, False -> {
          Ok(
            Game(..new_game_state, status: Some(Draw(reason: status.Stalemate))),
          )
        }
      }

      new_game_state
    }
    Some(_) -> {
      Error("Game is over, unable to apply moves to board")
    }
  }
}

pub fn apply_move_san_string(game: Game, move: String) -> Result(Game, String) {
  let move_san = move_san.from_string(move)
  case move_san {
    Ok(move_san) -> {
      case move_san {
        move_san.Normal(
          from: _,
          to: to,
          moving_piece: moving_piece,
          capture: _,
          promotion: promotion,
          maybe_check_or_checkmate: _,
        ) -> {
          let promotion = case promotion {
            Some(promotion) -> Some(piece.Piece(game.turn, promotion))
            None -> None
          }

          let move = {
            use all_legal_moves_ok <- result.try(all_legal_moves(game))
            let potential_moves =
              list.filter(all_legal_moves_ok, fn(move) {
                case move {
                  move.Normal(from: _, to: to_legal, promotion: promo_legal)
                    if to_legal == to && promo_legal == promotion
                  -> {
                    True
                  }
                  _ -> False
                }
              })

            case potential_moves {
              [] -> Error("No potential moves found")
              [move] -> {
                case move {
                  move.Normal(from: _, to: _, promotion: _) -> {
                    Ok(move)
                  }
                  _ -> panic as "This panic should be unreachable"
                }
              }
              move_list -> {
                let maybe_move =
                  list.filter(move_list, fn(move) {
                    case move {
                      move.Normal(from: from, to: _, promotion: _) -> {
                        case board.get_piece_at_position(game.board, from) {
                          Some(piece) -> {
                            piece.kind == moving_piece
                          }
                          None -> False
                        }
                      }
                      _ -> {
                        // this should be unreachable 
                        False
                      }
                    }
                  })
                case maybe_move {
                  [] -> Error("Move not found")
                  [move] -> Ok(move)
                  _ -> panic as "This panic should be unreachable"
                }
              }
            }
          }

          case move {
            Ok(move) -> {
              let new_game_state = apply_move(game, move)
              new_game_state
            }
            Error(error) -> Error(error)
          }
        }
        move_san.Castle(side: side, maybe_check_or_checkmate: _) -> {
          let move = case side {
            move_san.KingSide -> {
              case game.turn {
                White ->
                  move.Castle(
                    from: position.Position(
                      file: position.E,
                      rank: position.One,
                    ),
                    to: position.Position(file: position.G, rank: position.One),
                  )
                Black ->
                  move.Castle(
                    from: position.Position(
                      file: position.E,
                      rank: position.Eight,
                    ),
                    to: position.Position(
                      file: position.G,
                      rank: position.Eight,
                    ),
                  )
              }
            }
            move_san.QueenSide -> {
              case game.turn {
                White ->
                  move.Castle(
                    from: position.Position(
                      file: position.E,
                      rank: position.One,
                    ),
                    to: position.Position(file: position.C, rank: position.One),
                  )
                Black ->
                  move.Castle(
                    from: position.Position(
                      file: position.E,
                      rank: position.Eight,
                    ),
                    to: position.Position(
                      file: position.C,
                      rank: position.Eight,
                    ),
                  )
              }
            }
          }
          apply_move(game, move)
        }
        move_san.EnPassant(from: from, to: to, maybe_check_or_checkmate: _) -> {
          use all_legal_moves_ok <- result.try(all_legal_moves(game))
          let ep_moves =
            list.filter(all_legal_moves_ok, fn(move) {
              case move {
                move.EnPassant(from: _, to: to_legal) if to_legal == to -> {
                  True
                }
                _ -> False
              }
            })

          case ep_moves {
            [] -> Error("Illegal move")
            [move] -> apply_move(game, move)
            [move_1, move_2] -> {
              case from {
                Some(move_san.PositionSan(file: Some(file), rank: _))
                  if file == move_1.from.file
                -> {
                  apply_move(game, move_1)
                }
                Some(move_san.PositionSan(file: Some(file), rank: _))
                  if file == move_2.from.file
                -> {
                  apply_move(game, move_2)
                }
                _ -> Error("Illegal move")
              }
            }
            _ -> Error("Illegal move")
          }
        }
      }
    }
    Error(_) -> Error("Invalid move")
  }
}

pub fn apply_move_uci(game: Game, move: String) -> Result(Game, _) {
  case game.status {
    Some(InProgress(_, _)) | None ->
      case length(move) {
        4 | 5 -> {
          let move_chars = string.to_graphemes(move)
          let from_file = case list.first(move_chars) {
            Ok("a") -> Ok(A)
            Ok("b") -> Ok(B)
            Ok("c") -> Ok(C)
            Ok("d") -> Ok(D)
            Ok("e") -> Ok(E)
            Ok("f") -> Ok(F)
            Ok("g") -> Ok(G)
            Ok("h") -> Ok(H)
            _ -> Error("Could not parse origin file")
          }
          case list.rest(move_chars) {
            Ok(move_chars) -> {
              let from_rank = case list.first(move_chars) {
                Ok("1") -> Ok(One)
                Ok("2") -> Ok(Two)
                Ok("3") -> Ok(Three)
                Ok("4") -> Ok(Four)
                Ok("5") -> Ok(Five)
                Ok("6") -> Ok(Six)
                Ok("7") -> Ok(Seven)
                Ok("8") -> Ok(Eight)
                _ -> Error("Could not parse origin rank")
              }
              case list.rest(move_chars) {
                Ok(move_chars) -> {
                  let to_file = case list.first(move_chars) {
                    Ok("a") -> Ok(A)
                    Ok("b") -> Ok(B)
                    Ok("c") -> Ok(C)
                    Ok("d") -> Ok(D)
                    Ok("e") -> Ok(E)
                    Ok("f") -> Ok(F)
                    Ok("g") -> Ok(G)
                    Ok("h") -> Ok(H)
                    _ -> Error("Could not parse destination file")
                  }
                  case list.rest(move_chars) {
                    Ok(move_chars) -> {
                      let to_rank = case list.first(move_chars) {
                        Ok("1") -> Ok(One)
                        Ok("2") -> Ok(Two)
                        Ok("3") -> Ok(Three)
                        Ok("4") -> Ok(Four)
                        Ok("5") -> Ok(Five)
                        Ok("6") -> Ok(Six)
                        Ok("7") -> Ok(Seven)
                        Ok("8") -> Ok(Eight)
                        _ -> Error("Could not parse destination rank")
                      }

                      case from_file, from_rank, to_file, to_rank {
                        Ok(from_file), Ok(from_rank), Ok(to_file), Ok(to_rank) -> {
                          let promo = case string.slice(move, 4, 1) {
                            "q" -> Some(Queen)
                            "r" -> Some(Rook)
                            "b" -> Some(Bishop)
                            "n" -> Some(Knight)
                            _ -> None
                          }
                          use piece <- result.try(case
                            piece_at_position(
                              game,
                              position.Position(
                                file: from_file,
                                rank: from_rank,
                              ),
                            )
                          {
                            Some(piece) -> Ok(piece)
                            None -> Error("No piece at origin")
                          })

                          let maybe_enemy_piece =
                            piece_at_position(
                              game,
                              position.Position(file: to_file, rank: to_rank),
                            )

                          let move = case promo {
                            Some(promo) -> {
                              move.Normal(
                                from: position.Position(
                                  file: from_file,
                                  rank: from_rank,
                                ),
                                to: position.Position(
                                  file: to_file,
                                  rank: to_rank,
                                ),
                                promotion: Some(piece.Piece(game.turn, promo)),
                              )
                            }
                            None -> {
                              case piece {
                                piece.Piece(color: _, kind: Pawn) -> {
                                  case from_file == to_file {
                                    True ->
                                      move.Normal(
                                        from: position.Position(
                                          file: from_file,
                                          rank: from_rank,
                                        ),
                                        to: position.Position(
                                          file: to_file,
                                          rank: to_rank,
                                        ),
                                        promotion: None,
                                      )
                                    False -> {
                                      case maybe_enemy_piece {
                                        Some(_) ->
                                          move.Normal(
                                            from: position.Position(
                                              file: from_file,
                                              rank: from_rank,
                                            ),
                                            to: position.Position(
                                              file: to_file,
                                              rank: to_rank,
                                            ),
                                            promotion: None,
                                          )
                                        None ->
                                          move.EnPassant(
                                            from: position.Position(
                                              file: from_file,
                                              rank: from_rank,
                                            ),
                                            to: position.Position(
                                              file: to_file,
                                              rank: to_rank,
                                            ),
                                          )
                                      }
                                    }
                                  }
                                }
                                piece.Piece(color: _, kind: King) -> {
                                  case
                                    position.file_to_int(from_file)
                                    - position.file_to_int(to_file)
                                  {
                                    2 ->
                                      move.Castle(
                                        from: position.Position(
                                          file: position.E,
                                          rank: from_rank,
                                        ),
                                        to: position.Position(
                                          file: to_file,
                                          rank: to_rank,
                                        ),
                                      )
                                    -2 ->
                                      move.Castle(
                                        from: position.Position(
                                          file: position.E,
                                          rank: from_rank,
                                        ),
                                        to: position.Position(
                                          file: to_file,
                                          rank: to_rank,
                                        ),
                                      )
                                    _ ->
                                      move.Normal(
                                        from: position.Position(
                                          file: from_file,
                                          rank: from_rank,
                                        ),
                                        to: position.Position(
                                          file: to_file,
                                          rank: to_rank,
                                        ),
                                        promotion: None,
                                      )
                                  }
                                }
                                _ -> {
                                  move.Normal(
                                    from: position.Position(
                                      file: from_file,
                                      rank: from_rank,
                                    ),
                                    to: position.Position(
                                      file: to_file,
                                      rank: to_rank,
                                    ),
                                    promotion: None,
                                  )
                                }
                              }
                            }
                          }

                          let new_game_state = apply_move(game, move)
                          new_game_state
                        }
                        from_file_result,
                          from_rank_result,
                          to_file_result,
                          to_rank_result
                        -> {
                          let #(_, file_errors) =
                            result.partition([from_file_result, to_file_result])
                          let #(_, rank_errors) =
                            result.partition([from_rank_result, to_rank_result])
                          let errors = list.concat([file_errors, rank_errors])
                          Error(string.join(errors, ", "))
                        }
                      }
                    }
                    _ -> Error("Invalid move")
                  }
                }
                Error(_) -> Error("Invalid move")
              }
            }
            Error(_) -> Error("Invalid move")
          }
        }
        _ -> Error("Invalid move")
      }
    Some(_) -> Ok(game)
  }
}

pub fn undo_move(game: Game) -> Result(Game, _) {
  case game.status {
    Some(InProgress(_, _)) | None -> {
      case game.history {
        [] -> {
          Ok(game)
        }
        [move, ..rest] -> {
          case move {
            move.MoveWithCapture(
              captured_piece: captured_piece,
              move: move.Normal(from: from, to: to, promotion: promo_piece),
            ) -> {
              let moving_piece = case
                board.get_piece_at_position(game.board, to)
              {
                None -> {
                  panic as "Undoing Normal Move: Could not get piece at position"
                }
                Some(piece) -> piece
              }

              let moving_piece = case promo_piece {
                None -> moving_piece
                Some(_) -> piece.Piece(color: moving_piece.color, kind: Pawn)
              }

              let new_turn = {
                case game.turn {
                  White -> Black
                  Black -> White
                }
              }

              use new_game_state <- result.try(case captured_piece {
                None -> {
                  use new_board <- result.try(board.remove_piece_at_position(
                    game.board,
                    to,
                  ))

                  Ok(Game(..game, board: new_board))
                }
                Some(piece) -> {
                  use new_board <- result.try(board.remove_piece_at_position(
                    game.board,
                    to,
                  ))

                  let new_board =
                    board.set_piece_at_position(new_board, to, piece)

                  Ok(Game(..game, board: new_board))
                }
              })

              let new_board =
                board.set_piece_at_position(
                  new_game_state.board,
                  from,
                  moving_piece,
                )

              let new_game_state = Game(..new_game_state, board: new_board)

              let new_ply = game.ply - 1

              let new_white_kingside_castle = case game.white_kingside_castle {
                Yes -> Yes
                No(ply) -> {
                  case ply == game.ply {
                    True -> Yes
                    False -> No(ply)
                  }
                }
              }

              let new_white_queenside_castle = case
                game.white_queenside_castle
              {
                Yes -> Yes
                No(ply) -> {
                  case ply == game.ply {
                    True -> Yes
                    False -> No(ply)
                  }
                }
              }

              let new_black_kingside_castle = case game.black_kingside_castle {
                Yes -> Yes
                No(ply) -> {
                  case ply == game.ply {
                    True -> Yes
                    False -> No(ply)
                  }
                }
              }

              let new_black_queenside_castle = case
                game.black_queenside_castle
              {
                Yes -> Yes
                No(ply) -> {
                  case ply == game.ply {
                    True -> Yes
                    False -> No(ply)
                  }
                }
              }

              let new_history = rest

              let new_en_passant = case rest {
                [] -> None
                [move] | [move, ..] -> {
                  case move {
                    move.MoveWithCapture(
                      captured_piece: _captured_piece,
                      move: move.Normal(
                        from: position.Position(file: _, rank: Two),
                        to: position.Position(file: file, rank: Four),
                        promotion: None,
                      ),
                    )
                      if game.turn == White
                    -> {
                      let moving_piece = case
                        board.get_piece_at_position(
                          new_game_state.board,
                          position.Position(file: file, rank: Four),
                        )
                      {
                        Some(piece) -> piece
                        None ->
                          panic as "Undoing Normal Move: Could not get piece at position"
                      }
                      case moving_piece {
                        piece.Piece(color: _, kind: Pawn) -> {
                          Some(position.Position(file: file, rank: Three))
                        }
                        _ -> None
                      }
                    }
                    move.MoveWithCapture(
                      captured_piece: _captured_piece,
                      move: move.Normal(
                        from: position.Position(file: _, rank: Seven),
                        to: position.Position(file: file, rank: Five),
                        promotion: None,
                      ),
                    )
                      if game.turn == Black
                    -> {
                      let moving_piece = case
                        board.get_piece_at_position(
                          new_game_state.board,
                          position.Position(file: file, rank: Five),
                        )
                      {
                        Some(piece) -> piece
                        None ->
                          panic as "Undoing Normal Move:Could not get piece at position"
                      }
                      case moving_piece {
                        piece.Piece(color: _, kind: Pawn) -> {
                          Some(position.Position(file: file, rank: Six))
                        }
                        _ -> None
                      }
                    }
                    _ -> None
                  }
                }
              }

              let new_status = case game.status {
                None -> None
                Some(InProgress(fifty_move_rule, threefold_repetition_rule)) -> {
                  let new_fifty_move_rule = case fifty_move_rule {
                    0 -> 0
                    _ -> fifty_move_rule - 1
                  }

                  let threefold_position =
                    status.ThreeFoldPosition(
                      board: game.board,
                      turn: game.turn,
                      white_kingside_castle: game.white_kingside_castle,
                      white_queenside_castle: game.white_queenside_castle,
                      black_kingside_castle: game.black_kingside_castle,
                      black_queenside_castle: game.black_queenside_castle,
                      en_passant: game.en_passant,
                    )
                  let new_threefold_repetition_rule = case
                    dict.get(threefold_repetition_rule, threefold_position)
                  {
                    Error(Nil) -> threefold_repetition_rule
                    Ok(0) | Ok(1) ->
                      dict.delete(threefold_repetition_rule, threefold_position)
                    Ok(count) ->
                      dict.insert(
                        threefold_repetition_rule,
                        threefold_position,
                        count - 1,
                      )
                  }

                  Some(InProgress(
                    new_fifty_move_rule,
                    new_threefold_repetition_rule,
                  ))
                }
                Some(_) ->
                  panic as "Undoing Normal Move: trying to undo a move in a finished game is not possible"
              }

              let new_game_state =
                Game(
                  ..new_game_state,
                  turn: new_turn,
                  history: new_history,
                  ply: new_ply,
                  status: new_status,
                  white_kingside_castle: new_white_kingside_castle,
                  white_queenside_castle: new_white_queenside_castle,
                  black_kingside_castle: new_black_kingside_castle,
                  black_queenside_castle: new_black_queenside_castle,
                  en_passant: new_en_passant,
                )

              Ok(new_game_state)
            }
            move.MoveWithCapture(
              captured_piece: _captured_piece,
              move: move.Castle(from: from, to: to),
            ) -> {
              let rook_castling_target_square = case to {
                position.Position(file: G, rank: One) ->
                  position.Position(file: F, rank: One)
                position.Position(file: G, rank: Eight) ->
                  position.Position(file: F, rank: Eight)
                position.Position(file: C, rank: One) ->
                  position.Position(file: D, rank: One)
                position.Position(file: C, rank: Eight) ->
                  position.Position(file: D, rank: Eight)
                _ -> panic as "Undoing Castle Move: Invalid castle move"
              }

              use new_board <- result.try(case
                board.remove_piece_at_position(
                  game.board,
                  rook_castling_target_square,
                )
              {
                Ok(board) -> Ok(board)
                Error(_) ->
                  Error(
                    "Undoing Castle Move: Could not remove piece at position",
                  )
              })
              let new_game_state = Game(..game, board: new_board)

              use new_board <- result.try(board.remove_piece_at_position(
                new_game_state.board,
                to,
              ))
              let new_game_state = Game(..new_game_state, board: new_board)

              let rook_castling_origin_square = case to {
                position.Position(file: G, rank: One) ->
                  position.Position(file: H, rank: One)
                position.Position(file: G, rank: Eight) ->
                  position.Position(file: H, rank: Eight)
                position.Position(file: C, rank: One) ->
                  position.Position(file: A, rank: One)
                position.Position(file: C, rank: Eight) ->
                  position.Position(file: A, rank: Eight)
                _ -> panic as "Undoing Castle Move: Invalid castle move"
              }

              let new_turn = {
                case new_game_state.turn {
                  White -> Black
                  Black -> White
                }
              }
              let new_game_state =
                Game(
                  ..new_game_state,
                  board: board.set_piece_at_position(
                    new_game_state.board,
                    from,
                    piece.Piece(color: new_turn, kind: King),
                  ),
                )

              let new_game_state =
                Game(
                  ..new_game_state,
                  board: board.set_piece_at_position(
                    new_game_state.board,
                    rook_castling_origin_square,
                    piece.Piece(color: new_turn, kind: Rook),
                  ),
                )

              let new_ply = game.ply - 1

              let new_white_kingside_castle = case game.white_kingside_castle {
                Yes -> Yes
                No(ply) -> {
                  case ply == game.ply {
                    True -> Yes
                    False -> No(ply)
                  }
                }
              }

              let new_white_queenside_castle = case
                game.white_queenside_castle
              {
                Yes -> Yes
                No(ply) -> {
                  case ply == game.ply {
                    True -> Yes
                    False -> No(ply)
                  }
                }
              }

              let new_black_kingside_castle = case game.black_kingside_castle {
                Yes -> Yes
                No(ply) -> {
                  case ply == game.ply {
                    True -> Yes
                    False -> No(ply)
                  }
                }
              }

              let new_black_queenside_castle = case
                game.black_queenside_castle
              {
                Yes -> Yes
                No(ply) -> {
                  case ply == game.ply {
                    True -> Yes
                    False -> No(ply)
                  }
                }
              }

              let new_history = rest

              let new_en_passant = case rest {
                [] -> None
                [move] | [move, ..] -> {
                  case move {
                    move.MoveWithCapture(
                      captured_piece: _captured_piece,
                      move: move.Normal(
                        from: position.Position(file: _, rank: Two),
                        to: position.Position(file: file, rank: Four),
                        promotion: None,
                      ),
                    )
                      if game.turn == White
                    -> {
                      let moving_piece = case
                        board.get_piece_at_position(
                          new_game_state.board,
                          position.Position(file: file, rank: Four),
                        )
                      {
                        Some(piece) -> piece
                        None ->
                          panic as "Undoing Castle Move: could not get piece at position 1"
                      }
                      case moving_piece {
                        piece.Piece(color: _, kind: Pawn) -> {
                          Some(position.Position(file: file, rank: Three))
                        }
                        _ -> None
                      }
                    }
                    move.MoveWithCapture(
                      captured_piece: _captured_piece,
                      move: move.Normal(
                        from: position.Position(file: _, rank: Seven),
                        to: position.Position(file: file, rank: Five),
                        promotion: None,
                      ),
                    )
                      if game.turn == Black
                    -> {
                      let moving_piece = case
                        board.get_piece_at_position(
                          new_game_state.board,
                          position.Position(file: file, rank: Five),
                        )
                      {
                        Some(piece) -> piece
                        None ->
                          panic as "Undoing Castle Move: could not get piece at position 2"
                      }

                      case moving_piece {
                        piece.Piece(color: _, kind: Pawn) -> {
                          Some(position.Position(file: file, rank: Six))
                        }
                        _ -> None
                      }
                    }
                    _ -> None
                  }
                }
              }

              let new_status = case game.status {
                None -> None
                Some(InProgress(fifty_move_rule, threefold_repetition_rule)) -> {
                  case fifty_move_rule {
                    0 -> Some(InProgress(0, threefold_repetition_rule))
                    _ ->
                      Some(InProgress(
                        fifty_move_rule - 1,
                        threefold_repetition_rule,
                      ))
                  }
                }
                Some(_) ->
                  panic as "Undoing Castle Move: Trying to undo a move in a finished game"
              }

              let new_game_state =
                Game(
                  ..new_game_state,
                  turn: new_turn,
                  history: new_history,
                  ply: new_ply,
                  status: new_status,
                  white_kingside_castle: new_white_kingside_castle,
                  white_queenside_castle: new_white_queenside_castle,
                  black_kingside_castle: new_black_kingside_castle,
                  black_queenside_castle: new_black_queenside_castle,
                  en_passant: new_en_passant,
                )

              Ok(new_game_state)
            }

            move.MoveWithCapture(
              captured_piece: _captured_piece,
              move: move.EnPassant(from: from, to: to),
            ) -> {
              use new_board <- result.try(board.remove_piece_at_position(
                game.board,
                to,
              ))
              let new_game_state = Game(..game, board: new_board)
              let new_game_state = case game.turn {
                Black ->
                  Game(
                    ..new_game_state,
                    board: board.set_piece_at_position(
                      new_game_state.board,
                      from,
                      piece.Piece(color: White, kind: Pawn),
                    ),
                  )
                White ->
                  Game(
                    ..new_game_state,
                    board: board.set_piece_at_position(
                      new_game_state.board,
                      from,
                      piece.Piece(color: Black, kind: Pawn),
                    ),
                  )
              }
              let new_game_state = case game.turn {
                Black -> {
                  Game(
                    ..new_game_state,
                    board: board.set_piece_at_position(
                      new_game_state.board,
                      position.Position(file: to.file, rank: Five),
                      piece.Piece(color: Black, kind: Pawn),
                    ),
                  )
                }
                White -> {
                  Game(
                    ..new_game_state,
                    board: board.set_piece_at_position(
                      new_game_state.board,
                      position.Position(file: to.file, rank: Four),
                      piece.Piece(color: White, kind: Pawn),
                    ),
                  )
                }
              }

              let new_ply = game.ply - 1

              let new_white_kingside_castle = case game.white_kingside_castle {
                Yes -> Yes
                No(ply) -> {
                  case ply == game.ply {
                    True -> Yes
                    False -> No(ply)
                  }
                }
              }

              let new_white_queenside_castle = case
                game.white_queenside_castle
              {
                Yes -> Yes
                No(ply) -> {
                  case ply == game.ply {
                    True -> Yes
                    False -> No(ply)
                  }
                }
              }

              let new_black_kingside_castle = case game.black_kingside_castle {
                Yes -> Yes
                No(ply) -> {
                  case ply == game.ply {
                    True -> Yes
                    False -> No(ply)
                  }
                }
              }

              let new_black_queenside_castle = case
                game.black_queenside_castle
              {
                Yes -> Yes
                No(ply) -> {
                  case ply == game.ply {
                    True -> Yes
                    False -> No(ply)
                  }
                }
              }

              let new_turn = {
                case game.turn {
                  White -> Black
                  Black -> White
                }
              }

              let new_history = rest

              let new_en_passant = to

              let new_status = case game.status {
                None -> None
                Some(InProgress(fifty_move_rule, threefold_repetition_rule)) -> {
                  case fifty_move_rule {
                    0 -> Some(InProgress(0, threefold_repetition_rule))
                    _ ->
                      Some(InProgress(
                        fifty_move_rule - 1,
                        threefold_repetition_rule,
                      ))
                  }
                }
                Some(_) ->
                  panic as "Undoing En Passant Move: Trying to undo a move in a finished game"
              }

              let new_game_state =
                Game(
                  ..new_game_state,
                  turn: new_turn,
                  history: new_history,
                  ply: new_ply,
                  status: new_status,
                  white_kingside_castle: new_white_kingside_castle,
                  white_queenside_castle: new_white_queenside_castle,
                  black_kingside_castle: new_black_kingside_castle,
                  black_queenside_castle: new_black_queenside_castle,
                  en_passant: Some(new_en_passant),
                )

              Ok(new_game_state)
            }
          }
        }
      }
    }
    Some(_) -> {
      Ok(game)
    }
  }
}

pub fn all_legal_moves(game: Game) -> Result(List(Move), _) {
  case game.status {
    Some(InProgress(_, _)) | None -> {
      let legal_moves = {
        use pseudo_legal_move_list <- result.try(
          generate_pseudo_legal_move_list(game, game.turn),
        )
        Ok(
          pseudo_legal_move_list
          |> list.filter(fn(move) {
            case is_move_legal(game, move) {
              Ok(legality) -> legality
              Error(_) -> False
            }
          }),
        )
      }
      legal_moves
    }
    Some(_) -> Ok([])
  }
}

pub fn print_board_from_fen(fen: String) {
  let parsed_fen = fen.from_string(fen)
  use board_map <- result.try(bitboard_repr_to_map_repr(parsed_fen.board))
  io.print("\n")
  io.print("   +---+---+---+---+---+---+---+---+")
  list.each(positions_in_printing_order, fn(pos) {
    let piece_to_print = result.unwrap(dict.get(board_map, pos), None)
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
  })
  io.print("\n")
  io.print("     a   b   c   d   e   f   g   h\n")
  Ok("Successfully printed board")
}
