pub type Request

pub type Response

pub type Body

pub type Content

pub fn request(name: String) -> Request {
  todo
}

pub fn arguments(request: Request, arguments: Body) -> Request {
  todo
}

pub fn response() -> Response {
  todo
}

pub fn is_error(response: Response) -> Response {
  todo
}

pub fn add_content(response: Response, content: Content) -> Response {
  todo
}

pub fn annotations(content: Content, annotations) -> Content {
  todo
}

pub fn text(content: Content, text: String) -> Content {
  todo
}

pub fn image_data(content: Content, data: String) -> Content {
  todo
}

pub fn audio_data(content: Content, data: String) -> Content {
  todo
}

pub fn mime_type(content: Content, mime_type: String) -> Content {
  todo
}

pub fn resource_content(content: Content, resource_content) -> Content {
  todo
}
