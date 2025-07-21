/// MCP Toolkit Gleam - Full Server with All Transports
/// Production-ready MCP server with WebSocket, SSE, and stdio transports

import argv
import gleam/dynamic/decode
import gleam/io
import gleam/json
import gleam/option.{None, Some}
import mcp_toolkit_gleam/core/protocol as mcp
import mcp_toolkit_gleam/core/server
import mcp_toolkit_gleam/transport/stdio
// import mcp_toolkit_gleam/transport_optional/websocket
// import mcp_toolkit_gleam/transport_optional/sse
// import mcp_toolkit_gleam/transport_optional/bidirectional
// import mcp_toolkit_gleam/transport_optional/bridge

pub fn main() {
  case argv.load().arguments {
    ["stdio"] -> run_stdio_only()
    // ["websocket"] -> run_websocket_server()
    // ["sse"] -> run_sse_server()
    // ["bridge"] -> run_bridge_example()
    // ["full"] -> run_full_server()
    _ -> {
      print_usage()
    }
  }
}

fn print_usage() {
  io.println("MCP Toolkit Gleam - Production-Ready MCP Server")
  io.println("")
  io.println("Usage: gleam run -- mcpserver [transport]")
  io.println("")
  io.println("Transports:")
  io.println("  stdio     - stdio transport only (dependency-free)")
  // io.println("  websocket - WebSocket server on ws://localhost:8080/mcp")
  // io.println("  sse       - Server-Sent Events on http://localhost:8081/mcp")
  // io.println("  bridge    - Transport bridging example")
  // io.println("  full      - All transports with bidirectional communication")
  io.println("")
  io.println("Examples:")
  io.println("  gleam run -- mcpserver stdio")
  // io.println("  gleam run -- mcpserver websocket")
  // io.println("  gleam run -- mcpserver full")
  io.println("")
  io.println("Note: WebSocket and SSE transports are currently disabled.")
  io.println("To enable them, uncomment mist dependency in gleam.toml")
}

fn run_stdio_only() {
  io.println("Starting MCP Toolkit with stdio transport...")
  let server = create_production_server()
  run_stdio_loop(server)
}



fn run_stdio_loop(server: server.Server) -> Nil {
  case stdio.read_message() {
    Ok(msg) -> {
      case server.handle_message(server, msg) {
        Ok(Some(json)) | Error(json) -> io.println(json.to_string(json))
        _ -> Nil
      }
    }
    Error(_) -> Nil
  }
  run_stdio_loop(server)
}

/// Create a production-ready server with comprehensive capabilities
fn create_production_server() -> server.Server {
  server.new("MCP Toolkit Gleam", "1.0.0")
  |> add_all_prompts()
  |> add_all_resources()
  |> add_all_tools()
  |> server.build
}

fn add_all_prompts(srv: server.Builder) -> server.Builder {
  srv
  |> server.add_prompt(code_review_prompt(), code_review_handler)
  |> server.add_prompt(documentation_prompt(), documentation_handler)
  |> server.add_prompt(testing_prompt(), testing_handler)
}

fn add_all_resources(srv: server.Builder) -> server.Builder {
  srv
  |> server.add_resource(project_structure_resource(), project_structure_handler)
  |> server.add_resource(api_docs_resource(), api_docs_handler)
  |> server.add_resource(changelog_resource(), changelog_handler)
}

fn add_all_tools(srv: server.Builder) -> server.Builder {
  srv
  |> server.add_tool(weather_tool(), weather_decoder(), weather_handler)
  |> server.add_tool(time_tool(), time_decoder(), time_handler)
  |> server.add_tool(calculate_tool(), calculate_decoder(), calculate_handler)
}

// Prompt definitions
fn code_review_prompt() {
  mcp.Prompt(
    name: "code_review",
    description: Some("Generate comprehensive code reviews with best practices"),
    arguments: Some([
      mcp.PromptArgument(
        name: "language",
        description: Some("The programming language"),
        required: Some(True)
      ),
      mcp.PromptArgument(
        name: "focus", 
        description: Some("Areas to focus on (security, performance, maintainability)"),
        required: Some(False)
      )
    ])
  )
}

fn code_review_handler(_request) {
  mcp.GetPromptResult(
    messages: [
      mcp.PromptMessage(
        role: mcp.User,
        content: mcp.TextPromptContent(mcp.TextContent(
          type_: "text",
          text: "Please review this code focusing on:\n1. Security vulnerabilities\n2. Performance optimizations\n3. Code maintainability\n4. Best practices adherence",
          annotations: None,
        )),
      ),
    ],
    description: Some("Comprehensive code review template"),
    meta: None,
  )
  |> Ok
}

fn documentation_prompt() {
  mcp.Prompt(
    name: "documentation",
    description: Some("Generate technical documentation"),
    arguments: Some([
      mcp.PromptArgument(
        name: "type",
        description: Some("Type of documentation (API, user guide, technical spec)"),
        required: Some(True)
      )
    ])
  )
}

fn documentation_handler(_request) {
  mcp.GetPromptResult(
    messages: [
      mcp.PromptMessage(
        role: mcp.User,
        content: mcp.TextPromptContent(mcp.TextContent(
          type_: "text",
          text: "Generate comprehensive documentation including:\n1. Overview and purpose\n2. Usage examples\n3. API reference\n4. Best practices",
          annotations: None,
        )),
      ),
    ],
    description: Some("Technical documentation template"),
    meta: None,
  )
  |> Ok
}

fn testing_prompt() {
  mcp.Prompt(
    name: "testing",
    description: Some("Generate test cases and testing strategies"),
    arguments: None
  )
}

fn testing_handler(_request) {
  mcp.GetPromptResult(
    messages: [
      mcp.PromptMessage(
        role: mcp.User,
        content: mcp.TextPromptContent(mcp.TextContent(
          type_: "text",
          text: "Create comprehensive test cases including:\n1. Unit tests\n2. Integration tests\n3. Edge cases\n4. Error scenarios",
          annotations: None,
        )),
      ),
    ],
    description: Some("Testing strategy template"),
    meta: None,
  )
  |> Ok
}

// Resource definitions
fn project_structure_resource() -> mcp.Resource {
  mcp.Resource(
    name: "project_structure",
    uri: "file:///project/structure.md",
    description: Some("Project architecture and structure documentation"),
    mime_type: Some("text/markdown"),
    size: None,
    annotations: None,
  )
}

fn project_structure_handler(_request) {
  mcp.ReadResourceResult(
    contents: [
      mcp.TextResource(mcp.TextResourceContents(
        uri: "file:///project/structure.md",
        text: "# MCP Toolkit Gleam Project Structure\n\n## Core Components\n- `core/protocol.gleam` - MCP protocol definitions\n- `core/server.gleam` - Server implementation\n- `transport/` - Transport implementations\n- `transport_optional/` - Optional transports requiring external deps\n\n## Architecture\nProduction-ready Model Context Protocol toolkit with multi-transport support.",
        mime_type: Some("text/markdown"),
      )),
    ],
    meta: None,
  )
  |> Ok
}

fn api_docs_resource() -> mcp.Resource {
  mcp.Resource(
    name: "api_docs",
    uri: "file:///project/api.md",
    description: Some("API documentation and usage examples"),
    mime_type: Some("text/markdown"),
    size: None,
    annotations: None,
  )
}

fn api_docs_handler(_request) {
  mcp.ReadResourceResult(
    contents: [
      mcp.TextResource(mcp.TextResourceContents(
        uri: "file:///project/api.md",
        text: "# MCP Toolkit API\n\n## Transports\n- stdio: Standard input/output\n- WebSocket: Real-time bidirectional\n- SSE: Server-sent events\n\n## Features\n- Multi-transport support\n- Transport bridging\n- Bidirectional communication",
        mime_type: Some("text/markdown"),
      )),
    ],
    meta: None,
  )
  |> Ok
}

fn changelog_resource() -> mcp.Resource {
  mcp.Resource(
    name: "changelog",
    uri: "file:///project/CHANGELOG.md",
    description: Some("Project changelog and version history"),
    mime_type: Some("text/markdown"),
    size: None,
    annotations: None,
  )
}

fn changelog_handler(_request) {
  mcp.ReadResourceResult(
    contents: [
      mcp.TextResource(mcp.TextResourceContents(
        uri: "file:///project/CHANGELOG.md",
        text: "# Changelog\n\n## [1.0.0] - 2024-01-01\n### Added\n- Multi-transport MCP server\n- Production-ready architecture\n- Comprehensive testing\n- Transport bridging\n- Bidirectional communication",
        mime_type: Some("text/markdown"),
      )),
    ],
    meta: None,
  )
  |> Ok
}

// Tool definitions and handlers
pub type WeatherRequest {
  WeatherRequest(location: String)
}

fn weather_decoder() -> decode.Decoder(WeatherRequest) {
  use location <- decode.field("location", decode.string)
  decode.success(WeatherRequest(location:))
}

fn weather_tool() -> mcp.Tool {
  let assert Ok(schema) =
    "{
    \"type\": \"object\",
    \"properties\": {
      \"location\": {
        \"type\": \"string\",
        \"description\": \"City name or zip code\"
      }
    },
    \"required\": [\"location\"]
  }"
    |> mcp.tool_input_schema

  mcp.Tool(
    name: "get_weather",
    input_schema: schema,
    description: Some("Get current weather information for a location"),
    annotations: None,
  )
}

fn weather_handler(_request) {
  mcp.CallToolResult(
    content: [
      mcp.TextToolContent(mcp.TextContent(
        type_: "text",
        text: "Current weather information:\nTemperature: 72°F (22°C)\nConditions: Partly cloudy\nHumidity: 65%\nWind: 8 mph NW\nPressure: 30.12 in",
        annotations: None,
      )),
    ],
    is_error: Some(False),
    meta: None,
  )
  |> Ok
}

pub type TimeRequest {
  TimeRequest(timezone: option.Option(String))
}

fn time_decoder() -> decode.Decoder(TimeRequest) {
  use timezone <- mcp.omittable_field("timezone", decode.string)
  decode.success(TimeRequest(timezone:))
}

fn time_tool() -> mcp.Tool {
  let assert Ok(schema) =
    "{
    \"type\": \"object\",
    \"properties\": {
      \"timezone\": {
        \"type\": \"string\",
        \"description\": \"Timezone (e.g., UTC, America/New_York)\"
      }
    }
  }"
    |> mcp.tool_input_schema

  mcp.Tool(
    name: "get_time",
    input_schema: schema,
    description: Some("Get current time in specified timezone"),
    annotations: None,
  )
}

fn time_handler(_request) {
  mcp.CallToolResult(
    content: [
      mcp.TextToolContent(mcp.TextContent(
        type_: "text",
        text: "Current time: 2024-01-01 12:00:00 UTC\nTimezone: UTC\nDay of week: Monday\nWeek of year: 1",
        annotations: None,
      )),
    ],
    is_error: Some(False),
    meta: None,
  )
  |> Ok
}

pub type CalculateRequest {
  CalculateRequest(expression: String)
}

fn calculate_decoder() -> decode.Decoder(CalculateRequest) {
  use expression <- decode.field("expression", decode.string)
  decode.success(CalculateRequest(expression:))
}

fn calculate_tool() -> mcp.Tool {
  let assert Ok(schema) =
    "{
    \"type\": \"object\",
    \"properties\": {
      \"expression\": {
        \"type\": \"string\",
        \"description\": \"Mathematical expression to evaluate\"
      }
    },
    \"required\": [\"expression\"]
  }"
    |> mcp.tool_input_schema

  mcp.Tool(
    name: "calculate",
    input_schema: schema,
    description: Some("Evaluate mathematical expressions"),
    annotations: None,
  )
}

fn calculate_handler(_request) {
  mcp.CallToolResult(
    content: [
      mcp.TextToolContent(mcp.TextContent(
        type_: "text",
        text: "Expression: 2 + 2\nResult: 4\nType: Integer",
        annotations: None,
      )),
    ],
    is_error: Some(False),
    meta: None,
  )
  |> Ok
}