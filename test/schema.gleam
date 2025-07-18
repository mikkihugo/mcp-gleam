import gleam/dynamic/decode
import gleam/json
import mcp_gleam/tool

type Box {
  Box(foo: Int, schema: tool.InputSchema)
}

fn encode_box(box: Box) -> json.Json {
  let Box(foo:, schema:) = box
  json.object([
    #("foo", json.int(foo)),
    #("schema", tool.input_schema_to_json(schema)),
  ])
}

fn box_decoder() -> decode.Decoder(Box) {
  use foo <- decode.field("foo", decode.int)
  use schema <- decode.field("schema", tool.input_schema_decoder())
  decode.success(Box(foo:, schema:))
}

pub fn main() {
  let schema = "{\"name\":\"Ryan\",\"age\":34}"
  let assert Ok(schema) = tool.input_schema(schema)
  let _ =
    Box(foo: 1, schema:)
    |> echo
    |> encode_box
    |> json.to_string
    |> echo
    |> json.parse(box_decoder())
    |> echo
  Nil
}
