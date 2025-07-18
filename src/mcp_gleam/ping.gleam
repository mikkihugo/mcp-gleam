import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}

pub opaque type Request {
  Request
}

pub opaque type Response {
  Response
}

pub fn request() -> Request {
  Request
}

pub fn response() -> Response {
  Response
}

pub fn request_decoder() -> Decoder(Request) {
  decode.success(Request)
}

pub fn request_to_json(_request: Request) -> Json {
  json.object([])
}

pub fn response_decoder() -> Decoder(Response) {
  decode.success(Response)
}

pub fn response_to_json(_response: Response) -> Json {
  json.object([])
}
