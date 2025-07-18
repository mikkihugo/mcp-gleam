import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None, Some}
import mcp_gleam/internal
import mcp_gleam/tool.{type Tool}

pub type Request {
  Request(next_cursor: Option(String))
}

pub type Response {
  Response(tools: List(Tool), next_cursor: Option(String))
}

pub fn request() -> Request {
  Request(None)
}

pub fn request_with_cursor(next_cursor: String) -> Request {
  Request(Some(next_cursor))
}

pub fn response() -> Response {
  todo
}

pub fn next_cursor(response: Response, next_cursor: String) -> Response {
  todo
}

pub fn add_tool(response: Response, tool) -> Response {
  todo
}

pub fn request_decoder() -> decode.Decoder(Request) {
  use next_cursor <- internal.omittable_field("nextCursor", decode.string)
  decode.success(Request(next_cursor:))
}

pub fn request_to_json(request: Request) -> json.Json {
  let Request(next_cursor:) = request
  []
  |> internal.omittable_to_json("nextCursor", next_cursor, json.string)
  |> json.object
}
