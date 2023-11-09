# gchess
[![Package Version](https://img.shields.io/hexpm/v/gchess)](https://hex.pm/packages/gchess) [![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gchess/)

A chess library for Gleam.

```
let server = new_server()

new_game_from_fen(
    server,
    "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
  )

print_board(server)

all_legal_moves(server)
|> list.map(move.to_string)
|> list.each(io.println)

apply_move_uci(server, "e2e4")

print_board(server)
```
