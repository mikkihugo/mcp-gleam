import birdie
import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import mcp_gleam/list_prompts
import mcp_gleam/prompt
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
  list_prompts.request()
  |> test_case(
    title: "list prompts request no cursor",
    encode: list_prompts.request_to_json,
    decoder: list_prompts.request_decoder(),
  )
}

pub fn request_next_cursor_test() {
  list_prompts.request_with_cursor("cursor")
  |> test_case(
    title: "list prompts request with next_cursor",
    encode: list_prompts.request_to_json,
    decoder: list_prompts.request_decoder(),
  )
}

pub fn response_test() {
  list_prompts.response()
  |> test_case(
    title: "list prompts response empty",
    encode: list_prompts.response_to_json,
    decoder: list_prompts.response_decoder(),
  )
}

pub fn response_with_prompt_test() {
  list_prompts.response()
  |> list_prompts.add_prompt(prompt.new("my prompt"))
  |> test_case(
    title: "list prompts response with prompt",
    encode: list_prompts.response_to_json,
    decoder: list_prompts.response_decoder(),
  )
}

pub fn response_everything_test() {
  list_prompts.response()
  |> list_prompts.add_prompt(prompt.new("my prompt"))
  |> list_prompts.add_prompt(
    prompt.new("code_review")
    |> prompt.description(
      "Asks the LLM to analyze code quality and suggest improvements",
    )
    |> prompt.add_argument(
      prompt.argument("code")
      |> prompt.argument_description("The code to review")
      |> prompt.required(True),
    ),
  )
  |> list_prompts.next_cursor("cursor")
  |> test_case(
    title: "list prompts response with everything",
    encode: list_prompts.response_to_json,
    decoder: list_prompts.response_decoder(),
  )
}
