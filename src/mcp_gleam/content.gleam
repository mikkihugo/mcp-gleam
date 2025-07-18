import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import mcp_gleam/resource

pub type Content {
  Text(text: String)
  Image(data: String, mime_type: String)
  Audio(data: String, mime_type: String)
  EmbeddedResource(resource: resource.Content)
}

pub fn decoder() -> Decoder(Content) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "text" -> {
      use text <- decode.field("text", decode.string)
      decode.success(Text(text:))
    }
    "image" -> {
      use data <- decode.field("data", decode.string)
      use mime_type <- decode.field("mimeType", decode.string)
      decode.success(Image(data:, mime_type:))
    }
    "audio" -> {
      use data <- decode.field("data", decode.string)
      use mime_type <- decode.field("mimeType", decode.string)
      decode.success(Audio(data:, mime_type:))
    }
    "embedded_resource" -> {
      use resource <- decode.field("resource", resource.content_decoder())
      decode.success(EmbeddedResource(resource:))
    }
    _ -> decode.failure(Text(""), "Content")
  }
}

pub fn to_json(content: Content) -> Json {
  case content {
    Text(text:) ->
      json.object([#("type", json.string("text")), #("text", json.string(text))])
    Image(data:, mime_type:) ->
      json.object([
        #("type", json.string("image")),
        #("data", json.string(data)),
        #("mimeType", json.string(mime_type)),
      ])
    Audio(data:, mime_type:) ->
      json.object([
        #("type", json.string("audio")),
        #("data", json.string(data)),
        #("mimeType", json.string(mime_type)),
      ])
    EmbeddedResource(resource:) ->
      json.object([
        #("type", json.string("resource")),
        #("resource", resource.content_to_json(resource)),
      ])
  }
}
