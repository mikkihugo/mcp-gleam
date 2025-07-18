import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import mcp_gleam/internal

// Latest MCP Protocol Version: 2025-03-26
// Supported versions: 2025-03-26, 2024-11-05, 2024-10-07
const protocol_version = "2025-03-26"
const supported_versions = ["2025-03-26", "2024-11-05", "2024-10-07"]

pub type Request {
  Request(name: String, version: String, roots: Option(Roots), sampling: Bool)
}

pub type Roots {
  Roots(list_changed: Bool)
}

pub type Response {
  Response(
    name: String,
    version: String,
    instructions: Option(String),
    completions: Bool,
    logging: Bool,
    resources: Option(Resources),
    prompts: Option(Prompts),
    tools: Option(Tools),
  )
}

pub type Resources {
  Resources(list_changed: Bool, subscribe: Bool)
}

pub type Prompts {
  Prompts(list_changed: Bool)
}

pub type Tools {
  Tools(list_changed: Bool)
}

pub fn request(name: String, version: String) -> Request {
  Request(name:, version:, roots: None, sampling: False)
}

pub fn with_roots(request: Request, list_changed: Bool) -> Request {
  Request(..request, roots: Some(Roots(list_changed:)))
}

pub fn with_sampling(request: Request) -> Request {
  Request(..request, sampling: True)
}

pub fn response(name: String, version: String) -> Response {
  Response(
    name:,
    version:,
    instructions: None,
    completions: False,
    logging: False,
    resources: None,
    prompts: None,
    tools: None,
  )
}

pub fn instructions(response: Response, instructions: String) -> Response {
  Response(..response, instructions: Some(instructions))
}

pub fn with_completions(response: Response) -> Response {
  Response(..response, completions: True)
}

pub fn with_logging(response: Response) -> Response {
  Response(..response, logging: True)
}

pub fn with_prompts(response: Response, list_changed: Bool) -> Response {
  Response(..response, prompts: Some(Prompts(list_changed:)))
}

pub fn with_resources(
  response response: Response,
  list_changed list_changed: Bool,
  subscribe subscribe: Bool,
) -> Response {
  Response(..response, resources: Some(Resources(list_changed:, subscribe:)))
}

pub fn with_tools(response: Response, list_changed: Bool) -> Response {
  Response(..response, tools: Some(Tools(list_changed:)))
}

pub fn request_decoder() -> decode.Decoder(Request) {
  use _ <- decode.field("protocolVersion", version_decoder())
  use name <- decode.subfield(["clientInfo", "name"], decode.string)
  use version <- decode.subfield(["clientInfo", "version"], decode.string)
  use roots <- internal.omittable_subfield(
    ["capabilities", "roots"],
    roots_decoder(),
  )
  use sampling <- internal.optional_subfield(
    ["capabilities", "sampling"],
    False,
    internal.empty_object_decoder(),
  )

  decode.success(Request(name:, version:, roots:, sampling:))
}

pub fn request_to_json(request: Request) -> json.Json {
  let Request(name:, version:, roots:, sampling:) = request
  let client_info =
    json.object([
      #("name", json.string(name)),
      #("version", json.string(version)),
    ])
  let capabilities =
    []
    |> internal.omittable_to_json("roots", roots, roots_to_json)
    |> internal.empty_object_field_to_json("sampling", sampling)
    |> json.object

  json.object([
    #("protocolVersion", json.string(protocol_version)),
    #("clientInfo", client_info),
    #("capabilities", capabilities),
  ])
}

fn roots_decoder() -> decode.Decoder(Roots) {
  use list_changed <- decode.optional_field("listChanged", False, decode.bool)
  decode.success(Roots(list_changed:))
}

fn roots_to_json(roots: Roots) -> json.Json {
  let Roots(list_changed:) = roots
  json.object([#("listChanged", json.bool(list_changed))])
}

pub fn response_decoder() -> decode.Decoder(Response) {
  use _ <- decode.field("protocolVersion", version_decoder())
  use name <- decode.subfield(["serverInfo", "name"], decode.string)
  use version <- decode.subfield(["serverInfo", "version"], decode.string)
  use instructions <- internal.omittable_field("instructions", decode.string)
  use completions <- internal.optional_subfield(
    ["capabilities", "completions"],
    False,
    internal.empty_object_decoder(),
  )
  use logging <- internal.optional_subfield(
    ["capabilities", "logging"],
    False,
    internal.empty_object_decoder(),
  )
  use resources <- internal.optional_subfield(
    ["capabilities", "resources"],
    None,
    decode.optional(resources_decoder()),
  )
  use prompts <- internal.optional_subfield(
    ["capabilities", "prompts"],
    None,
    decode.optional(prompts_decoder()),
  )
  use tools <- internal.optional_subfield(
    ["capabilities", "tools"],
    None,
    decode.optional(tools_decoder()),
  )
  decode.success(Response(
    name:,
    version:,
    instructions:,
    completions:,
    logging:,
    resources:,
    prompts:,
    tools:,
  ))
}

pub fn response_to_json(response: Response) -> json.Json {
  let Response(
    name:,
    version:,
    instructions:,
    completions:,
    logging:,
    resources:,
    prompts:,
    tools:,
  ) = response
  let server_info =
    json.object([
      #("name", json.string(name)),
      #("version", json.string(version)),
    ])

  let capabilities =
    []
    |> internal.empty_object_field_to_json("completions", completions)
    |> internal.empty_object_field_to_json("logging", logging)
    |> internal.omittable_to_json("resources", resources, resources_to_json)
    |> internal.omittable_to_json("prompts", prompts, prompts_to_json)
    |> internal.omittable_to_json("tools", tools, tools_to_json)
    |> json.object

  [
    #("protocolVersion", json.string(protocol_version)),
    #("serverInfo", server_info),
    #("capabilities", capabilities),
  ]
  |> internal.omittable_to_json("instructions", instructions, json.string)
  |> json.object
}

fn resources_decoder() -> decode.Decoder(Resources) {
  use list_changed <- decode.optional_field("listChanged", False, decode.bool)
  use subscribe <- decode.optional_field("subscribe", False, decode.bool)
  decode.success(Resources(list_changed:, subscribe:))
}

fn resources_to_json(resources: Resources) -> json.Json {
  let Resources(list_changed:, subscribe:) = resources
  json.object([
    #("listChanged", json.bool(list_changed)),
    #("subscribe", json.bool(subscribe)),
  ])
}

fn prompts_decoder() -> decode.Decoder(Prompts) {
  use list_changed <- decode.optional_field("listChanged", False, decode.bool)
  decode.success(Prompts(list_changed:))
}

fn prompts_to_json(prompts: Prompts) -> json.Json {
  let Prompts(list_changed:) = prompts
  json.object([#("listChanged", json.bool(list_changed))])
}

fn tools_decoder() -> decode.Decoder(Tools) {
  use list_changed <- decode.optional_field("listChanged", False, decode.bool)
  decode.success(Tools(list_changed:))
}

fn tools_to_json(tools: Tools) -> json.Json {
  let Tools(list_changed:) = tools
  json.object([#("listChanged", json.bool(list_changed))])
}

fn version_decoder() {
  decode.new_primitive_decoder("protocolVersion", fn(data) {
    case decode.run(data, decode.string) {
      Ok(v) -> {
        case list.contains(supported_versions, v) {
          True -> Ok(v)
          False -> Error("Unsupported protocol version: " <> v)
        }
      }
      Error(e) -> Error("Invalid protocol version format")
    }
  })
}
