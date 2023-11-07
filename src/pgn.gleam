import gleam/string
import gleam/list
import gleam/option.{type Option, None, Some}

// import game.{type Game}
// import move_san

// pub fn load_pgn(pgn: String) -> Game {
//   let game = game.new_game()
//   let pgn = string.trim(pgn)
//   let pgn = remove_tags(pgn)
//   let list_of_movetext = split_movetext(pgn)
//   list.fold(
//     list_of_movetext,
//     game,
//     fn(game, movetext) {
//       let game = case string.split(movetext, " ") {
//         [_index, white_ply, black_ply] -> {
//           let white_ply = move_san.from_string(white_ply)
//           let black_ply = move_san.from_string(black_ply)
//           todo
//         }
//         [index, white_ply] -> todo
//         [index] -> todo
//         _ -> panic("Invalid PGN")
//       }
//       game
//     },
//   )

//   todo
// }

pub fn split_movetext(pgn) -> List(String) {
  case pop_move(pgn) {
    Some(#(move, rest)) -> {
      list.append([move], split_movetext(rest))
    }
    None -> []
  }
}

fn pop_move(pgn) -> Option(#(String, String)) {
  case string.pop_grapheme(pgn) {
    Ok(#(index_first_digit, rest)) if index_first_digit == "1" || index_first_digit == "2" || index_first_digit == "3" || index_first_digit == "4" || index_first_digit == "5" || index_first_digit == "6" || index_first_digit == "7" || index_first_digit == "8" || index_first_digit == "9" -> {
      case string.split_once(rest, ".") {
        Error(_) -> panic("Could not parse move index")
        Ok(#(index_rest_of_digits, rest)) -> {
          let rest = string.trim(rest)
          case string.split_once(rest, " ") {
            Ok(#(first_ply, rest)) -> {
              case string.split_once(rest, " ") {
                Ok(#(second_ply, rest)) -> {
                  case string.first(second_ply) {
                    Ok("1")
                    | Ok("2")
                    | Ok("3")
                    | Ok("4")
                    | Ok("5")
                    | Ok("6")
                    | Ok("7")
                    | Ok("8")
                    | Ok("9")
                    | Error(_) -> {
                      Some(#(
                        index_first_digit <> index_rest_of_digits <> ". " <> first_ply,
                        "",
                      ))
                    }
                    _ -> {
                      Some(#(
                        index_first_digit <> index_rest_of_digits <> ". " <> first_ply <> " " <> second_ply,
                        rest,
                      ))
                    }
                  }
                }

                Error(_) ->
                  Some(#(
                    index_first_digit <> index_rest_of_digits <> ". " <> first_ply <> " " <> rest,
                    "",
                  ))
              }
            }
            Error(_) ->
              Some(#(
                index_first_digit <> index_rest_of_digits <> ". " <> rest,
                "",
              ))
          }
        }
      }
    }
    Error(_) -> None
    _ -> panic("could not parse move")
  }
}

fn remove_tags(pgn: String) -> String {
  case string.pop_grapheme(pgn) {
    Ok(#("[", rest)) -> {
      case string.split_once(rest, "]") {
        Error(_) -> panic("Invalid PGN")
        Ok(#(_tag_text, rest)) -> {
          remove_tags(rest)
        }
      }
    }
    _ -> pgn
  }
}