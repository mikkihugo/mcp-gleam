import birdie
import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import mcp_gleam/list_resources
import mcp_gleam/resource
import gleeunit/should

fn test_case(
  msg msg: msg,
  title title: String,
  encode encode: fn(msg) -> Json,
  decoder decoder: Decoder(msg),
) -> Nil {
  let json_string =
    msg
    |> encode
    |> json.to_string

  json_string |> birdie.snap(title:)

  json_string
  |> json.parse(using: decoder)
  |> should.equal(Ok(msg))
}

pub fn request_test() {
  list_resources.request()
  |> test_case(
    title: "list resources request no cursor",
    encode: list_resources.request_to_json,
    decoder: list_resources.request_decoder(),
  )
}

pub fn request_next_cursor_test() {
  list_resources.request_with_cursor("cursor")
  |> test_case(
    title: "list resources request with next_cursor",
    encode: list_resources.request_to_json,
    decoder: list_resources.request_decoder(),
  )
}

pub fn response_test() {
  list_resources.response()
  |> test_case(
    title: "list resources response empty",
    encode: list_resources.response_to_json,
    decoder: list_resources.response_decoder(),
  )
}

pub fn response_with_resource_test() {
  list_resources.response()
  |> list_resources.add_resource(resource.new(
    "file:///example.txt",
    "my resource",
  ))
  |> test_case(
    title: "list resources response with resource",
    encode: list_resources.response_to_json,
    decoder: list_resources.response_decoder(),
  )
}

pub fn response_everything_test() {
  list_resources.response()
  |> list_resources.add_resource(resource.new(
    "file:///example.txt",
    "my resource",
  ))
  |> list_resources.add_resource(resource.new(
    "file:///another.txt",
    "another resource",
  ))
  |> list_resources.next_cursor("cursor")
  |> test_case(
    title: "list resources response with everything",
    encode: list_resources.response_to_json,
    decoder: list_resources.response_decoder(),
  )
}
