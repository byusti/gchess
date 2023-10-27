# gchess
[![Package Version](https://img.shields.io/hexpm/v/gchess)](https://hex.pm/packages/gchess)

<!--[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gchess/) -->
## Intro

A chess library for Gleam.

```
  let game_actor =
    game.new_game_from_fen(
      "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQK2R w KQkq - 0 1",
    )
  game.print_board(game_actor)
  let assert list_of_moves = game.all_legal_moves(game_actor)
  list.each(list_of_moves, fn(move) { io.println(move.to_string(move)) })
  game.apply_move(
    game_actor,
    move.Castle(
      from: position.Position(file: position.E, rank: position.One),
      to: position.Position(file: position.G, rank: position.One),
    ),
  )
  game.print_board(game_actor)
```

## Features
get all legal moves\
make a move\
make a move using uci notation\
print game board to console\
print fen as board to console\

## TODO
My goal is to match the feature set of [binbo](https://github.com/DOBRO/binbo).
