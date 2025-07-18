import gleam/bytes_tree.{type BytesTree}
import gleam/dict.{type Dict}
import gleam/dynamic/decode.{type Decoder, type Dynamic}
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string_tree.{type StringTree}
import mcp_gleam/get_prompt
import mcp_gleam/mcp.{type McpError}
import mcp_gleam/read_resource
import mcp_gleam/resource

pub type Body {
  Text(StringTree)
  Bytes(BytesTree)
  Empty
}

pub type Response {
  Response(result: Body)
  ErrorResponse(code: Int, message: String, data: Body)
}

pub type Builder {
  Builder(
    name: String,
    version: String,
    description: Option(String),
    instructions: Option(String),
    resources: Dict(String, ServerResource),
    resource_templates: Dict(String, ServerResourceTemplate),
    tools: Dict(String, ServerTool),
    // prompts: Dict(String, ServerPrompt),
    capabilities: mcp.ServerCapabilities,
    page_limit: Option(Int),
  )
}

pub fn new(name name: String, version version: String) -> Builder {
  Builder(
    name:,
    version:,
    description: None,
    instructions: None,
    resources: dict.new(),
    resource_templates: dict.new(),
    tools: dict.new(),
    // prompts: dict.new(),
    capabilities: mcp.ServerCapabilities(None, None, None, None, None),
    page_limit: None,
  )
}

pub fn description(builder: Builder, description: String) -> Builder {
  Builder(..builder, description: Some(description))
}

pub fn instructions(builder: Builder, instructions: String) -> Builder {
  Builder(..builder, instructions: Some(instructions))
}

pub fn add_resource(
  builder: Builder,
  resource: resource.Resource,
  handler: fn(read_resource.Request) -> Result(read_resource.Response, McpError),
) -> Builder {
  let capabilities = case builder.capabilities.resources {
    None ->
      mcp.ServerCapabilities(
        ..builder.capabilities,
        resources: Some(mcp.ServerCapabilitiesResources(
          Some(False),
          Some(False),
        )),
      )
    Some(_) -> builder.capabilities
  }

  Builder(
    ..builder,
    resources: dict.insert(
      builder.resources,
      // resource.uri,
      todo,
      ServerResource(resource, handler),
    ),
    capabilities:,
  )
}

pub fn add_resource_template(
  builder: Builder,
  template: mcp.ResourceTemplate,
  handler: fn(read_resource.Request) -> Result(read_resource.Response, McpError),
) -> Builder {
  let capabilities = case builder.capabilities.resources {
    None ->
      mcp.ServerCapabilities(
        ..builder.capabilities,
        resources: Some(mcp.ServerCapabilitiesResources(
          Some(False),
          Some(False),
        )),
      )
    Some(_) -> builder.capabilities
  }

  Builder(
    ..builder,
    resource_templates: dict.insert(
      builder.resource_templates,
      template.name,
      ServerResourceTemplate(template, todo),
    ),
    capabilities:,
  )
}

pub fn add_tool(
  builder: Builder,
  tool: mcp.Tool,
  arguments_decoder: Decoder(arguments),
  handler: fn(mcp.CallToolRequest(arguments)) ->
    Result(mcp.CallToolResult, String),
) -> Builder {
  let capabilities = case builder.capabilities.tools {
    None ->
      mcp.ServerCapabilities(
        ..builder.capabilities,
        tools: Some(mcp.ServerCapabilitiesTools(None)),
      )
    Some(_) -> builder.capabilities
  }
  Builder(
    ..builder,
    tools: dict.insert(
      builder.tools,
      tool.name,
      ServerTool(tool, prompt_handler(arguments_decoder, handler)),
    ),
    capabilities:,
  )
}

fn prompt_handler(
  arguments_decoder: Decoder(arguments),
  handler: fn(mcp.CallToolRequest(arguments)) ->
    Result(mcp.CallToolResult, String),
) -> fn(mcp.CallToolRequest(Dynamic)) ->
  Result(mcp.CallToolResult, mcp.McpError) {
  fn(request: mcp.CallToolRequest(Dynamic)) {
    case request.arguments {
      None ->
        mcp.CallToolRequest(..request, arguments: None)
        |> handler
        |> result.map_error(mcp.ApplicationError)

      Some(dyn) ->
        case decode.run(dyn, arguments_decoder) {
          Ok(args) ->
            mcp.CallToolRequest(..request, arguments: Some(args))
            |> handler
            |> result.map_error(mcp.ApplicationError)

          Error(_) -> Error(mcp.InvalidParams)
        }
    }
  }
}

// pub fn add_prompt(
//   builder: Builder,
//   prompt: mcp.Prompt,
//   handler: fn(get_prompt.Request(a)) -> Result(get_prompt.Response, McpError),
// ) -> Builder {
//   let capabilities = case builder.capabilities.prompts {
//     None ->
//       mcp.ServerCapabilities(
//         ..builder.capabilities,
//         prompts: Some(mcp.ServerCapabilitiesPrompts(None)),
//       )
//     Some(_) -> builder.capabilities
//   }
//   Builder(
//     ..builder,
//     prompts: dict.insert(
//       builder.prompts,
//       prompt.name,
//       ServerPrompt(prompt, handler),
//     ),
//     capabilities:,
//   )
// }

pub fn resource_capabilities(
  builder: Builder,
  subscribe: Bool,
  list_changed: Bool,
) {
  let capabilities =
    mcp.ServerCapabilities(
      ..builder.capabilities,
      resources: Some(mcp.ServerCapabilitiesResources(
        Some(subscribe),
        Some(list_changed),
      )),
    )
  Builder(..builder, capabilities: capabilities)
}

pub fn prompt_capabilities(builder: Builder, list_changed: Bool) {
  let capabilities =
    mcp.ServerCapabilities(
      ..builder.capabilities,
      prompts: Some(mcp.ServerCapabilitiesPrompts(Some(list_changed))),
    )
  Builder(..builder, capabilities: capabilities)
}

pub fn tool_capabilities(builder: Builder, list_changed: Bool) {
  let capabilities =
    mcp.ServerCapabilities(
      ..builder.capabilities,
      tools: Some(mcp.ServerCapabilitiesTools(Some(list_changed))),
    )
  Builder(..builder, capabilities: capabilities)
}

pub fn enable_logging(builder: Builder) {
  let capabilities =
    mcp.ServerCapabilities(
      ..builder.capabilities,
      logging: Some(mcp.ServerCapabilitiesLogging),
    )
  Builder(..builder, capabilities: capabilities)
}

pub fn page_limit(builder: Builder, page_limit: Int) -> Builder {
  Builder(..builder, page_limit: Some(page_limit))
}

pub opaque type Server {
  Server(
    name: String,
    version: String,
    description: Option(String),
    instructions: Option(String),
    resources: Dict(String, ServerResource),
    resource_templates: Dict(String, ServerResourceTemplate),
    tools: Dict(String, ServerTool),
    // prompts: Dict(String, ServerPrompt),
    capabilities: mcp.ServerCapabilities,
    page_limit: Option(Int),
  )
}

pub fn build(builder: Builder) -> Server {
  Server(
    name: builder.name,
    version: builder.version,
    description: builder.description,
    instructions: builder.instructions,
    resources: builder.resources,
    resource_templates: builder.resource_templates,
    tools: builder.tools,
    // prompts: builder.prompts,
    capabilities: builder.capabilities,
    page_limit: builder.page_limit,
  )
}

// pub opaque type ServerPrompt {
//   ServerPrompt(
//     prompt: mcp.Prompt,
//     handler: fn(get_prompt.Request) -> Result(get_prompt.Response, McpError),
//   )
// }

pub opaque type ServerResource {
  ServerResource(
    resource: resource.Resource,
    handler: fn(read_resource.Request) ->
      Result(read_resource.Response, McpError),
  )
}

// TODO
pub opaque type ServerResourceTemplate {
  ServerResourceTemplate(
    template: mcp.ResourceTemplate,
    handler: fn(mcp.ReadResourceRequest) ->
      Result(mcp.ReadResourceResult, McpError),
  )
}

pub opaque type ServerTool {
  ServerTool(
    tool: mcp.Tool,
    handler: fn(mcp.CallToolRequest(Dynamic)) ->
      Result(mcp.CallToolResult, mcp.McpError),
  )
}
// pub fn handle_request(server: Server, request) -> Response {
//   todo
// }

// pub fn handle_notification(server: Server, notification) -> Nil {
//   todo
// }

// pub fn handle_response(server: Server, response) -> Nil {
//   todo
// }

// pub fn send_request(server: Server, request) -> Nil {
//   todo
// }

// pub fn send_notification(server: Server, notification) -> Nil {
//   todo
// }
