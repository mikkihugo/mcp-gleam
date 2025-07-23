/// MCP Toolkit Gleam - Stdio Transport Only
/// Production-ready MCP server with stdio transport (dependency-free)
import gleam/dynamic/decode
import gleam/io
import gleam/json
import gleam/option.{None, Some}
import mcp_toolkit_gleam/core/protocol as mcp
import mcp_toolkit_gleam/core/server
import mcp_toolkit_gleam/transport/stdio

pub fn main() {
  io.println("MCP Toolkit Gleam - Stdio Transport")
  io.println("Production-ready MCP server with stdio transport")
  io.println("Listening for JSON-RPC messages on stdin...")

  let server = create_production_stdio_server()
  execute_stdio_message_loop(server)
}

fn execute_stdio_message_loop(server: server.Server) -> Nil {
  case stdio.read_message() {
    Ok(msg) -> {
      case server.handle_message(server, msg) {
        Ok(Some(json)) | Error(json) -> io.println(json.to_string(json))
        _ -> Nil
      }
    }
    Error(_) -> Nil
  }
  execute_stdio_message_loop(server)
}

/// Create a production-ready server with comprehensive sample capabilities
fn create_production_stdio_server() -> server.Server {
  server.new("MCP Toolkit Gleam", "1.0.0")
  |> server.add_prompt(create_code_review_prompt(), handle_code_review_prompt)
  |> server.add_resource(
    create_project_structure_resource(),
    handle_project_structure_resource,
  )
  |> server.add_tool(
    create_weather_tool(),
    decode_weather_request(),
    handle_weather_tool_request,
  )
  |> server.build
}

fn create_code_review_prompt() {
  mcp.Prompt(
    name: "code_review",
    description: Some("Generate a comprehensive code review"),
    arguments: None,
  )
}

fn handle_code_review_prompt(_request) {
  mcp.GetPromptResult(
    messages: [
      mcp.PromptMessage(
        role: mcp.User,
        content: mcp.TextPromptContent(mcp.TextContent(
          type_: "text",
          text: "Please review this code for best practices, potential bugs, and improvements.",
          annotations: None,
        )),
      ),
    ],
    description: Some("Code review prompt template"),
    meta: None,
  )
  |> Ok
}

fn create_project_structure_resource() -> mcp.Resource {
  mcp.Resource(
    name: "project_structure",
    uri: "file:///project/structure.md",
    description: Some("Project structure and architecture documentation"),
    mime_type: Some("text/markdown"),
    size: None,
    annotations: None,
  )
}

fn handle_project_structure_resource(_request) {
  mcp.ReadResourceResult(
    contents: [
      mcp.TextResource(mcp.TextResourceContents(
        uri: "file:///project/structure.md",
        text: "# Project Structure\n\nThis is a Model Context Protocol toolkit implementation in Gleam.\n\n## Features\n- Multi-transport support\n- Production-ready architecture\n- Comprehensive testing",
        mime_type: Some("text/markdown"),
      )),
    ],
    meta: None,
  )
  |> Ok
}

pub type WeatherToolRequest {
  WeatherToolRequest(location: String)
}

fn decode_weather_request() -> decode.Decoder(WeatherToolRequest) {
  use location <- decode.field("location", decode.string)
  decode.success(WeatherToolRequest(location:))
}

fn create_weather_tool() -> mcp.Tool {
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

fn handle_weather_tool_request(_request) {
  mcp.CallToolResult(
    content: [
      mcp.TextToolContent(mcp.TextContent(
        type_: "text",
        text: "Current weather information:\nTemperature: 72°F\nConditions: Partly cloudy\nHumidity: 65%",
        annotations: None,
      )),
    ],
    is_error: Some(False),
    meta: None,
  )
  |> Ok
}
