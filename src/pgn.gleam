import gleam/string
import gleam/list
import gleam/option.{type Option, None, Some}

pub fn split_movetext(pgn) -> List(String) {
  case pop_move(pgn) {
    Some(#(move, rest)) -> {
      list.append([move], split_movetext(rest))
    }
    None -> []
  }
}

pub fn pop_move(pgn) -> Option(#(String, String)) {
  case string.pop_grapheme(pgn) {
    Ok(#(index_first_digit, rest)) if index_first_digit == "1" || index_first_digit == "2" || index_first_digit == "3" || index_first_digit == "4" || index_first_digit == "5" || index_first_digit == "6" || index_first_digit == "7" || index_first_digit == "8" || index_first_digit == "9" -> {
      case string.split_once(rest, ".") {
        Error(_) -> panic("Could not parse move index")
        Ok(#(_index_rest_of_digits, rest)) -> {
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
                      Some(#(first_ply, ""))
                    }
                    _ -> {
                      Some(#(first_ply <> " " <> second_ply, rest))
                    }
                  }
                }

                Error(_) -> Some(#(first_ply <> " " <> rest, ""))
              }
            }
            Error(_) -> Some(#(rest, ""))
          }
        }
      }
    }
    Error(_) -> None
    _ -> panic("could not parse move")
  }
}

pub fn remove_tags(pgn: String) -> String {
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
