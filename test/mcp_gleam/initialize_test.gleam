import birdie
import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import mcp_gleam/initialize
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
  initialize.request("client", "1.0.0")
  |> test_case(
    title: "initialize request with no capabilities",
    encode: initialize.request_to_json,
    decoder: initialize.request_decoder(),
  )
}

pub fn request_roots_test() {
  initialize.request("client", "1.0.0")
  |> initialize.with_roots(False)
  |> test_case(
    title: "initialize request with roots",
    encode: initialize.request_to_json,
    decoder: initialize.request_decoder(),
  )
}

pub fn request_everything_test() {
  initialize.request("client", "1.0.0")
  |> initialize.with_roots(True)
  |> initialize.with_sampling()
  |> test_case(
    title: "initialize request with everything",
    encode: initialize.request_to_json,
    decoder: initialize.request_decoder(),
  )
}

pub fn response_test() {
  initialize.response("server", "1.0.0")
  |> test_case(
    title: "initialize response no capabilities",
    encode: initialize.response_to_json,
    decoder: initialize.response_decoder(),
  )
}

pub fn response_instructions_test() {
  initialize.response("server", "1.0.0")
  |> initialize.instructions("do stuff")
  |> test_case(
    title: "initialize response with instructions",
    encode: initialize.response_to_json,
    decoder: initialize.response_decoder(),
  )
}

pub fn response_resources_test() {
  initialize.response("server", "1.0.0")
  |> initialize.with_resources(list_changed: True, subscribe: False)
  |> test_case(
    title: "initialize response with resources",
    encode: initialize.response_to_json,
    decoder: initialize.response_decoder(),
  )
}

pub fn response_everything_test() {
  initialize.response("server", "1.0.0")
  |> initialize.instructions("do stuff")
  |> initialize.with_resources(list_changed: True, subscribe: False)
  |> initialize.with_completions
  |> initialize.with_logging
  |> initialize.with_prompts(False)
  |> initialize.with_tools(True)
  |> test_case(
    title: "initialize response with everything",
    encode: initialize.response_to_json,
    decoder: initialize.response_decoder(),
  )
}
