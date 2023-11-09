# gchess
[![Package Version](https://img.shields.io/hexpm/v/gchess)](https://hex.pm/packages/gchess)

[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gchess/)
## Intro

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

## Interface

### Creating game actor
```
let server = new_server()
```

### Initializing new game
```
new_game(server)
```

### Initializing game from fen
```
new_game_from_fen(server, fen)
```

### Making moves

```
let move =
  Normal(
    from: Position(file: E, rank: Two),
    to: Position(file: E, rank: Four),
    captured: None,
    promotion: None,
  )
apply_move(server, move)
```
```
apply_move_uci(server, "e2e4")
```
```
apply_move_san_string(server, "e4")
```

### Undoing moves
```
undo_move(server)
```

### Getting Fen
```
get_fen(server)
```