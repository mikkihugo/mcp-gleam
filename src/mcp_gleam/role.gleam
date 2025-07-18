import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}

pub type Role {
  User
  Assistant
}

pub fn decoder() -> Decoder(Role) {
  use variant <- decode.then(decode.string)
  case variant {
    "user" -> decode.success(User)
    "assistant" -> decode.success(Assistant)
    _ -> decode.failure(User, "Role")
  }
}

pub fn to_json(role: Role) -> Json {
  case role {
    User -> json.string("user")
    Assistant -> json.string("assistant")
  }
}
