# gchess
[![Package Version](https://img.shields.io/hexpm/v/gchess)](https://hex.pm/packages/gchess)

<!--[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gchess/) -->
## Intro

A chess library for Gleam.

```
  let game_actor =
    game_server.from_fen(
      "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
    )

  game_server.print_board(game_actor)

  game_server.all_legal_moves(game_actor)
  |> list.map(move.to_string)
  |> list.each(io.println)

  game_server.apply_move_uci(game_actor, "e2e4")

  game_server.print_board(game_actor)
```

## Features
get all legal moves\
make a move\
make a move using uci string\
convert game state to fen\
print board to console\
print fen string as board to console

chess rules implemented:
- castling
- en passant
- pawn promotion
- fifty move rule

## TODO
My goal is to match the interface of [binbo](https://github.com/DOBRO/binbo).
