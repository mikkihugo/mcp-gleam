import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import mcp_gleam/internal

pub type Resource {
  Resource(
    uri: String,
    name: String,
    description: Option(String),
    mime_type: Option(String),
    size: Option(Int),
  )
}

pub type Content {
  Text(uri: String, mime_type: Option(String), text: String)
  Binary(uri: String, mime_type: Option(String), blob: String)
}

pub fn new(uri: String, name: String) -> Resource {
  Resource(uri:, name:, description: None, mime_type: None, size: None)
}

pub fn description(resource: Resource, description: String) -> Resource {
  Resource(..resource, description: Some(description))
}

pub fn mime_type(resource: Resource, mime_type: String) -> Resource {
  Resource(..resource, mime_type: Some(mime_type))
}

pub fn size(resource: Resource, size: Int) -> Resource {
  Resource(..resource, size: Some(size))
}

pub fn content(uri: String) -> Content {
  Text(uri:, mime_type: None, text: "")
}

pub fn blob(content: Content, blob: String) -> Content {
  Binary(uri: content.uri, mime_type: content.mime_type, blob:)
}

pub fn text(content: Content, text: String) -> Content {
  Text(uri: content.uri, mime_type: content.mime_type, text:)
}

pub fn content_mime_type(content: Content, mime_type: String) -> Content {
  case content {
    Binary(_, _, _) -> Binary(..content, mime_type: Some(mime_type))
    Text(_, _, _) -> Text(..content, mime_type: Some(mime_type))
  }
}

pub fn decoder() -> Decoder(Resource) {
  use uri <- decode.field("uri", decode.string)
  use name <- decode.field("name", decode.string)
  use description <- internal.omittable_field("description", decode.string)
  use mime_type <- internal.omittable_field("mime_type", decode.string)
  use size <- internal.omittable_field("size", decode.int)
  decode.success(Resource(uri:, name:, description:, mime_type:, size:))
}

pub fn to_json(resource: Resource) -> Json {
  let Resource(uri:, name:, description:, mime_type:, size:) = resource
  [#("uri", json.string(uri)), #("name", json.string(name))]
  |> internal.omittable_to_json("description", description, json.string)
  |> internal.omittable_to_json("mimeType", mime_type, json.string)
  |> internal.omittable_to_json("size", size, json.int)
  |> json.object
}

pub fn content_decoder() -> Decoder(Content) {
  let text = {
    use uri <- decode.field("uri", decode.string)
    use mime_type <- internal.omittable_field("mimeType", decode.string)
    use text <- decode.field("text", decode.string)
    decode.success(Text(uri:, mime_type:, text:))
  }
  let binary = {
    use uri <- decode.field("uri", decode.string)
    use mime_type <- internal.omittable_field("mimeType", decode.string)
    use blob <- decode.field("blob", decode.string)
    decode.success(Binary(uri:, mime_type:, blob:))
  }

  decode.one_of(text, [binary])
}

pub fn content_to_json(content: Content) -> Json {
  case content {
    Text(uri:, mime_type:, text:) ->
      [#("uri", json.string(uri)), #("text", json.string(text))]
      |> internal.omittable_to_json("mimeType", mime_type, json.string)
      |> json.object
    Binary(uri:, mime_type:, blob:) ->
      [#("uri", json.string(uri)), #("blob", json.string(blob))]
      |> internal.omittable_to_json("mimeType", mime_type, json.string)
      |> json.object
  }
}
