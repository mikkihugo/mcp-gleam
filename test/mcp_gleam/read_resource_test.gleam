import birdie
import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import mcp_gleam/read_resource
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
  read_resource.request("file:///example.txt")
  |> test_case(
    title: "read resource request",
    encode: read_resource.request_to_json,
    decoder: read_resource.request_decoder(),
  )
}

pub fn response_test() {
  read_resource.response()
  |> read_resource.add_content(
    resource.content("file:///example.txt")
    |> resource.text("Resource content")
    |> resource.content_mime_type("text/plain"),
  )
  |> read_resource.add_content(
    resource.content("file:///example.png")
    |> resource.blob("base64-encoded-data")
    |> resource.content_mime_type("image/png"),
  )
  |> test_case(
    title: "read resource response",
    encode: read_resource.response_to_json,
    decoder: read_resource.response_decoder(),
  )
}
