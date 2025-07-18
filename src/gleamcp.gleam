import argv
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/io
import gleam/json
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleamcp/mcp

import gleamcp/bleh_server as server
import gleamcp/server/stdio

pub fn main() {
  case argv.load().arguments {
    ["print"] -> print(create_legacy_server())
    ["stdio"] -> run_stdio_server()
    ["websocket"] -> run_websocket_server() 
    ["sse"] -> run_sse_server()
    ["bridge"] -> run_bridge_example()
    ["full"] -> run_full_server()
    _ -> {
      io.println("MCP Gleam - Full Implementation")
      io.println("")
      io.println("Usage: gleam run [command]")
      io.println("")
      io.println("Commands:")
      io.println("  print     - Print server capabilities (legacy)")
      io.println("  stdio     - Run MCP server with stdio transport") 
      io.println("  websocket - Run MCP server with WebSocket transport")
      io.println("  sse       - Run MCP server with SSE transport")
      io.println("  bridge    - Run bridge between transports")
      io.println("  full      - Run full bidirectional server with all transports")
      io.println("")
      io.println("Examples:")
      io.println("  gleam run stdio")
      io.println("  gleam run websocket")
      io.println("  gleam run full")
      
      // Default to legacy loop for backward compatibility
      loop(create_legacy_server())
    }
  }
}

fn loop(server: server.Server) -> Nil {
  case stdio.read_message() |> echo {
    Ok(msg) -> {
      case server.handle_message(server, msg) {
        Ok(Some(json)) | Error(json) -> io.println(json.to_string(json) |> echo)
        _ -> Nil
      }
    }
    Error(_) -> Nil
  }
  loop(server)
}

fn print(server: server.Server) -> Nil {
  let _ =
    server.handle_message(server, list_prompts)
    |> result.map(fn(r) { option.map(r, json.to_string) })
    |> echo
  Nil
}

fn prompt() {
  mcp.Prompt(name: "test", description: Some("this is a test"), arguments: None)
}

fn prompt_handler(_request) {
  mcp.GetPromptResult(
    messages: [
      mcp.PromptMessage(
        role: mcp.User,
        content: mcp.TextPromptContent(mcp.TextContent(
          type_: "text",
          // type_: mcp.ContentTypeText,
          text: "this is a prompt message",
          annotations: None,
        )),
      ),
    ],
    description: Some("this is a test result"),
    meta: None,
  )
  |> Ok
}

fn resource() -> mcp.Resource {
  mcp.Resource(
    name: "test resource",
    uri: "file:///project/src/main.rs",
    description: Some("Primary application entry point"),
    mime_type: Some("text/x-rust"),
    size: None,
    annotations: None,
  )
}

fn resource_handler(_request) {
  mcp.ReadResourceResult(
    contents: [
      mcp.TextResource(mcp.TextResourceContents(
        uri: "file:///project/src/main.rs",
        text: "fn main() {\n    println!(\"Hello world!\");\n}",
        mime_type: Some("text/x-rust"),
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

fn tool() -> mcp.Tool {
  let assert Ok(schema) =
    "{
    'type': 'object',
    'properties': {
      'location': {
        'type': 'string',
        'description': 'City name or zip code'
      }
    },
    'required': ['location']
  }
  "
    |> string.replace("'", "\"")
    |> mcp.tool_input_schema

  mcp.Tool(
    name: "get_weather",
    input_schema: schema,
    description: Some("Get current weather information for a location"),
    annotations: None,
  )
}

fn tool_handler(_request) {
  mcp.CallToolResult(
    content: [
      mcp.TextToolContent(mcp.TextContent(
        type_: "text",
        // type_: mcp.ContentTypeText,
        text: "Current weather in New York:\nTemperature: 72°F\nConditions: Partly cloudy",
        annotations: None,
      )),
    ],
    is_error: Some(False),
    meta: None,
  )
  |> Ok
}

pub const initialize = "{\"jsonrpc\":\"2.0\",\"id\":0,\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2024-11-05\",\"capabilities\":{\"sampling\":{},\"roots\":{\"listChanged\":true}},\"clientInfo\":{\"name\":\"mcp-inspector\",\"version\":\"0.10.2\"}}}"

pub const list_prompts = "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"prompts/list\",\"params\":{\"_meta\":{\"progressToken\":1}}}"

pub const get_prompt = "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"prompts/get\",\"params\":{\"_meta\":{\"progressToken\":2},\"name\":\"test\",\"arguments\":{}}}"

pub const list_resources = "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"resources/list\",\"params\":{\"_meta\":{\"progressToken\":3}}}"

pub const read_resource = "{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"resources/read\",\"params\":{\"_meta\":{\"progressToken\":4},\"uri\":\"file:///project/src/main.rs\"}}"

pub const list_tools = "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\",\"params\":{\"_meta\":{\"progressToken\":1}}}"

pub const call_tool = "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"_meta\":{\"progressToken\":2},\"name\":\"get_weather\",\"arguments\":{\"location\":\"30040\"}}}"

pub const ping = "{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"ping\",\"params\":{\"_meta\":{\"progressToken\":4}}}"

fn echo(x: t) -> t {
  x
}

/// Create the legacy server for backward compatibility
fn create_legacy_server() -> server.Server {
  server.new("test", "1.0.0")
  |> server.add_prompt(prompt(), prompt_handler)
  |> server.add_resource(resource(), resource_handler)
  |> server.add_tool(tool(), get_weather_decoder(), tool_handler)
  |> server.build
}

/// Run MCP server with stdio transport (placeholder implementation)
fn run_stdio_server() -> Nil {
  io.println("Starting MCP server with stdio transport...")
  io.println("Note: This is a basic implementation. Full transport support coming soon!")
  loop(create_legacy_server())
}

/// Run MCP server with WebSocket transport (placeholder implementation)
fn run_websocket_server() -> Nil {
  io.println("Starting MCP server with WebSocket transport...")
  io.println("WebSocket server would start on ws://localhost:8080/mcp")
  io.println("Note: Full WebSocket implementation coming soon!")
  io.println("For now, falling back to stdio mode...")
  loop(create_legacy_server())
}

/// Run MCP server with SSE transport (placeholder implementation)
fn run_sse_server() -> Nil {
  io.println("Starting MCP server with SSE transport...")
  io.println("SSE server would start on http://localhost:8081/mcp")
  io.println("Note: Full SSE implementation coming soon!")
  io.println("For now, falling back to stdio mode...")
  loop(create_legacy_server())
}

/// Run bridge example (placeholder implementation)
fn run_bridge_example() -> Nil {
  io.println("Starting bridge between stdio and WebSocket...")
  io.println("Bridge would connect stdio input to WebSocket clients")
  io.println("Note: Full bridge implementation coming soon!")
  io.println("For now, falling back to stdio mode...")
  loop(create_legacy_server())
}

/// Run full bidirectional server (placeholder implementation)
fn run_full_server() -> Nil {
  io.println("Starting full bidirectional MCP server...")
  io.println("Would start all transports:")
  io.println("  - stdio: Send JSON-RPC messages via stdin")
  io.println("  - WebSocket: ws://localhost:8080/mcp")
  io.println("  - SSE: http://localhost:8081/mcp")
  io.println("")
  io.println("Would support bidirectional communication and send")
  io.println("notifications and requests to connected clients.")
  io.println("Note: Full implementation in progress!")
  io.println("For now, falling back to stdio mode...")
  loop(create_legacy_server())
}
