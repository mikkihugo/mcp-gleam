import gleam/dict.{type Dict}
import gleam/dynamic/decode.{type Decoder, type Dynamic}
import gleam/json
import gleam/list
import gleam/result
import mcp_toolkit_gleam/core/method
import jsonrpc

import gleam/option.{type Option, None, Some}

import mcp_toolkit_gleam/core/protocol as mcp

pub type Builder {
  Builder(
    name: String,
    version: String,
    description: Option(String),
    instructions: Option(String),
    resources: Dict(String, ServerResource),
    resource_templates: Dict(String, ServerResourceTemplate),
    tools: Dict(String, ServerTool),
    prompts: Dict(String, ServerPrompt),
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
    prompts: dict.new(),
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
  resource: mcp.Resource,
  handler: fn(mcp.ReadResourceRequest) -> Result(mcp.ReadResourceResult, String),
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
      resource.uri,
      ServerResource(resource, handler),
    ),
    capabilities:,
  )
}

pub fn add_resource_template(
  builder: Builder,
  template: mcp.ResourceTemplate,
  handler: fn(mcp.ReadResourceRequest) -> Result(mcp.ReadResourceResult, String),
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
      ServerResourceTemplate(template, handler),
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

pub fn add_prompt(
  builder: Builder,
  prompt: mcp.Prompt,
  handler: fn(mcp.GetPromptRequest) -> Result(mcp.GetPromptResult, String),
) -> Builder {
  let capabilities = case builder.capabilities.prompts {
    None ->
      mcp.ServerCapabilities(
        ..builder.capabilities,
        prompts: Some(mcp.ServerCapabilitiesPrompts(None)),
      )
    Some(_) -> builder.capabilities
  }
  Builder(
    ..builder,
    prompts: dict.insert(
      builder.prompts,
      prompt.name,
      ServerPrompt(prompt, handler),
    ),
    capabilities:,
  )
}

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
    prompts: Dict(String, ServerPrompt),
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
    prompts: builder.prompts,
    capabilities: builder.capabilities,
    page_limit: builder.page_limit,
  )
}

pub opaque type ServerPrompt {
  ServerPrompt(
    prompt: mcp.Prompt,
    handler: fn(mcp.GetPromptRequest) -> Result(mcp.GetPromptResult, String),
  )
}

pub opaque type ServerResource {
  ServerResource(
    resource: mcp.Resource,
    handler: fn(mcp.ReadResourceRequest) ->
      Result(mcp.ReadResourceResult, String),
  )
}

pub opaque type ServerResourceTemplate {
  ServerResourceTemplate(
    template: mcp.ResourceTemplate,
    handler: fn(mcp.ReadResourceRequest) ->
      Result(mcp.ReadResourceResult, String),
  )
}

pub opaque type ServerTool {
  ServerTool(
    tool: mcp.Tool,
    handler: fn(mcp.CallToolRequest(Dynamic)) ->
      Result(mcp.CallToolResult, mcp.McpError),
  )
}

pub fn handle_message(
  server: Server,
  message: String,
) -> Result(Option(json.Json), json.Json) {
  let result =
    json.parse(message, jsonrpc.message_decoder())
    |> result.map_error(jsonrpc.json_error)
    |> result.map_error(jsonrpc.error_response(_, jsonrpc.NullId))
    |> result.map_error(jsonrpc.error_response_to_json(
      _,
      jsonrpc.nothing_to_json,
    ))

  use msg <- result.try(result)
  case msg {
    jsonrpc.RequestMessage(request) ->
      handle_request(server, request) |> result.map(Some)

    jsonrpc.NotificationMessage(notification) -> {
      let _ = handle_notification(server, notification)
      Ok(None)
    }

    _ -> Ok(None)
  }
}

fn handle_request(
  server: Server,
  request: jsonrpc.Request(Dynamic),
) -> Result(json.Json, json.Json) {
  case request.method {
    m if m == method.initialize -> {
      require_params(
        server,
        request,
        initialize,
        mcp.initialize_request_decoder(),
        mcp.initialize_result_to_json,
      )
    }

    m if m == method.ping -> {
      case request.params {
        None ->
          ping(server, mcp.PingRequest(None))
          |> result.map(mcp.ping_result_to_json)
        Some(params) ->
          decode.run(params, mcp.ping_request_decoder())
          |> decode_errors_json(request.id)
          |> result.try(ping(server, _))
          |> result.map(jsonrpc.response(_, request.id))
          |> result.map(jsonrpc.response_to_json(_, mcp.ping_result_to_json))
      }
    }

    m if m == method.resources_list -> {
      paginated_params(
        server,
        request,
        list_resources,
        mcp.list_resources_result_to_json,
      )
    }

    m if m == method.resources_read -> {
      require_params(
        server,
        request,
        read_resource,
        mcp.read_resource_request_decoder(),
        mcp.read_resource_result_to_json,
      )
    }

    m if m == method.resources_templates_list -> {
      paginated_params(
        server,
        request,
        list_resource_templates,
        mcp.list_resource_templates_result_to_json,
      )
    }

    m if m == method.prompts_list -> {
      paginated_params(
        server,
        request,
        list_prompts,
        mcp.list_prompts_result_to_json,
      )
    }

    m if m == method.prompts_get -> {
      require_params(
        server,
        request,
        get_prompt,
        mcp.get_prompt_request_decoder(),
        mcp.get_prompt_result_to_json,
      )
    }

    m if m == method.tools_list -> {
      paginated_params(
        server,
        request,
        list_tools,
        mcp.list_tools_result_to_json,
      )
    }

    m if m == method.tools_call -> {
      require_params(
        server,
        request,
        call_tool,
        mcp.call_tool_request_decoder(decode.dynamic),
        mcp.call_tool_result_to_json,
      )
    }
    _ ->
      jsonrpc.method_not_found
      |> jsonrpc.error_response(request.id)
      |> jsonrpc.error_response_to_json(jsonrpc.nothing_to_json)
      |> Ok
  }
}

fn require_params(
  server: Server,
  request: jsonrpc.Request(Dynamic),
  handler: fn(Server, a) -> Result(b, json.Json),
  params_decoder: decode.Decoder(a),
  result_encoder: fn(b) -> json.Json,
) -> Result(json.Json, json.Json) {
  case request.params {
    None ->
      jsonrpc.invalid_params
      |> jsonrpc.error_response(request.id)
      |> jsonrpc.error_response_to_json(jsonrpc.nothing_to_json)
      |> Error
    Some(params) ->
      decode.run(params, params_decoder)
      |> decode_errors_json(request.id)
      |> result.try(handler(server, _))
      |> result.map(jsonrpc.response(_, request.id))
      |> result.map(jsonrpc.response_to_json(_, result_encoder))
  }
}

fn paginated_params(
  server: Server,
  request: jsonrpc.Request(Dynamic),
  handler: fn(Server, mcp.ListRequest) -> Result(a, json.Json),
  encoder: fn(a) -> json.Json,
) -> Result(json.Json, json.Json) {
  case request.params {
    None ->
      handler(server, mcp.ListRequest(None))
      |> result.map(jsonrpc.response(_, request.id))
      |> result.map(jsonrpc.response_to_json(_, encoder))

    Some(params) ->
      decode.run(params, mcp.list_request_decoder())
      |> decode_errors_json(request.id)
      |> result.try(handler(server, _))
      |> result.map(jsonrpc.response(_, request.id))
      |> result.map(jsonrpc.response_to_json(_, encoder))
  }
}

fn handle_notification(
  _server: Server,
  notification: jsonrpc.Notification(Dynamic),
) -> Nil {
  case notification.method {
    // m if m == method.notification_resources_list_changed -> todo
    // m if m == method.notification_resource_updated -> todo
    // m if m == method.notification_prompts_list_changed -> todo
    // m if m == method.notification_tools_list_changed -> todo
    _ -> Nil
  }
}

pub fn initialize(
  server: Server,
  _request: mcp.InitializeRequest,
) -> Result(mcp.InitializeResult, json.Json) {
  Ok(mcp.InitializeResult(
    capabilities: server.capabilities,
    protocol_version: mcp.protocol_version,
    server_info: mcp.Implementation(server.name, server.version),
    instructions: server.instructions,
    meta: None,
  ))
}

pub fn ping(
  _server: Server,
  _request: mcp.PingRequest,
) -> Result(mcp.PingResult, json.Json) {
  Ok(mcp.PingResult)
}

pub fn list_resources(
  server: Server,
  _request: mcp.ListResourcesRequest,
) -> Result(mcp.ListResourcesResult, json.Json) {
  let resources =
    dict.values(server.resources)
    |> list.map(fn(r) { r.resource })
  Ok(mcp.ListResourcesResult(resources:, next_cursor: None, meta: None))
}

pub fn list_resource_templates(
  server: Server,
  _request: mcp.ListResourceTemplatesRequest,
) -> Result(mcp.ListResourceTemplatesResult, json.Json) {
  let resource_templates =
    dict.values(server.resource_templates)
    |> list.map(fn(r) { r.template })
  Ok(mcp.ListResourceTemplatesResult(
    resource_templates:,
    next_cursor: None,
    meta: None,
  ))
}

pub fn read_resource(
  server: Server,
  request: mcp.ReadResourceRequest,
) -> Result(mcp.ReadResourceResult, json.Json) {
  case dict.get(server.resources, request.uri) {
    Ok(resource) -> {
      // TODO
      let assert Ok(res) = resource.handler(request)
      Ok(res)
    }
    Error(_) -> {
      jsonrpc.invalid_params
      // TODO
      |> jsonrpc.error_response(jsonrpc.NullId)
      |> jsonrpc.error_response_to_json(jsonrpc.nothing_to_json)
      |> Error
    }
  }
}

pub fn list_prompts(
  server: Server,
  _request: mcp.ListPromptsRequest,
) -> Result(mcp.ListPromptsResult, json.Json) {
  let prompts =
    dict.values(server.prompts)
    |> list.map(fn(p) { p.prompt })
  Ok(mcp.ListPromptsResult(prompts:, next_cursor: None, meta: None))
}

pub fn get_prompt(
  server: Server,
  request: mcp.GetPromptRequest,
) -> Result(mcp.GetPromptResult, json.Json) {
  case dict.get(server.prompts, request.name) {
    Ok(prompt) -> {
      // TODO
      let assert Ok(res) = prompt.handler(request)
      Ok(res)
    }
    Error(_) -> {
      jsonrpc.invalid_params
      // TODO
      |> jsonrpc.error_response(jsonrpc.NullId)
      |> jsonrpc.error_response_to_json(jsonrpc.nothing_to_json)
      |> Error
    }
  }
}

pub fn list_tools(
  server: Server,
  _request: mcp.ListToolsRequest,
) -> Result(mcp.ListToolsResult, json.Json) {
  let tools =
    dict.values(server.tools)
    |> list.map(fn(t) { t.tool })
  Ok(mcp.ListToolsResult(tools:, next_cursor: None, meta: None))
}

pub fn call_tool(
  server: Server,
  request: mcp.CallToolRequest(Dynamic),
) -> Result(mcp.CallToolResult, json.Json) {
  case dict.get(server.tools, request.name) {
    Ok(tool) -> {
      // TODO
      let assert Ok(res) = tool.handler(request)
      Ok(res)
    }
    Error(_) -> {
      jsonrpc.invalid_params
      // TODO
      |> jsonrpc.error_response(jsonrpc.NullId)
      |> jsonrpc.error_response_to_json(jsonrpc.nothing_to_json)
      |> Error
    }
  }
}

// pub fn notification_resources_list_changed(
//   server: Server,
//   request: request,
// ) -> Result(result, mcp.McpError) {
//   todo
// }

// pub fn notification_resource_updated(
//   server: Server,
//   request: request,
// ) -> Result(result, mcp.McpError) {
//   todo
// }

// pub fn notification_prompts_list_changed(
//   server: Server,
//   request: request,
// ) -> Result(result, mcp.McpError) {
//   todo
// }

// pub fn notification_tools_list_changed(
//   server: Server,
//   request: request,
// ) -> Result(result, mcp.McpError) {
//   todo
// }

fn decode_errors_json(
  result: Result(a, List(decode.DecodeError)),
  id: jsonrpc.Id,
) -> Result(a, json.Json) {
  result
  |> result.map_error(jsonrpc.decode_errors)
  |> result.map_error(jsonrpc.error_response(_, id))
  |> result.map_error(jsonrpc.error_response_to_json(_, jsonrpc.nothing_to_json))
}
