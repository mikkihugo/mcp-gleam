import birdie
import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import mcp_gleam/content
import mcp_gleam/get_prompt
import mcp_gleam/prompt
import mcp_gleam/role
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

type Arg {
  Arg(code: String)
}

fn arg_decoder() -> Decoder(Arg) {
  use code <- decode.field("code", decode.string)
  decode.success(Arg(code:))
}

fn arg_to_json(arg: Arg) -> Json {
  let Arg(code:) = arg
  json.object([#("code", json.string(code))])
}

pub fn request_test() {
  get_prompt.request("code_review")
  |> get_prompt.arguments(Arg("def hello():\n    print('world')"))
  |> test_case(
    title: "get prompt request",
    encode: get_prompt.request_to_json(_, arg_to_json),
    decoder: get_prompt.request_decoder(arg_decoder()),
  )
}

pub fn response_test() {
  get_prompt.response()
  |> test_case(
    title: "get prompt response",
    encode: get_prompt.response_to_json,
    decoder: get_prompt.response_decoder(),
  )
}

pub fn response_everything_test() {
  get_prompt.response()
  |> get_prompt.description("Code review prompt")
  |> get_prompt.add_message(get_prompt.Message(
    role.User,
    content.Text(
      "Please review this Python code:\ndef hello():\n    print('world')",
    ),
  ))
  |> test_case(
    title: "get prompt response with everything",
    encode: get_prompt.response_to_json,
    decoder: get_prompt.response_decoder(),
  )
}
