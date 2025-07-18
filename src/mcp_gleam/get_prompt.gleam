import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import mcp_gleam/content.{type Content}
import mcp_gleam/internal
import mcp_gleam/role.{type Role}

pub type Request(arguments) {
  Request(name: String, arguments: Option(arguments))
}

pub type Response {
  Response(description: Option(String), messages: List(Message))
}

pub type Message {
  Message(role: Role, content: Content)
}

pub fn request(name: String) -> Request(arguments) {
  Request(name:, arguments: None)
}

pub fn arguments(
  request: Request(a),
  arguments: arguments,
) -> Request(arguments) {
  Request(..request, arguments: Some(arguments))
}

pub fn response() -> Response {
  Response(None, [])
}

pub fn description(response: Response, description: String) -> Response {
  Response(..response, description: Some(description))
}

pub fn add_message(response: Response, message: Message) -> Response {
  Response(..response, messages: [message, ..response.messages])
}

pub fn request_decoder(
  arguments_decoder: Decoder(arguments),
) -> Decoder(Request(arguments)) {
  use name <- decode.field("name", decode.string)
  use arguments <- internal.omittable_field("arguments", arguments_decoder)
  decode.success(Request(name:, arguments:))
}

pub fn request_to_json(
  request: Request(arguments),
  arguments_to_json: fn(arguments) -> Json,
) -> Json {
  let Request(name:, arguments:) = request
  [#("name", json.string(name))]
  |> internal.omittable_to_json("arguments", arguments, arguments_to_json)
  |> json.object
}

pub fn response_decoder() -> Decoder(Response) {
  use description <- internal.omittable_field("description", decode.string)
  use messages <- decode.field("messages", decode.list(message_decoder()))
  decode.success(Response(description:, messages:))
}

pub fn response_to_json(response: Response) -> Json {
  let Response(description:, messages:) = response
  [#("messages", json.array(messages, message_to_json))]
  |> internal.omittable_to_json("description", description, json.string)
  |> json.object
}

fn message_decoder() -> Decoder(Message) {
  use role <- decode.field("role", role.decoder())
  use content <- decode.field("content", content.decoder())
  decode.success(Message(role:, content:))
}

fn message_to_json(message: Message) -> Json {
  let Message(role:, content:) = message
  json.object([
    #("role", role.to_json(role)),
    #("content", content.to_json(content)),
  ])
}
