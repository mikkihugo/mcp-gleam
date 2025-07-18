import gleam/dynamic/decode
import gleam/json
import mcp_gleam/resource.{type Content}

pub type Request {
  Request(uri: String)
}

pub type Response {
  Response(contents: List(Content))
}

pub fn request(uri: String) -> Request {
  Request(uri:)
}

pub fn response() -> Response {
  Response([])
}

pub fn add_content(response: Response, content: Content) -> Response {
  Response(contents: [content, ..response.contents])
}

pub fn request_decoder() -> decode.Decoder(Request) {
  use uri <- decode.field("uri", decode.string)
  decode.success(Request(uri:))
}

pub fn request_to_json(request: Request) -> json.Json {
  let Request(uri:) = request
  json.object([#("uri", json.string(uri))])
}

pub fn response_decoder() -> decode.Decoder(Response) {
  use contents <- decode.field(
    "contents",
    decode.list(resource.content_decoder()),
  )
  decode.success(Response(contents:))
}

pub fn response_to_json(response: Response) -> json.Json {
  let Response(contents:) = response
  json.object([#("contents", json.array(contents, resource.content_to_json))])
}
