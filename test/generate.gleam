import gleam/json
import mcp_toolkit_gleam/core/json_schema
import simplifile

pub fn main() {
  let assert Ok(content) = simplifile.read("json_spec.json")
  let assert Ok(schema) = json.decode(content, json_schema.decoder)
  let assert Ok(code) =
    json_schema.codegen()
    |> json_schema.root_name("PlaceHolderRootName")
    |> json_schema.generate(schema)

  simplifile.write("src/generated_spec.gleam", code)
}
