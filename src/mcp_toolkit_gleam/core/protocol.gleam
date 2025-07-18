import gleam
import gleam/dict.{type Dict}
import gleam/dynamic/decode.{type Decoder}
import gleam/function
import gleam/json.{type Json}
import gleam/option.{type Option}
import mcp_toolkit_gleam/core/json_schema
import jsonrpc

// 2025-06-18 (Latest MCP Specification)
pub const protocol_version = "2025-06-18"

pub type McpError {
  ParseError
  InvalidRequest
  MethodNotFound
  InvalidParams
  InternalError
  ApplicationError(message: String)
}

pub type Annotations {
  // priority is a lie. The TS SDK doesn't have it.
  Annotations(audience: Option(List(Role)), priority: Option(Float))
}

pub fn annotations_decoder() -> Decoder(Annotations) {
  use audience <- omittable_field("audience", decode.list(role_decoder()))
  use priority <- omittable_field("priority", decode.float)
  decode.success(Annotations(audience:, priority:))
}

pub fn annotations_to_json(annotations: Annotations) -> Json {
  let Annotations(audience:, priority:) = annotations
  []
  |> omittable_to_json("audience", audience, json.array(_, role_to_json))
  |> omittable_to_json("priority", priority, json.float)
  |> json.object
}

pub type AudioContent {
  AudioContent(
    annotations: Option(Annotations),
    data: String,
    mime_type: String,
    type_: ContentType,
  )
}

pub fn audio_content_decoder() -> Decoder(AudioContent) {
  use type_ <- decode.field("type", content_type_decoder())
  use data <- decode.field("data", decode.string)
  use mime_type <- decode.field("mimeType", decode.string)
  use annotations <- omittable_field("annotations", annotations_decoder())
  decode.success(AudioContent(type_:, data:, mime_type:, annotations:))
}

pub fn audio_content_to_json(audio_content: AudioContent) -> Json {
  let AudioContent(type_:, data:, mime_type:, annotations:) = audio_content
  [
    #("type", content_type_to_json(type_)),
    #("data", json.string(data)),
    #("mimeType", json.string(mime_type)),
  ]
  |> omittable_to_json("annotations", annotations, annotations_to_json)
  |> json.object
}

pub type BlobResourceContents {
  BlobResourceContents(blob: String, mime_type: Option(String), uri: String)
}

pub fn blob_resource_contents_decoder() -> Decoder(BlobResourceContents) {
  use uri <- decode.field("uri", decode.string)
  use blob <- decode.field("blob", decode.string)
  use mime_type <- omittable_field("mimeType", decode.string)
  decode.success(BlobResourceContents(uri:, blob:, mime_type:))
}

pub fn blob_resource_contents_to_json(
  blob_resource_contents: BlobResourceContents,
) -> Json {
  let BlobResourceContents(uri:, blob:, mime_type:) = blob_resource_contents
  [#("uri", json.string(uri)), #("blob", json.string(blob))]
  |> omittable_to_json("mimeType", mime_type, json.string)
  |> json.object
}

// pub type CallToolRequest {
//   CallToolRequest(method: String, params: CallToolRequestParams)
// }

pub type CallToolRequest(arguments) {
  CallToolRequest(name: String, arguments: Option(arguments))
}

pub fn call_tool_request_decoder(
  arguments_decoder: Decoder(arguments),
) -> Decoder(CallToolRequest(arguments)) {
  use name <- decode.field("name", decode.string)
  use arguments <- omittable_field("arguments", arguments_decoder)
  decode.success(CallToolRequest(name:, arguments:))
}

pub fn call_tool_request_to_json(
  call_tool_request: CallToolRequest(arguments),
  to_json: fn(arguments) -> Json,
) -> Json {
  let CallToolRequest(name:, arguments:) = call_tool_request
  [#("name", json.string(name))]
  |> omittable_to_json("arguments", arguments, to_json)
  |> json.object
}

pub type ToolResultContent {
  TextToolContent(TextContent)
  ImageToolContent(ImageContent)
  AudioToolContent(AudioContent)
  ResourceToolContent(EmbeddedResource)
}

pub fn tool_result_content_decoder() -> Decoder(ToolResultContent) {
  let text = text_content_decoder() |> decode.map(TextToolContent)
  let image = image_content_decoder() |> decode.map(ImageToolContent)
  let audio = audio_content_decoder() |> decode.map(AudioToolContent)
  let resource = embedded_resource_decoder() |> decode.map(ResourceToolContent)
  decode.one_of(text, [image, audio, resource])
}

pub fn tool_result_content_to_json(
  tool_result_content: ToolResultContent,
) -> Json {
  case tool_result_content {
    TextToolContent(content) -> text_content_to_json(content)
    ImageToolContent(content) -> image_content_to_json(content)
    AudioToolContent(content) -> audio_content_to_json(content)
    ResourceToolContent(content) -> embedded_resource_to_json(content)
  }
}

pub type CallToolResult {
  CallToolResult(
    meta: Option(Meta),
    content: List(ToolResultContent),
    is_error: Option(Bool),
  )
}

pub fn call_tool_result_decoder() -> Decoder(CallToolResult) {
  use meta <- omittable_field("_meta", meta_decoder())
  use content <- decode.field(
    "content",
    decode.list(tool_result_content_decoder()),
  )
  use is_error <- omittable_field("isError", decode.bool)
  decode.success(CallToolResult(meta:, content:, is_error:))
}

pub fn call_tool_result_to_json(call_tool_result: CallToolResult) -> Json {
  let CallToolResult(content:, is_error:, meta:) = call_tool_result

  [#("content", json.array(content, tool_result_content_to_json))]
  |> omittable_to_json("isError", is_error, json.bool)
  |> omittable_to_json("_meta", meta, meta_to_json)
  |> json.object
}

pub type Meta {
  Meta(progress_token: Option(ProgressToken))
}

pub fn meta_decoder() -> Decoder(Meta) {
  use progress_token <- omittable_field(
    "progressToken",
    progress_token_decoder(),
  )
  decode.success(Meta(progress_token:))
}

pub fn meta_to_json(meta: Meta) -> Json {
  []
  |> omittable_to_json(
    "progressToken",
    meta.progress_token,
    progress_token_to_json,
  )
  |> json.object
}

// pub type CancelledNotification {
//   CancelledNotification(method: String, params: CancelledNotificationParams)
// }

pub type RequestId =
  jsonrpc.Id

pub type CancelledNotification {
  CancelledNotification(reason: Option(String), request_id: RequestId)
}

pub fn cancelled_notification_decoder() -> Decoder(CancelledNotification) {
  use reason <- omittable_field("reason", decode.string)
  use request_id <- decode.field("requestId", jsonrpc.id_decoder())
  decode.success(CancelledNotification(reason:, request_id:))
}

pub fn cancelled_notification_to_json(
  cancelled_notification: CancelledNotification,
) -> Json {
  let CancelledNotification(reason:, request_id:) = cancelled_notification
  [#("requestId", jsonrpc.id_to_json(request_id))]
  |> omittable_to_json("reason", reason, json.string)
  |> json.object
}

pub type ClientCapabilities {
  ClientCapabilities(
    // experimental: Option(Dict(String, Dynamic)),
    roots: Option(ClientCapabilitiesRoots),
    sampling: Option(ClientCapabilitiesSampling),
  )
}

pub fn client_capabilities_decoder() -> Decoder(ClientCapabilities) {
  use roots <- omittable_field("roots", client_capabilities_roots_decoder())
  use sampling <- omittable_field(
    "sampling",
    client_capabilities_sampling_decoder(),
  )
  decode.success(ClientCapabilities(roots:, sampling:))
}

pub fn client_capabilities_to_json(
  client_capabilities: ClientCapabilities,
) -> Json {
  let ClientCapabilities(roots:, sampling:) = client_capabilities
  []
  |> omittable_to_json("roots", roots, client_capabilities_roots_to_json)
  |> omittable_to_json(
    "sampling",
    sampling,
    client_capabilities_sampling_to_json,
  )
  |> json.object
}

pub type ClientCapabilitiesRoots {
  ClientCapabilitiesRoots(list_changed: Option(Bool))
}

pub fn client_capabilities_roots_decoder() -> Decoder(ClientCapabilitiesRoots) {
  use list_changed <- omittable_field("listChanged", decode.bool)
  decode.success(ClientCapabilitiesRoots(list_changed:))
}

pub fn client_capabilities_roots_to_json(
  client_capabilities_roots: ClientCapabilitiesRoots,
) -> Json {
  let ClientCapabilitiesRoots(list_changed:) = client_capabilities_roots
  []
  |> omittable_to_json("listChanged", list_changed, json.bool)
  |> json.object
}

pub type ClientCapabilitiesSampling {
  ClientCapabilitiesSampling
}

pub fn client_capabilities_sampling_decoder() -> Decoder(
  ClientCapabilitiesSampling,
) {
  decode.success(ClientCapabilitiesSampling)
}

pub fn client_capabilities_sampling_to_json(
  _client_capabilities_sampling: ClientCapabilitiesSampling,
) -> Json {
  json.object([])
}

// pub type CompleteRequest {
//   CompleteRequest(method: String, params: CompleteRequestParams)
// }

pub type CompleteRequest {
  CompleteRequest(
    argument: CompleteRequestArgument,
    ref: CompleteRequestReference,
  )
}

pub fn complete_request_decoder() -> Decoder(CompleteRequest) {
  use argument <- decode.field("argument", complete_request_argument_decoder())
  use ref <- decode.field("ref", complete_request_reference_decoder())
  decode.success(CompleteRequest(argument:, ref:))
}

pub fn complete_request_to_json(complete_request: CompleteRequest) -> Json {
  let CompleteRequest(argument:, ref:) = complete_request
  json.object([
    #("argument", complete_request_argument_to_json(argument)),
    #("ref", complete_request_reference_to_json(ref)),
  ])
}

pub type CompleteRequestArgument {
  CompleteRequestArgument(name: String, value: String)
}

pub fn complete_request_argument_decoder() -> Decoder(CompleteRequestArgument) {
  use name <- decode.field("name", decode.string)
  use value <- decode.field("value", decode.string)
  decode.success(CompleteRequestArgument(name:, value:))
}

pub fn complete_request_argument_to_json(
  complete_request_argument: CompleteRequestArgument,
) -> Json {
  let CompleteRequestArgument(name:, value:) = complete_request_argument
  json.object([#("name", json.string(name)), #("value", json.string(value))])
}

pub type CompleteRequestReference {
  CompleteRequestPromptReference(PromptReference)
  CompleteRequestResourceReference(ResourceReference)
}

pub fn complete_request_reference_decoder() -> Decoder(CompleteRequestReference) {
  let prompt =
    prompt_reference_decoder() |> decode.map(CompleteRequestPromptReference)
  let resource =
    resource_reference_decoder() |> decode.map(CompleteRequestResourceReference)
  decode.one_of(resource, [prompt])
}

pub fn complete_request_reference_to_json(
  complete_request_reference: CompleteRequestReference,
) -> Json {
  case complete_request_reference {
    CompleteRequestPromptReference(ref) -> prompt_reference_to_json(ref)
    CompleteRequestResourceReference(ref) -> resource_reference_to_json(ref)
  }
}

pub type CompleteResult {
  CompleteResult(meta: Option(Meta), completion: Completion)
}

pub fn complete_result_decoder() -> Decoder(CompleteResult) {
  use meta <- omittable_field("_meta", meta_decoder())
  use completion <- decode.field("completion", completion_decoder())
  decode.success(CompleteResult(meta:, completion:))
}

pub fn complete_result_to_json(complete_result: CompleteResult) -> Json {
  let CompleteResult(meta:, completion:) = complete_result
  [#("completion", completion_to_json(completion))]
  |> omittable_to_json("_meta", meta, meta_to_json)
  |> json.object
}

pub type Completion {
  Completion(has_more: Option(Bool), total: Option(Int), values: List(String))
}

pub fn completion_decoder() -> Decoder(Completion) {
  use has_more <- omittable_field("hasMore", decode.bool)
  use total <- omittable_field("total", decode.int)
  use values <- decode.field("values", decode.list(decode.string))
  decode.success(Completion(has_more:, total:, values:))
}

pub fn completion_to_json(completion: Completion) -> Json {
  let Completion(has_more:, total:, values:) = completion
  [#("values", json.array(values, json.string))]
  |> omittable_to_json("hasMore", has_more, json.bool)
  |> omittable_to_json("total", total, json.int)
  |> json.object
}

pub type ContentType {
  ContentTypeText
  ContentTypeImage
  ContentTypeAudio
  ContentTypeResource
}

pub fn content_type_decoder() -> Decoder(ContentType) {
  use variant <- decode.then(decode.string)
  case variant {
    "text" -> decode.success(ContentTypeText)
    "image" -> decode.success(ContentTypeImage)
    "audio" -> decode.success(ContentTypeAudio)
    "resource" -> decode.success(ContentTypeResource)
    _ -> decode.failure(ContentTypeText, "ContentType")
  }
}

pub fn content_type_to_json(content_type: ContentType) -> Json {
  case content_type {
    ContentTypeText -> json.string("text")
    ContentTypeImage -> json.string("image")
    ContentTypeAudio -> json.string("audio")
    ContentTypeResource -> json.string("resource")
  }
}

// pub type CreateMessageRequest {
//   CreateMessageRequest(method: String, params: CreateMessageRequestParams)
// }

pub type CreateMessageRequest(metadata) {
  CreateMessageRequest(
    include_context: Option(IncludeContext),
    max_tokens: Int,
    messages: List(SamplingMessage),
    metadata: Option(metadata),
    model_preferences: Option(ModelPreferences),
    stop_sequences: Option(List(String)),
    system_prompt: Option(String),
    temperature: Option(Int),
  )
}

pub fn create_message_request_decoder(
  metadata_decoder: Decoder(metadata),
) -> Decoder(CreateMessageRequest(metadata)) {
  use include_context <- omittable_field(
    "includeContext",
    include_context_decoder(),
  )
  use max_tokens <- decode.field("maxTokens", decode.int)
  use messages <- decode.field(
    "messages",
    decode.list(sampling_message_decoder()),
  )
  use metadata <- omittable_field("metadata", metadata_decoder)
  use model_preferences <- omittable_field(
    "modelPreferences",
    model_preferences_decoder(),
  )
  use stop_sequences <- omittable_field(
    "stopSequences",
    decode.list(decode.string),
  )
  use system_prompt <- omittable_field("systemPrompt", decode.string)
  use temperature <- omittable_field("temperature", decode.int)
  decode.success(CreateMessageRequest(
    include_context:,
    max_tokens:,
    messages:,
    metadata:,
    model_preferences:,
    stop_sequences:,
    system_prompt:,
    temperature:,
  ))
}

pub fn create_message_request_to_json(
  create_message_request: CreateMessageRequest(metadata),
  to_json: fn(metadata) -> Json,
) -> Json {
  let CreateMessageRequest(
    include_context:,
    max_tokens:,
    messages:,
    metadata:,
    model_preferences:,
    stop_sequences:,
    system_prompt:,
    temperature:,
  ) = create_message_request
  [
    #("maxTokens", json.int(max_tokens)),
    #("messages", json.array(messages, sampling_message_to_json)),
  ]
  |> omittable_to_json(
    "includeContext",
    include_context,
    include_context_to_json,
  )
  |> omittable_to_json("metadata", metadata, to_json)
  |> omittable_to_json(
    "modelPreferences",
    model_preferences,
    model_preferences_to_json,
  )
  |> omittable_to_json("stopSequences", stop_sequences, json.array(
    _,
    json.string,
  ))
  |> omittable_to_json("systemPrompt", system_prompt, json.string)
  |> omittable_to_json("temperature", temperature, json.int)
  |> json.object
}

pub type IncludeContext {
  AllServers
  None
  ThisServer
}

pub fn include_context_decoder() -> Decoder(IncludeContext) {
  use variant <- decode.then(decode.string)
  case variant {
    "allServers" -> decode.success(AllServers)
    "none" -> decode.success(None)
    "thisServer" -> decode.success(ThisServer)
    _ -> decode.failure(None, "IncludeContext")
  }
}

pub fn include_context_to_json(include_context: IncludeContext) -> Json {
  case include_context {
    AllServers -> json.string("allServers")
    None -> json.string("none")
    ThisServer -> json.string("thisServer")
  }
}

pub type CreateMessageResult {
  CreateMessageResult(
    meta: Option(Meta),
    content: MessageContent,
    model: String,
    role: Role,
    stop_reason: Option(String),
  )
}

pub fn create_message_result_decoder() -> Decoder(CreateMessageResult) {
  use meta <- omittable_field("_meta", meta_decoder())
  use content <- decode.field("content", message_content_decoder())
  use model <- decode.field("model", decode.string)
  use role <- decode.field("role", role_decoder())
  use stop_reason <- omittable_field("stopReason", decode.string)
  decode.success(CreateMessageResult(
    meta:,
    content:,
    model:,
    role:,
    stop_reason:,
  ))
}

pub fn create_message_result_to_json(
  create_message_result: CreateMessageResult,
) -> Json {
  let CreateMessageResult(meta:, content:, model:, role:, stop_reason:) =
    create_message_result
  [
    #("content", message_content_to_json(content)),
    #("model", json.string(model)),
    #("role", role_to_json(role)),
  ]
  |> omittable_to_json("_meta", meta, meta_to_json)
  |> omittable_to_json("stopReason", stop_reason, json.string)
  |> json.object
}

pub type MessageContent {
  TextMessageContent(TextContent)
  ImageMessageContent(ImageContent)
  AudioMessageContent(AudioContent)
}

pub fn message_content_decoder() {
  let text = text_content_decoder() |> decode.map(TextMessageContent)
  let image = image_content_decoder() |> decode.map(ImageMessageContent)
  let audio = audio_content_decoder() |> decode.map(AudioMessageContent)

  decode.one_of(text, [image, audio])
}

pub fn message_content_to_json(content) {
  case content {
    TextMessageContent(content) -> text_content_to_json(content)
    ImageMessageContent(content) -> image_content_to_json(content)
    AudioMessageContent(content) -> audio_content_to_json(content)
  }
}

pub type EmbeddedResource {
  EmbeddedResource(
    annotations: Option(Annotations),
    resource: ResourceContents,
    type_: String,
  )
}

pub fn embedded_resource_decoder() -> Decoder(EmbeddedResource) {
  use annotations <- omittable_field("annotations", annotations_decoder())
  use resource <- decode.field("resource", resource_contents_decoder())
  use type_ <- decode.field("type", decode.string)
  decode.success(EmbeddedResource(annotations:, resource:, type_:))
}

pub fn embedded_resource_to_json(embedded_resource: EmbeddedResource) -> Json {
  let EmbeddedResource(annotations:, resource:, type_:) = embedded_resource
  [
    #("resource", resource_contents_to_json(resource)),
    #("type", json.string(type_)),
  ]
  |> omittable_to_json("annotations", annotations, annotations_to_json)
  |> json.object
}

pub type ResourceContents {
  TextResource(TextResourceContents)
  BlobResource(BlobResourceContents)
}

pub fn resource_contents_decoder() {
  let text = text_resource_contents_decoder() |> decode.map(TextResource)
  let blob = blob_resource_contents_decoder() |> decode.map(BlobResource)
  decode.one_of(text, [blob])
}

pub fn resource_contents_to_json(resource_contents: ResourceContents) {
  case resource_contents {
    BlobResource(res) -> blob_resource_contents_to_json(res)
    TextResource(res) -> text_resource_contents_to_json(res)
  }
}

// pub type GetPromptRequest {
//   GetPromptRequest(method: String, params: GetPromptRequestParams)
// }

pub type GetPromptRequest {
  GetPromptRequest(arguments: Option(Dict(String, String)), name: String)
}

pub fn get_prompt_request_decoder() -> Decoder(GetPromptRequest) {
  use arguments <- omittable_field(
    "arguments",
    decode.dict(decode.string, decode.string),
  )
  use name <- decode.field("name", decode.string)
  decode.success(GetPromptRequest(arguments:, name:))
}

pub fn get_prompt_request_to_json(get_prompt_request: GetPromptRequest) -> Json {
  let GetPromptRequest(arguments:, name:) = get_prompt_request
  [#("name", json.string(name))]
  |> omittable_to_json("arguments", arguments, json.dict(
    _,
    function.identity,
    json.string,
  ))
  |> json.object
}

pub type GetPromptResult {
  GetPromptResult(
    meta: Option(Meta),
    description: Option(String),
    messages: List(PromptMessage),
  )
}

pub fn get_prompt_result_decoder() -> Decoder(GetPromptResult) {
  use meta <- omittable_field("_meta", meta_decoder())
  use description <- omittable_field("description", decode.string)
  use messages <- decode.field(
    "messages",
    decode.list(prompt_message_decoder()),
  )
  decode.success(GetPromptResult(meta:, description:, messages:))
}

pub fn get_prompt_result_to_json(get_prompt_result: GetPromptResult) -> Json {
  let GetPromptResult(meta:, description:, messages:) = get_prompt_result
  [#("messages", json.array(messages, prompt_message_to_json))]
  |> omittable_to_json("_meta", meta, meta_to_json)
  |> omittable_to_json("description", description, json.string)
  |> json.object
}

pub type ImageContent {
  ImageContent(
    annotations: Option(Annotations),
    data: String,
    mime_type: String,
    type_: String,
  )
}

pub fn image_content_decoder() -> Decoder(ImageContent) {
  use annotations <- omittable_field("annotations", annotations_decoder())
  use data <- decode.field("data", decode.string)
  use mime_type <- decode.field("mimeType", decode.string)
  use type_ <- decode.field("type", decode.string)
  decode.success(ImageContent(annotations:, data:, mime_type:, type_:))
}

pub fn image_content_to_json(image_content: ImageContent) -> Json {
  let ImageContent(annotations:, data:, mime_type:, type_:) = image_content
  [
    #("data", json.string(data)),
    #("mimeType", json.string(mime_type)),
    #("type", json.string(type_)),
  ]
  |> omittable_to_json("annotations", annotations, annotations_to_json)
  |> json.object
}

pub type Implementation {
  Implementation(name: String, version: String)
}

pub fn implementation_decoder() -> Decoder(Implementation) {
  use name <- decode.field("name", decode.string)
  use version <- decode.field("version", decode.string)
  decode.success(Implementation(name:, version:))
}

pub fn implementation_to_json(implementation: Implementation) -> Json {
  let Implementation(name:, version:) = implementation
  json.object([#("name", json.string(name)), #("version", json.string(version))])
}

// pub type InitializeRequest {
//   InitializeRequest(method: String, params: InitializeRequestParams)
// }

pub type InitializeRequest {
  InitializeRequest(
    capabilities: ClientCapabilities,
    client_info: Implementation,
    protocol_version: String,
  )
}

pub fn initialize_request_decoder() -> Decoder(InitializeRequest) {
  use capabilities <- decode.field(
    "capabilities",
    client_capabilities_decoder(),
  )
  use client_info <- decode.field("clientInfo", implementation_decoder())
  use protocol_version <- decode.field("protocolVersion", decode.string)
  decode.success(InitializeRequest(
    capabilities:,
    client_info:,
    protocol_version:,
  ))
}

pub fn initialize_request_to_json(initialize_request: InitializeRequest) -> Json {
  let InitializeRequest(capabilities:, client_info:, protocol_version:) =
    initialize_request
  json.object([
    #("capabilities", client_capabilities_to_json(capabilities)),
    #("clientInfo", implementation_to_json(client_info)),
    #("protocolVersion", json.string(protocol_version)),
  ])
}

pub type InitializeResult {
  InitializeResult(
    meta: Option(Meta),
    capabilities: ServerCapabilities,
    instructions: Option(String),
    protocol_version: String,
    server_info: Implementation,
  )
}

pub fn initialize_result_decoder() -> Decoder(InitializeResult) {
  use meta <- omittable_field("_meta", meta_decoder())
  use capabilities <- decode.field(
    "capabilities",
    server_capabilities_decoder(),
  )
  use instructions <- omittable_field("instructions", decode.string)
  use protocol_version <- decode.field("protocolVersion", decode.string)
  use server_info <- decode.field("serverInfo", implementation_decoder())
  decode.success(InitializeResult(
    meta:,
    capabilities:,
    instructions:,
    protocol_version:,
    server_info:,
  ))
}

pub fn initialize_result_to_json(initialize_result: InitializeResult) -> Json {
  let InitializeResult(
    meta:,
    capabilities:,
    instructions:,
    protocol_version:,
    server_info:,
  ) = initialize_result
  [
    #("capabilities", server_capabilities_to_json(capabilities)),
    #("protocolVersion", json.string(protocol_version)),
    #("serverInfo", implementation_to_json(server_info)),
  ]
  |> omittable_to_json("_meta", meta, meta_to_json)
  |> omittable_to_json("instructions", instructions, json.string)
  |> json.object
}

// pub type InitializedNotification {
//   InitializedNotification(
//     method: String,
//     params: Option(InitializedNotificationParams),
//   )
// }

pub type InitializedNotification {
  InitializedNotification(meta: Option(Meta))
}

pub fn initialized_notification_decoder() -> Decoder(InitializedNotification) {
  use meta <- omittable_field("_meta", meta_decoder())
  decode.success(InitializedNotification(meta:))
}

pub fn initialized_notification_to_json(
  initialized_notification: InitializedNotification,
) -> Json {
  let InitializedNotification(meta:) = initialized_notification
  [] |> omittable_to_json("_meta", meta, meta_to_json) |> json.object
}

/// Used for tracking progress of operations
pub type ProgressToken {
  ProgressTokenString(String)
  ProgressTokenInt(Int)
}

pub fn progress_token_decoder() {
  let string = decode.string |> decode.map(ProgressTokenString)
  let int = decode.int |> decode.map(ProgressTokenInt)
  decode.one_of(string, [int])
}

pub fn progress_token_to_json(token: ProgressToken) -> Json {
  case token {
    ProgressTokenString(s) -> json.string(s)
    ProgressTokenInt(i) -> json.int(i)
  }
}

// pub type ListPromptsRequest {
//   ListPromptsRequest(method: String, params: Option(ListPromptsRequestParams))
// }

pub type ListRequest {
  ListRequest(cursor: Option(String))
}

pub fn list_request_decoder() -> Decoder(ListRequest) {
  use cursor <- omittable_field("cursor", decode.string)
  decode.success(ListRequest(cursor:))
}

pub fn list_request_to_json(request: ListRequest) -> Json {
  [] |> omittable_to_json("cursor", request.cursor, json.string) |> json.object
}

pub type ListPromptsRequest =
  ListRequest

pub const list_prompts_request_decoder = list_request_decoder

pub const list_prompts_request_to_json = list_request_to_json

// pub type ListPromptsRequest {
//   ListPromptsRequest(cursor: Option(String))
// }

pub type ListPromptsResult {
  ListPromptsResult(
    meta: Option(Meta),
    next_cursor: Option(String),
    prompts: List(Prompt),
  )
}

pub fn list_prompts_result_decoder() -> Decoder(ListPromptsResult) {
  use meta <- omittable_field("_meta", meta_decoder())
  use next_cursor <- omittable_field("nextCursor", decode.string)
  use prompts <- decode.field("prompts", decode.list(prompt_decoder()))
  decode.success(ListPromptsResult(meta:, next_cursor:, prompts:))
}

pub fn list_prompts_result_to_json(
  list_prompts_result: ListPromptsResult,
) -> Json {
  let ListPromptsResult(meta:, next_cursor:, prompts:) = list_prompts_result
  [#("prompts", json.array(prompts, prompt_to_json))]
  |> omittable_to_json("_meta", meta, meta_to_json)
  |> omittable_to_json("nextCursor", next_cursor, json.string)
  |> json.object
}

pub type ListResourceTemplatesRequest =
  ListRequest

pub const list_resource_templates_request_decoder = list_request_decoder

pub const list_resource_templates_request_to_json = list_request_to_json

// pub type ListResourceTemplatesRequest {
//   ListResourceTemplatesRequest(
//     method: String,
//     params: Option(ListResourceTemplatesRequestParams),
//   )
// }

// pub type ListResourceTemplatesRequestParams {
//   ListResourceTemplatesRequestParams(cursor: Option(String))
// }

pub type ListResourceTemplatesResult {
  ListResourceTemplatesResult(
    meta: Option(Meta),
    next_cursor: Option(String),
    resource_templates: List(ResourceTemplate),
  )
}

pub fn list_resource_templates_result_decoder() -> Decoder(
  ListResourceTemplatesResult,
) {
  use meta <- omittable_field("_meta", meta_decoder())
  use next_cursor <- omittable_field("nextCursor", decode.string)
  use resource_templates <- decode.field(
    "resourceTemplates",
    decode.list(resource_template_decoder()),
  )
  decode.success(ListResourceTemplatesResult(
    meta:,
    next_cursor:,
    resource_templates:,
  ))
}

pub fn list_resource_templates_result_to_json(
  list_resource_templates_result: ListResourceTemplatesResult,
) -> Json {
  let ListResourceTemplatesResult(meta:, next_cursor:, resource_templates:) =
    list_resource_templates_result
  [
    #(
      "resourceTemplates",
      json.array(resource_templates, resource_template_to_json),
    ),
  ]
  |> omittable_to_json("_meta", meta, meta_to_json)
  |> omittable_to_json("nextCursor", next_cursor, json.string)
  |> json.object
}

pub type ListResourcesRequest =
  ListRequest

pub const list_resources_request_decoder = list_request_decoder

pub const list_resources_request_to_json = list_request_to_json

// pub type ListResourcesRequest {
//   ListResourcesRequest(
//     method: String,
//     params: Option(ListResourcesRequestParams),
//   )
// }

// pub type ListResourcesRequestParams {
//   ListResourcesRequestParams(cursor: Option(String))
// }

pub type ListResourcesResult {
  ListResourcesResult(
    meta: Option(Meta),
    next_cursor: Option(String),
    resources: List(Resource),
  )
}

pub fn list_resources_result_decoder() -> Decoder(ListResourcesResult) {
  use meta <- omittable_field("_meta", meta_decoder())
  use next_cursor <- omittable_field("nextCursor", decode.string)
  use resources <- decode.field("resources", decode.list(resource_decoder()))
  decode.success(ListResourcesResult(meta:, next_cursor:, resources:))
}

pub fn list_resources_result_to_json(
  list_resource_result: ListResourcesResult,
) -> Json {
  let ListResourcesResult(meta:, next_cursor:, resources:) =
    list_resource_result
  [#("resources", json.array(resources, resource_to_json))]
  |> omittable_to_json("_meta", meta, meta_to_json)
  |> omittable_to_json("nextCursor", next_cursor, json.string)
  |> json.object
}

// pub type ListRootsRequest {
//   ListRootsRequest(method: String, params: Option(ListRootsRequestParams))
// }

pub type ListRootsRequest {
  ListRootsRequestParams(meta: Option(Meta))
}

pub fn list_roots_request_decoder() -> Decoder(ListRootsRequest) {
  use meta <- omittable_field("_meta", meta_decoder())
  decode.success(ListRootsRequestParams(meta:))
}

pub fn list_roots_request_to_json(list_roots_request: ListRootsRequest) -> Json {
  let ListRootsRequestParams(meta:) = list_roots_request
  [] |> omittable_to_json("_meta", meta, meta_to_json) |> json.object
}

pub type ListRootsResult {
  ListRootsResult(meta: Option(Meta), roots: List(Root))
}

pub fn list_roots_result_decoder() -> Decoder(ListRootsResult) {
  use meta <- omittable_field("_meta", meta_decoder())
  use roots <- decode.field("roots", decode.list(root_decoder()))
  decode.success(ListRootsResult(meta:, roots:))
}

pub fn encode_list_roots_result(list_roots_result: ListRootsResult) -> Json {
  let ListRootsResult(meta:, roots:) = list_roots_result
  [#("roots", json.array(roots, root_to_json))]
  |> omittable_to_json("_meta", meta, meta_to_json)
  |> json.object
}

// pub type ListToolsRequest {
//   ListToolsRequest(method: String, params: Option(ListToolsRequestParams))
// }

pub type ListToolsRequest =
  ListRequest

pub const list_tools_request_decoder = list_request_decoder

pub const list_tools_request_to_json = list_request_to_json

pub type ListToolsResult {
  ListToolsResult(
    meta: Option(Meta),
    next_cursor: Option(String),
    tools: List(Tool),
  )
}

pub fn list_tools_result_decoder() -> Decoder(ListToolsResult) {
  use meta <- omittable_field("_meta", meta_decoder())
  use next_cursor <- omittable_field("nextCursor", decode.string)
  use tools <- decode.field("tools", decode.list(tool_decoder()))
  decode.success(ListToolsResult(meta:, next_cursor:, tools:))
}

pub fn list_tools_result_to_json(list_tools_result: ListToolsResult) -> Json {
  let ListToolsResult(meta:, next_cursor:, tools:) = list_tools_result
  [#("tools", json.array(tools, tool_to_json))]
  |> omittable_to_json("_meta", meta, meta_to_json)
  |> omittable_to_json("nextCursor", next_cursor, json.string)
  |> json.object
}

pub type LoggingLevel {
  Alert
  Critical
  Debug
  Emergency
  Error
  Info
  Notice
  Warning
}

pub fn logging_level_decoder() -> Decoder(LoggingLevel) {
  use variant <- decode.then(decode.string)
  case variant {
    "alert" -> decode.success(Alert)
    "critical" -> decode.success(Critical)
    "debug" -> decode.success(Debug)
    "emergency" -> decode.success(Emergency)
    "error" -> decode.success(Error)
    "info" -> decode.success(Info)
    "notice" -> decode.success(Notice)
    "warning" -> decode.success(Warning)
    _ -> decode.failure(Error, "LoggingLevel")
  }
}

pub fn logging_level_to_json(logging_level: LoggingLevel) -> Json {
  case logging_level {
    Alert -> json.string("alert")
    Critical -> json.string("critical")
    Debug -> json.string("debug")
    Emergency -> json.string("emergency")
    Error -> json.string("error")
    Info -> json.string("info")
    Notice -> json.string("notice")
    Warning -> json.string("warning")
  }
}

// pub type LoggingMessageNotification {
//   LoggingMessageNotification(
//     method: String,
//     params: LoggingMessageNotificationParams,
//   )
// }

pub type LoggingMessageNotification(data) {
  LoggingMessageNotification(
    data: data,
    level: LoggingLevel,
    logger: Option(String),
  )
}

pub fn logging_message_notification_decoder(
  data_decoder: Decoder(data),
) -> Decoder(LoggingMessageNotification(data)) {
  use data <- decode.field("data", data_decoder)
  use level <- decode.field("level", logging_level_decoder())
  use logger <- omittable_field("logger", decode.string)
  decode.success(LoggingMessageNotification(data:, level:, logger:))
}

pub fn logging_message_notification_to_json(
  logging_message_notification: LoggingMessageNotification(data),
  to_json: fn(data) -> Json,
) -> Json {
  let LoggingMessageNotification(data:, level:, logger:) =
    logging_message_notification
  [#("data", to_json(data)), #("level", logging_level_to_json(level))]
  |> omittable_to_json("logger", logger, json.string)
  |> json.object
}

pub type ModelHint {
  ModelHint(name: Option(String))
}

pub fn model_hint_decoder() -> Decoder(ModelHint) {
  use name <- omittable_field("name", decode.string)
  decode.success(ModelHint(name:))
}

pub fn model_hint_to_json(model_hint: ModelHint) -> Json {
  let ModelHint(name:) = model_hint
  [] |> omittable_to_json("name", name, json.string) |> json.object
}

pub type ModelPreferences {
  ModelPreferences(
    cost_priority: Option(Int),
    hints: Option(List(ModelHint)),
    intelligence_priority: Option(Int),
    speed_priority: Option(Int),
  )
}

pub fn model_preferences_decoder() -> Decoder(ModelPreferences) {
  use cost_priority <- omittable_field("costPriority", decode.int)
  use hints <- omittable_field("hints", decode.list(model_hint_decoder()))
  use intelligence_priority <- omittable_field(
    "intelligencePriority",
    decode.int,
  )
  use speed_priority <- omittable_field("speedPriority", decode.int)
  decode.success(ModelPreferences(
    cost_priority:,
    hints:,
    intelligence_priority:,
    speed_priority:,
  ))
}

pub fn model_preferences_to_json(model_preferences: ModelPreferences) -> Json {
  let ModelPreferences(
    cost_priority:,
    hints:,
    intelligence_priority:,
    speed_priority:,
  ) = model_preferences
  []
  |> omittable_to_json("costPriority", cost_priority, json.int)
  |> omittable_to_json("hints", hints, json.array(_, model_hint_to_json))
  |> omittable_to_json("intelligencePriority", intelligence_priority, json.int)
  |> omittable_to_json("speedPriority", speed_priority, json.int)
  |> json.object
}

// pub type Notification {
//   Notification(method: String, params: Option(NotificationParams))
// }

// pub type NotificationParams {
//   NotificationParams(meta: Option(Dict(String, Dynamic)))
// }

// pub type PaginatedRequest {
//   PaginatedRequest(method: String, params: Option(PaginatedRequestParams))
// }

// pub type PaginatedRequestParams {
//   PaginatedRequestParams(cursor: Option(String))
// }

// pub type PaginatedResult {
//   PaginatedResult(
//     meta: Option(Dict(String, Dynamic)),
//     next_cursor: Option(String),
//   )
// }

// pub type PingRequest {
//   PingRequest(method: String, params: Option(PingRequestParams))
// }

pub type PingRequest {
  PingRequest(meta: Option(Meta))
}

pub fn ping_request_decoder() -> Decoder(PingRequest) {
  use meta <- omittable_field("_meta", meta_decoder())
  decode.success(PingRequest(meta:))
}

pub fn ping_request_to_json(ping_request: PingRequest) -> Json {
  let PingRequest(meta:) = ping_request
  [] |> omittable_to_json("_meta", meta, meta_to_json) |> json.object
}

pub type PingResult {
  PingResult
}

pub fn ping_result_decoder() -> Decoder(PingResult) {
  decode.success(PingResult)
}

pub fn ping_result_to_json(_ping_result: PingResult) -> Json {
  json.object([])
}

// pub type ProgressNotification {
//   ProgressNotification(method: String, params: ProgressNotificationParams)
// }

pub type ProgressNotification {
  ProgressNotification(
    message: Option(String),
    progress: Int,
    progress_token: ProgressToken,
    total: Option(Int),
  )
}

pub fn progress_notification_decoder() -> Decoder(ProgressNotification) {
  use message <- omittable_field("message", decode.string)
  use progress <- decode.field("progress", decode.int)
  use progress_token <- decode.field("progressToken", progress_token_decoder())
  use total <- omittable_field("total", decode.int)
  decode.success(ProgressNotification(
    message:,
    progress:,
    progress_token:,
    total:,
  ))
}

pub fn progress_notification_to_json(
  progress_notification: ProgressNotification,
) -> Json {
  let ProgressNotification(message:, progress:, progress_token:, total:) =
    progress_notification
  json.object(
    [
      #("progress", json.int(progress)),
      #("progressToken", progress_token_to_json(progress_token)),
    ]
    |> omittable_to_json("message", message, json.string)
    |> omittable_to_json("total", total, json.int),
  )
}

pub type Prompt {
  Prompt(
    arguments: Option(List(PromptArgument)),
    description: Option(String),
    name: String,
  )
}

pub fn prompt_decoder() -> Decoder(Prompt) {
  use arguments <- omittable_field(
    "arguments",
    decode.list(prompt_argument_decoder()),
  )
  use description <- omittable_field("description", decode.string)
  use name <- decode.field("name", decode.string)
  decode.success(Prompt(arguments:, description:, name:))
}

pub fn prompt_to_json(prompt: Prompt) -> Json {
  let Prompt(arguments:, description:, name:) = prompt
  [#("name", json.string(name))]
  |> omittable_to_json("arguments", arguments, json.array(
    _,
    prompt_argument_to_json,
  ))
  |> omittable_to_json("description", description, json.string)
  |> json.object
}

pub type PromptArgument {
  PromptArgument(
    description: Option(String),
    name: String,
    required: Option(Bool),
  )
}

pub fn prompt_argument_decoder() -> Decoder(PromptArgument) {
  use description <- omittable_field("description", decode.string)
  use name <- decode.field("name", decode.string)
  use required <- omittable_field("required", decode.bool)
  decode.success(PromptArgument(description:, name:, required:))
}

pub fn prompt_argument_to_json(prompt_argument: PromptArgument) -> Json {
  let PromptArgument(description:, name:, required:) = prompt_argument
  [#("name", json.string(name))]
  |> omittable_to_json("description", description, json.string)
  |> omittable_to_json("required", required, json.bool)
  |> json.object
}

// pub type PromptListChangedNotification {
//   PromptListChangedNotification(
//     method: String,
//     params: Option(PromptListChangedNotificationParams),
//   )
// }

pub type PromptListChangedNotification {
  PromptListChangedNotification(meta: Option(Meta))
}

pub fn prompt_list_changed_notification_decoder() -> Decoder(
  PromptListChangedNotification,
) {
  use meta <- omittable_field("_meta", meta_decoder())
  decode.success(PromptListChangedNotification(meta:))
}

pub fn prompt_list_changed_notification_to_json(
  notification: PromptListChangedNotification,
) -> Json {
  let PromptListChangedNotification(meta:) = notification
  [] |> omittable_to_json("_meta", meta, meta_to_json) |> json.object
}

pub type PromptMessage {
  PromptMessage(content: PromptMessageContent, role: Role)
}

pub fn prompt_message_decoder() -> Decoder(PromptMessage) {
  use content <- decode.field("content", prompt_message_content_decoder())
  use role <- decode.field("role", role_decoder())
  decode.success(PromptMessage(content:, role:))
}

pub fn prompt_message_to_json(prompt_message: PromptMessage) -> Json {
  let PromptMessage(content:, role:) = prompt_message
  json.object([
    #("content", prompt_message_content_to_json(content)),
    #("role", role_to_json(role)),
  ])
}

pub type PromptMessageContent {
  TextPromptContent(TextContent)
  ImagePromptContent(ImageContent)
  AudioPromptContent(AudioContent)
  ResourcePromptContent(EmbeddedResource)
}

pub fn prompt_message_content_decoder() -> Decoder(PromptMessageContent) {
  let text = text_content_decoder() |> decode.map(TextPromptContent)
  let image = image_content_decoder() |> decode.map(ImagePromptContent)
  let audio = audio_content_decoder() |> decode.map(AudioPromptContent)
  let resource =
    embedded_resource_decoder() |> decode.map(ResourcePromptContent)

  decode.one_of(text, [image, audio, resource])
}

pub fn prompt_message_content_to_json(content: PromptMessageContent) -> Json {
  case content {
    TextPromptContent(content) -> text_content_to_json(content)
    ImagePromptContent(content) -> image_content_to_json(content)
    AudioPromptContent(content) -> audio_content_to_json(content)
    ResourcePromptContent(content) -> embedded_resource_to_json(content)
  }
}

pub type PromptReference {
  PromptReference(name: String, type_: String)
}

pub fn prompt_reference_decoder() -> Decoder(PromptReference) {
  use name <- decode.field("name", decode.string)
  use type_ <- decode.field("type", decode.string)
  decode.success(PromptReference(name:, type_:))
}

pub fn prompt_reference_to_json(prompt_reference: PromptReference) -> Json {
  let PromptReference(name:, type_:) = prompt_reference
  json.object([#("name", json.string(name)), #("type", json.string(type_))])
}

// pub type ReadResourceRequest {
//   ReadResourceRequest(method: String, params: ReadResourceRequestParams)
// }

pub type ReadResourceRequest {
  ReadResourceRequest(uri: String)
}

pub fn read_resource_request_decoder() -> Decoder(ReadResourceRequest) {
  use uri <- decode.field("uri", decode.string)
  decode.success(ReadResourceRequest(uri:))
}

pub fn read_resource_request_to_json(
  read_resource_request: ReadResourceRequest,
) -> Json {
  let ReadResourceRequest(uri:) = read_resource_request
  json.object([#("uri", json.string(uri))])
}

pub type ReadResourceResult {
  ReadResourceResult(meta: Option(Meta), contents: List(ResourceContents))
}

pub fn read_resource_result_decoder() -> Decoder(ReadResourceResult) {
  use meta <- omittable_field("_meta", meta_decoder())
  use contents <- decode.field(
    "contents",
    decode.list(resource_contents_decoder()),
  )
  decode.success(ReadResourceResult(meta:, contents:))
}

pub fn read_resource_result_to_json(
  read_resource_result: ReadResourceResult,
) -> Json {
  let ReadResourceResult(meta:, contents:) = read_resource_result
  [#("contents", json.array(contents, resource_contents_to_json))]
  |> omittable_to_json("_meta", meta, meta_to_json)
  |> json.object
}

// pub type Request {
//   Request(method: String, params: Option(RequestParams))
// }

// pub type RequestParams {
//   RequestParams(meta: Option(RequestParamsMeta))
// }

// pub type RequestParamsMeta {
//   RequestParamsMeta(progress_token: Option(ProgressToken))
// }

pub type Resource {
  Resource(
    annotations: Option(Annotations),
    description: Option(String),
    mime_type: Option(String),
    name: String,
    size: Option(Int),
    uri: String,
  )
}

pub fn resource_decoder() -> Decoder(Resource) {
  use annotations <- omittable_field("annotations", annotations_decoder())
  use description <- omittable_field("description", decode.string)
  use mime_type <- omittable_field("mimeType", decode.string)
  use name <- decode.field("name", decode.string)
  use size <- omittable_field("size", decode.int)
  use uri <- decode.field("uri", decode.string)
  decode.success(Resource(
    annotations:,
    description:,
    mime_type:,
    name:,
    size:,
    uri:,
  ))
}

pub fn resource_to_json(resource: Resource) -> Json {
  let Resource(annotations:, description:, mime_type:, name:, size:, uri:) =
    resource
  [#("name", json.string(name)), #("uri", json.string(uri))]
  |> omittable_to_json("annotations", annotations, annotations_to_json)
  |> omittable_to_json("description", description, json.string)
  |> omittable_to_json("mimeType", mime_type, json.string)
  |> omittable_to_json("size", size, json.int)
  |> json.object
}

// pub type ResourceContents {
//   ResourceContents(mime_type: Option(String), uri: String)
// }

// pub type ResourceListChangedNotification {
//   ResourceListChangedNotification(
//     method: String,
//     params: Option(ResourceListChangedNotificationParams),
//   )
// }

pub type ResourceListChangedNotification {
  ResourceListChangedNotification(meta: Option(Meta))
}

pub fn resource_list_changed_notification_decoder() -> Decoder(
  ResourceListChangedNotification,
) {
  use meta <- omittable_field("_meta", meta_decoder())
  decode.success(ResourceListChangedNotification(meta:))
}

pub fn resource_list_changed_notification_to_json(
  resource_list_changed_notification: ResourceListChangedNotification,
) -> Json {
  let ResourceListChangedNotification(meta:) =
    resource_list_changed_notification
  [] |> omittable_to_json("_meta", meta, meta_to_json) |> json.object
}

pub type ResourceReference {
  ResourceReference(type_: String, uri: String)
}

pub fn resource_reference_decoder() -> Decoder(ResourceReference) {
  use type_ <- decode.field("type", decode.string)
  use uri <- decode.field("uri", decode.string)
  decode.success(ResourceReference(type_:, uri:))
}

pub fn resource_reference_to_json(resource_reference: ResourceReference) -> Json {
  let ResourceReference(type_:, uri:) = resource_reference
  json.object([#("type", json.string(type_)), #("uri", json.string(uri))])
}

pub type ResourceTemplate {
  ResourceTemplate(
    annotations: Option(Annotations),
    description: Option(String),
    mime_type: Option(String),
    name: String,
    uri_template: String,
  )
}

pub fn resource_template_decoder() -> Decoder(ResourceTemplate) {
  use annotations <- omittable_field("annotations", annotations_decoder())
  use description <- omittable_field("description", decode.string)
  use mime_type <- omittable_field("mimeType", decode.string)
  use name <- decode.field("name", decode.string)
  use uri_template <- decode.field("uriTemplate", decode.string)
  decode.success(ResourceTemplate(
    annotations:,
    description:,
    mime_type:,
    name:,
    uri_template:,
  ))
}

pub fn resource_template_to_json(resource_template: ResourceTemplate) -> Json {
  let ResourceTemplate(
    annotations:,
    description:,
    mime_type:,
    name:,
    uri_template:,
  ) = resource_template
  [#("name", json.string(name)), #("uriTemplate", json.string(uri_template))]
  |> omittable_to_json("annotations", annotations, annotations_to_json)
  |> omittable_to_json("description", description, json.string)
  |> omittable_to_json("mimeType", mime_type, json.string)
  |> json.object
}

// pub type ResourceUpdatedNotification {
//   ResourceUpdatedNotification(
//     method: String,
//     params: ResourceUpdatedNotificationParams,
//   )
// }

pub type ResourceUpdatedNotification {
  ResourceUpdatedNotification(uri: String)
}

pub fn resource_updated_notification_decoder() -> Decoder(
  ResourceUpdatedNotification,
) {
  use uri <- decode.field("uri", decode.string)
  decode.success(ResourceUpdatedNotification(uri:))
}

pub fn resource_updated_notification_to_json(
  resource_updated_notification: ResourceUpdatedNotification,
) -> Json {
  let ResourceUpdatedNotification(uri:) = resource_updated_notification
  json.object([#("uri", json.string(uri))])
}

// pub type Result {
//   Result(meta: Option(Dict(String, Dynamic)))
// }

pub type Role {
  Assistant
  User
}

pub fn role_decoder() -> Decoder(Role) {
  use variant <- decode.then(decode.string)
  case variant {
    "user" -> decode.success(User)
    "assistant" -> decode.success(Assistant)
    _ -> decode.failure(User, "Role")
  }
}

pub fn role_to_json(role: Role) -> Json {
  case role {
    User -> json.string("user")
    Assistant -> json.string("assistant")
  }
}

pub type Root {
  Root(name: Option(String), uri: String)
}

pub fn root_decoder() -> Decoder(Root) {
  use name <- omittable_field("name", decode.string)
  use uri <- decode.field("uri", decode.string)
  decode.success(Root(name:, uri:))
}

pub fn root_to_json(root: Root) -> Json {
  let Root(name:, uri:) = root
  json.object(
    [#("uri", json.string(uri))]
    |> omittable_to_json("name", name, json.string),
  )
}

// pub type RootsListChangedNotification {
//   RootsListChangedNotification(
//     method: String,
//     params: Option(RootsListChangedNotificationParams),
//   )
// }

pub type RootsListChangedNotification {
  RootsListChangedNotification(meta: Option(Meta))
}

pub fn roots_list_changed_notification_decoder() -> Decoder(
  RootsListChangedNotification,
) {
  use meta <- omittable_field("_meta", meta_decoder())
  decode.success(RootsListChangedNotification(meta:))
}

pub fn roots_list_changed_notification_to_json(
  roots_list_changed_notification: RootsListChangedNotification,
) -> Json {
  let RootsListChangedNotification(meta:) = roots_list_changed_notification
  [] |> omittable_to_json("_meta", meta, meta_to_json) |> json.object
}

pub type SamplingMessage {
  SamplingMessage(content: MessageContent, role: Role)
}

pub fn sampling_message_decoder() -> Decoder(SamplingMessage) {
  use content <- decode.field("content", message_content_decoder())
  use role <- decode.field("role", role_decoder())
  decode.success(SamplingMessage(content:, role:))
}

pub fn sampling_message_to_json(sampling_message: SamplingMessage) -> Json {
  let SamplingMessage(content:, role:) = sampling_message
  json.object([
    #("content", message_content_to_json(content)),
    #("role", role_to_json(role)),
  ])
}

pub type ServerCapabilities {
  ServerCapabilities(
    completions: Option(ServerCapabilitiesCompletions),
    // experimental: Option(Dict(String, Dynamic)),
    logging: Option(ServerCapabilitiesLogging),
    prompts: Option(ServerCapabilitiesPrompts),
    resources: Option(ServerCapabilitiesResources),
    tools: Option(ServerCapabilitiesTools),
  )
}

fn server_capabilities_decoder() -> Decoder(ServerCapabilities) {
  use completions <- omittable_field(
    "completions",
    server_capabilities_completions_decoder(),
  )
  use logging <- omittable_field(
    "logging",
    server_capabilities_logging_decoder(),
  )
  use prompts <- omittable_field(
    "prompts",
    server_capabilities_prompts_decoder(),
  )
  use resources <- omittable_field(
    "resources",
    server_capabilities_resources_decoder(),
  )
  use tools <- omittable_field("tools", server_capabilities_tools_decoder())
  decode.success(ServerCapabilities(
    completions:,
    logging:,
    prompts:,
    resources:,
    tools:,
  ))
}

pub fn server_capabilities_to_json(capabilities: ServerCapabilities) -> Json {
  let ServerCapabilities(completions:, logging:, prompts:, resources:, tools:) =
    capabilities
  []
  |> omittable_to_json(
    "completions",
    completions,
    server_capabilities_completions_to_json,
  )
  |> omittable_to_json("logging", logging, server_capabilities_logging_to_json)
  |> omittable_to_json("prompts", prompts, server_capabilities_prompts_to_json)
  |> omittable_to_json(
    "resources",
    resources,
    server_capabilities_resources_to_json,
  )
  |> omittable_to_json("tools", tools, server_capabilities_tools_to_json)
  |> json.object
}

pub type ServerCapabilitiesCompletions {
  ServerCapabilitiesCompletions
}

pub fn server_capabilities_completions_decoder() -> Decoder(
  ServerCapabilitiesCompletions,
) {
  decode.success(ServerCapabilitiesCompletions)
}

pub fn server_capabilities_completions_to_json(
  _server_capabilities_completions: ServerCapabilitiesCompletions,
) -> Json {
  json.object([])
}

pub type ServerCapabilitiesLogging {
  ServerCapabilitiesLogging
}

pub fn server_capabilities_logging_decoder() -> Decoder(
  ServerCapabilitiesLogging,
) {
  decode.success(ServerCapabilitiesLogging)
}

pub fn server_capabilities_logging_to_json(
  _server_capabilities_logging: ServerCapabilitiesLogging,
) -> Json {
  json.object([])
}

pub type ServerCapabilitiesPrompts {
  ServerCapabilitiesPrompts(list_changed: Option(Bool))
}

pub fn server_capabilities_prompts_decoder() -> Decoder(
  ServerCapabilitiesPrompts,
) {
  use list_changed <- omittable_field("listChanged", decode.bool)
  decode.success(ServerCapabilitiesPrompts(list_changed:))
}

pub fn server_capabilities_prompts_to_json(
  server_capabilities_prompts: ServerCapabilitiesPrompts,
) -> Json {
  let ServerCapabilitiesPrompts(list_changed:) = server_capabilities_prompts
  [] |> omittable_to_json("listChanged", list_changed, json.bool) |> json.object
}

pub type ServerCapabilitiesResources {
  ServerCapabilitiesResources(
    list_changed: Option(Bool),
    subscribe: Option(Bool),
  )
}

pub fn server_capabilities_resources_decoder() -> Decoder(
  ServerCapabilitiesResources,
) {
  use list_changed <- omittable_field("listChanged", decode.bool)
  use subscribe <- omittable_field("subscribe", decode.bool)
  decode.success(ServerCapabilitiesResources(list_changed:, subscribe:))
}

pub fn server_capabilities_resources_to_json(
  server_capabilities_resources: ServerCapabilitiesResources,
) -> Json {
  let ServerCapabilitiesResources(list_changed:, subscribe:) =
    server_capabilities_resources
  []
  |> omittable_to_json("listChanged", list_changed, json.bool)
  |> omittable_to_json("subscribe", subscribe, json.bool)
  |> json.object
}

pub type ServerCapabilitiesTools {
  ServerCapabilitiesTools(list_changed: Option(Bool))
}

pub fn server_capabilities_tools_decoder() -> Decoder(ServerCapabilitiesTools) {
  use list_changed <- omittable_field("listChanged", decode.bool)
  decode.success(ServerCapabilitiesTools(list_changed:))
}

pub fn server_capabilities_tools_to_json(
  server_capabilities_tools: ServerCapabilitiesTools,
) -> Json {
  let ServerCapabilitiesTools(list_changed:) = server_capabilities_tools
  [] |> omittable_to_json("listChanged", list_changed, json.bool) |> json.object
}

// pub type SetLevelRequest {
//   SetLevelRequest(method: String, params: SetLevelRequestParams)
// }

pub type SetLevelRequest {
  SetLevelRequest(level: LoggingLevel)
}

pub fn set_level_request_decoder() -> Decoder(SetLevelRequest) {
  use level <- decode.field("level", logging_level_decoder())
  decode.success(SetLevelRequest(level:))
}

pub fn set_level_request_to_json(set_level_request: SetLevelRequest) -> Json {
  let SetLevelRequest(level:) = set_level_request
  json.object([#("level", logging_level_to_json(level))])
}

// pub type SubscribeRequest {
//   SubscribeRequest(method: String, params: SubscribeRequestParams)
// }

pub type SubscribeRequest {
  SubscribeRequest(uri: String)
}

pub fn subscribe_request_decoder() -> Decoder(SubscribeRequest) {
  use uri <- decode.field("uri", decode.string)
  decode.success(SubscribeRequest(uri:))
}

pub fn subscribe_request_to_json(subscribe_request: SubscribeRequest) -> Json {
  let SubscribeRequest(uri:) = subscribe_request
  json.object([#("uri", json.string(uri))])
}

pub type TextContent {
  TextContent(annotations: Option(Annotations), text: String, type_: String)
}

pub fn text_content_decoder() -> Decoder(TextContent) {
  use annotations <- omittable_field("annotations", annotations_decoder())
  use text <- decode.field("text", decode.string)
  use type_ <- decode.field("type", decode.string)
  decode.success(TextContent(annotations:, text:, type_:))
}

pub fn text_content_to_json(text_content: TextContent) -> Json {
  let TextContent(annotations:, text:, type_:) = text_content
  json.object(
    [#("text", json.string(text)), #("type", json.string(type_))]
    |> omittable_to_json("annotations", annotations, annotations_to_json),
  )
}

pub type TextResourceContents {
  TextResourceContents(mime_type: Option(String), text: String, uri: String)
}

pub fn text_resource_contents_decoder() -> Decoder(TextResourceContents) {
  use mime_type <- omittable_field("mimeType", decode.string)
  use text <- decode.field("text", decode.string)
  use uri <- decode.field("uri", decode.string)
  decode.success(TextResourceContents(mime_type:, text:, uri:))
}

pub fn text_resource_contents_to_json(
  text_resource_contents: TextResourceContents,
) -> Json {
  let TextResourceContents(mime_type:, text:, uri:) = text_resource_contents
  [#("text", json.string(text)), #("uri", json.string(uri))]
  |> omittable_to_json("mimeType", mime_type, json.string)
  |> json.object
}

pub type Tool {
  Tool(
    annotations: Option(ToolAnnotations),
    description: Option(String),
    input_schema: ToolInputSchema,
    name: String,
  )
}

pub fn tool_decoder() -> Decoder(Tool) {
  use annotations <- omittable_field("annotations", tool_annotations_decoder())
  use description <- omittable_field("description", decode.string)
  use input_schema <- decode.field("inputSchema", tool_input_schema_decoder())
  use name <- decode.field("name", decode.string)
  decode.success(Tool(annotations:, description:, input_schema:, name:))
}

pub fn tool_to_json(tool: Tool) -> Json {
  let Tool(annotations:, description:, input_schema:, name:) = tool
  [
    #("inputSchema", tool_input_schema_to_json(input_schema)),
    #("name", json.string(name)),
  ]
  |> omittable_to_json("annotations", annotations, tool_annotations_to_json)
  |> omittable_to_json("description", description, json.string)
  |> json.object
}

pub type ToolAnnotations {
  ToolAnnotations(
    destructive_hint: Option(Bool),
    idempotent_hint: Option(Bool),
    open_world_hint: Option(Bool),
    read_only_hint: Option(Bool),
    title: Option(String),
  )
}

pub fn tool_annotations_decoder() -> Decoder(ToolAnnotations) {
  use destructive_hint <- omittable_field("destructiveHint", decode.bool)
  use idempotent_hint <- omittable_field("idempotentHint", decode.bool)
  use open_world_hint <- omittable_field("openWorldHint", decode.bool)
  use read_only_hint <- omittable_field("readOnlyHint", decode.bool)
  use title <- omittable_field("title", decode.string)
  decode.success(ToolAnnotations(
    destructive_hint:,
    idempotent_hint:,
    open_world_hint:,
    read_only_hint:,
    title:,
  ))
}

pub fn tool_annotations_to_json(tool_annotations: ToolAnnotations) -> Json {
  let ToolAnnotations(
    destructive_hint:,
    idempotent_hint:,
    open_world_hint:,
    read_only_hint:,
    title:,
  ) = tool_annotations
  []
  |> omittable_to_json("destructiveHint", destructive_hint, json.bool)
  |> omittable_to_json("idempotentHint", idempotent_hint, json.bool)
  |> omittable_to_json("openWorldHint", open_world_hint, json.bool)
  |> omittable_to_json("readOnlyHint", read_only_hint, json.bool)
  |> omittable_to_json("title", title, json.string)
  |> json.object
}

pub opaque type ToolInputSchema {
  ToolInputSchema(json_schema.ObjectSchema)
}

pub fn tool_input_schema(
  json: String,
) -> Result(ToolInputSchema, json.DecodeError) {
  json.parse(json, tool_input_schema_decoder())
}

pub fn tool_input_schema_decoder() -> Decoder(ToolInputSchema) {
  let default =
    ToolInputSchema(
      json_schema.ObjectSchema(
        properties: [],
        required: [],
        additional_properties: option.None,
        pattern_properties: [],
      ),
    )
  decode.new_primitive_decoder("ToolInputSchema", fn(data) {
    case decode.run(data, decode.at(["type"], decode.string)) {
      Ok("object") ->
        case json_schema.decode_object_schema(data) {
          Ok(schema) -> Ok(ToolInputSchema(schema))
          gleam.Error(_) -> gleam.Error(default)
        }
      _ -> gleam.Error(default)
    }
  })
}

pub fn tool_input_schema_to_json(schema: ToolInputSchema) -> Json {
  let ToolInputSchema(schema) = schema

  [
    #("type", json.string("object")),
    ..json_schema.object_schema_to_json(schema)
  ]
  |> json.object
}

// pub type ToolInputSchema {
//   ToolInputSchema(
//     properties: Option(Dict(String, Dynamic)),
//     required: Option(List(String)),
//     type_: String,
//   )
// }

// pub type ToolListChangedNotification {
//   ToolListChangedNotification(
//     method: String,
//     params: Option(ToolListChangedNotificationParams),
//   )
// }

pub type ToolListChangedNotification {
  ToolListChangedNotification(meta: Option(Meta))
}

pub fn tool_list_changed_notification_decoder() -> Decoder(
  ToolListChangedNotification,
) {
  use meta <- omittable_field("_meta", meta_decoder())
  decode.success(ToolListChangedNotification(meta:))
}

pub fn tool_list_changed_notification_to_json(
  tool_list_changed_notification: ToolListChangedNotification,
) -> Json {
  let ToolListChangedNotification(meta:) = tool_list_changed_notification
  [] |> omittable_to_json("_meta", meta, meta_to_json) |> json.object
}

// pub type UnsubscribeRequest {
//   UnsubscribeRequest(method: String, params: UnsubscribeRequestParams)
// }

pub type UnsubscribeRequest {
  UnsubscribeRequest(uri: String)
}

pub fn unsubscribe_request_decoder() -> Decoder(UnsubscribeRequest) {
  use uri <- decode.field("uri", decode.string)
  decode.success(UnsubscribeRequest(uri:))
}

pub fn unsubscribe_request_to_json(
  unsubscribe_request: UnsubscribeRequest,
) -> Json {
  let UnsubscribeRequest(uri:) = unsubscribe_request
  json.object([#("uri", json.string(uri))])
}

pub fn omittable_field(
  name: name,
  decoder: Decoder(a),
  next: fn(Option(a)) -> Decoder(b),
) -> Decoder(b) {
  decode.optional_field(name, option.None, decode.optional(decoder), next)
}

pub fn omittable_to_json(
  object: List(#(String, json.Json)),
  key: String,
  value: option.Option(a),
  to_json: fn(a) -> json.Json,
) -> List(#(String, json.Json)) {
  case value {
    option.Some(value) -> [#(key, to_json(value)), ..object]
    option.None -> object
  }
}
