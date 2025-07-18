import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import mcp_gleam/internal

pub type Prompt {
  Prompt(name: String, description: Option(String), arguments: List(Argument))
}

pub type Argument {
  Argument(name: String, description: Option(String), required: Bool)
}

pub fn new(name: String) -> Prompt {
  Prompt(name:, description: None, arguments: [])
}

pub fn description(prompt: Prompt, description: String) -> Prompt {
  Prompt(..prompt, description: Some(description))
}

pub fn add_argument(prompt: Prompt, argument: Argument) -> Prompt {
  Prompt(..prompt, arguments: [argument, ..prompt.arguments])
}

pub fn argument(name: String) -> Argument {
  Argument(name:, description: None, required: False)
}

pub fn argument_description(argument: Argument, description: String) -> Argument {
  Argument(..argument, description: Some(description))
}

pub fn required(argument: Argument, required: Bool) -> Argument {
  Argument(..argument, required:)
}

pub fn decoder() -> Decoder(Prompt) {
  use name <- decode.field("name", decode.string)
  use description <- internal.omittable_field("description", decode.string)
  use arguments <- decode.optional_field(
    "arguments",
    [],
    decode.list(argument_decoder()),
  )
  decode.success(Prompt(name:, description:, arguments:))
}

pub fn to_json(prompt: Prompt) -> Json {
  let Prompt(name:, description:, arguments:) = prompt
  [
    #("name", json.string(name)),
    #("arguments", json.array(arguments, argument_to_json)),
  ]
  |> internal.omittable_to_json("description", description, json.string)
  |> json.object
}

fn argument_decoder() -> Decoder(Argument) {
  use name <- decode.field("name", decode.string)
  use description <- internal.omittable_field("description", decode.string)
  use required <- decode.optional_field("required", False, decode.bool)
  decode.success(Argument(name:, description:, required:))
}

fn argument_to_json(argument: Argument) -> Json {
  let Argument(name:, description:, required:) = argument
  [#("name", json.string(name)), #("required", json.bool(required))]
  |> internal.omittable_to_json("description", description, json.string)
  |> json.object
}
