pub type CastleRights {
  Yes
  No(ply: Int)
}

pub fn to_bool(castle_rights: CastleRights) -> Bool {
  case castle_rights {
    Yes -> True
    No(_) -> False
  }
}
