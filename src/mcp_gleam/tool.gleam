import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}

pub type Tool {
  Tool(
    name: String,
    input_schema: InputSchema,
    description: Option(String),
    annotations: Option(Annotations),
  )
}

pub type Annotations {
  Annotations(
    title: Option(String),
    read_only_hint: Bool,
    destructive_hint: Bool,
    idempotent_hint: Bool,
    open_world_hint: Bool,
  )
}

pub type InputSchema

pub fn new(name: String, input_schema: InputSchema) -> Tool {
  Tool(name:, input_schema:, description: None, annotations: None)
}

pub fn description(tool: Tool, description: String) -> Tool {
  Tool(..tool, description: Some(description))
}

pub fn with_annotations(tool: Tool, annotations: Annotations) -> Tool {
  Tool(..tool, annotations: Some(annotations))
}

pub fn annotations() {
  Annotations(
    title: None,
    read_only_hint: False,
    destructive_hint: True,
    idempotent_hint: False,
    open_world_hint: True,
  )
}

pub fn title(annotations: Annotations, title: String) -> Annotations {
  Annotations(..annotations, title: Some(title))
}

pub fn read_only_hint(
  annotations: Annotations,
  read_only_hint: Bool,
) -> Annotations {
  Annotations(..annotations, read_only_hint:)
}

pub fn destructive_hint(
  annotations: Annotations,
  destructive_hint: Bool,
) -> Annotations {
  Annotations(..annotations, destructive_hint:)
}

pub fn idempotent_hint(
  annotations: Annotations,
  idempotent_hint: Bool,
) -> Annotations {
  Annotations(..annotations, idempotent_hint:)
}

pub fn open_world_hint(
  annotations: Annotations,
  open_world_hint: Bool,
) -> Annotations {
  Annotations(..annotations, open_world_hint:)
}

pub fn input_schema(json: String) -> Result(InputSchema, json.DecodeError) {
  string_to_json(json)
}

pub fn input_schema_decoder() -> Decoder(InputSchema) {
  decode.new_primitive_decoder("InputSchema", fn(data) { Ok(identity(data)) })
}

@external(erlang, "mcp_ffi", "input_schema_to_json")
@external(javascript, "../../gleam_stdlib/gleam_stdlib.mjs", "identity")
pub fn input_schema_to_json(schema: InputSchema) -> Json

@external(erlang, "gleam_json_ffi", "decode")
@external(javascript, "../../gleam_json/gleam_json_ffi.mjs", "decode")
fn string_to_json(json: String) -> Result(InputSchema, json.DecodeError)

@external(erlang, "gleam_stdlib", "identity")
@external(javascript, "../../gleam_stdlib/gleam_stdlib.mjs", "identity")
fn identity(a: a) -> b
