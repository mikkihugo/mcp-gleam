/// MCP Toolkit Gleam - Stdio Transport Only
/// Production-ready MCP server with stdio transport (dependency-free)

import gleam/dynamic/decode
import gleam/erlang/process
import gleam/io
import gleam/json
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import mcp_toolkit_gleam/core/protocol as mcp
import mcp_toolkit_gleam/core/server
import mcp_toolkit_gleam/transport/stdio

pub fn main() {
  io.println("MCP Toolkit Gleam - Stdio Transport")
  io.println("Production-ready MCP server with stdio transport")
  io.println("Listening for JSON-RPC messages on stdin...")
  
  let server = create_example_server()
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

/// Create an example server with sample resources, tools, and prompts
fn create_example_server() -> server.Server {
  server.new("MCP Toolkit Gleam", "1.0.0")
  |> server.add_prompt(example_prompt(), example_prompt_handler)
  |> server.add_resource(example_resource(), example_resource_handler)
  |> server.add_tool(example_tool(), get_weather_decoder(), example_tool_handler)
  |> server.build
}

fn example_prompt() {
  mcp.Prompt(
    name: "code_review", 
    description: Some("Generate a comprehensive code review"),
    arguments: None
  )
}

fn example_prompt_handler(_request) {
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

fn example_resource() -> mcp.Resource {
  mcp.Resource(
    name: "project_structure",
    uri: "file:///project/structure.md",
    description: Some("Project structure and architecture documentation"),
    mime_type: Some("text/markdown"),
    size: None,
    annotations: None,
  )
}

fn example_resource_handler(_request) {
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

pub type GetWeather {
  GetWeather(location: String)
}

fn get_weather_decoder() -> decode.Decoder(GetWeather) {
  use location <- decode.field("location", decode.string)
  decode.success(GetWeather(location:))
}

fn example_tool() -> mcp.Tool {
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

fn example_tool_handler(_request) {
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