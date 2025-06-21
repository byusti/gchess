# gchess
[![Package Version](https://img.shields.io/hexpm/v/gchess)](https://hex.pm/packages/gchess) [![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gchess/)

A chess library for Gleam.

```
let server = new_server()

let assert Ok(_) = new_game_from_fen(
    server,
    "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
  )

print_board(server)

all_legal_moves(server)
|> list.map(move.to_string)
|> list.each(io.println)

let assert Ok(_) = apply_move_uci_string(server, "e2e4")

print_board(server)
```

## Installation

To get the most recent version of the library, I recommend cloning this repo into your gleam project directory and referencing it from within the .toml file of the project.

Assuming the cloned repo is at the root of the project directory, the .toml would look like this:
```
[dependencies]
gchess = { path = "gchess" }
```
