import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None, Some}
import mcp_gleam/internal
import mcp_gleam/prompt.{type Prompt}

pub type Request {
  Request(next_cursor: Option(String))
}

pub type Response {
  Response(prompts: List(Prompt), next_cursor: Option(String))
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

pub fn add_prompt(response: Response, prompt: Prompt) -> Response {
  Response(..response, prompts: [prompt, ..response.prompts])
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
  use prompts <- decode.field("prompts", decode.list(prompt.decoder()))
  use next_cursor <- internal.omittable_field("nextCursor", decode.string)
  decode.success(Response(prompts:, next_cursor:))
}

pub fn response_to_json(response: Response) -> json.Json {
  let Response(prompts:, next_cursor:) = response
  [#("prompts", json.array(prompts, prompt.to_json))]
  |> internal.omittable_to_json("nextCursor", next_cursor, json.string)
  |> json.object
}
