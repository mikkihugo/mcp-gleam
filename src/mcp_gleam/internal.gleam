import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option, None}

pub fn omittable_field(
  name: name,
  decoder: Decoder(a),
  next: fn(Option(a)) -> Decoder(b),
) -> Decoder(b) {
  decode.optional_field(name, option.None, decode.optional(decoder), next)
}

pub fn omittable_subfield(
  path: List(segment),
  decoder: Decoder(a),
  next: fn(Option(a)) -> Decoder(b),
) -> Decoder(b) {
  decode.optionally_at(path, None, decode.optional(decoder))
  |> decode.then(next)
}

pub fn omittable_to_json(
  object: List(#(String, Json)),
  key: String,
  value: option.Option(a),
  to_json: fn(a) -> Json,
) -> List(#(String, Json)) {
  case value {
    option.Some(value) -> [#(key, to_json(value)), ..object]
    option.None -> object
  }
}

pub fn optional_subfield(
  field_path: List(name),
  default: t,
  field_decoder: Decoder(t),
  next: fn(t) -> Decoder(final),
) {
  decode.optionally_at(field_path, default, field_decoder)
  |> decode.then(next)
}

pub fn empty_object_field(key: name, next: fn(Bool) -> Decoder(a)) -> Decoder(a) {
  decode.optional_field(key, False, decode.success(True), next)
}

pub fn empty_object_field_to_json(
  object: List(#(String, Json)),
  key: String,
  value: Bool,
) -> List(#(String, Json)) {
  case value {
    True -> [#(key, json.object([])), ..object]
    False -> object
  }
}

pub fn empty_object_decoder() -> Decoder(Bool) {
  use _ <- decode.map(decode.dict(decode.dynamic, decode.dynamic))
  True
}
