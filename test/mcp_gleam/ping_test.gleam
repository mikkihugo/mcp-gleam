import birdie
import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import mcp_gleam/ping
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
  ping.request()
  |> test_case(
    title: "ping request",
    encode: ping.request_to_json,
    decoder: ping.request_decoder(),
  )
}

pub fn response_test() {
  ping.response()
  |> test_case(
    title: "ping response",
    encode: ping.response_to_json,
    decoder: ping.response_decoder(),
  )
}
