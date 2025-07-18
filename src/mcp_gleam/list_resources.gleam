import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None, Some}
import mcp_gleam/internal
import mcp_gleam/resource.{type Resource}

pub type Request {
  Request(next_cursor: Option(String))
}

pub type Response {
  Response(resources: List(Resource), next_cursor: Option(String))
}

pub fn request() -> Request {
  Request(None)
}

pub fn request_with_cursor(next_cursor: String) -> Request {
  Request(Some(next_cursor))
}

pub fn response() -> Response {
  Response([], None)
}

pub fn add_resource(response: Response, resource: Resource) -> Response {
  Response(..response, resources: [resource, ..response.resources])
}

pub fn next_cursor(response: Response, next_cursor: String) -> Response {
  Response(..response, next_cursor: Some(next_cursor))
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

pub fn response_decoder() -> decode.Decoder(Response) {
  use resources <- decode.field("resources", decode.list(resource.decoder()))
  use next_cursor <- internal.omittable_field("nextCursor", decode.string)
  decode.success(Response(resources:, next_cursor:))
}

pub fn response_to_json(response: Response) -> json.Json {
  let Response(resources:, next_cursor:) = response
  [#("resources", json.array(resources, resource.to_json))]
  |> internal.omittable_to_json("nextCursor", next_cursor, json.string)
  |> json.object
}
