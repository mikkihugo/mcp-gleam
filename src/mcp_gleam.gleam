import argv
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/io
import gleam/json
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import mcp_gleam/mcp

import mcp_gleam/bleh_server as server
import mcp_gleam/server/stdio

pub fn main() {
  case argv.load().arguments {
    ["print"] -> print(create_legacy_server())
    ["stdio"] -> run_stdio_server()
    _ -> {
      io.println("MCP Gleam - Production-ready MCP Server")
      io.println("")
      io.println("Usage: gleam run [command]")
      io.println("")
      io.println("Commands:")
      io.println("  print     - Print server capabilities (legacy)")
      io.println("  stdio     - Run MCP server with stdio transport") 
      io.println("")
      io.println("Note: WebSocket and SSE transports require the 'mist' dependency.")
      io.println("See mcp_full.gleam for full transport examples.")
      io.println("")
      io.println("Examples:")
      io.println("  gleam run stdio")
      
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

pub const initialize = "{\"jsonrpc\":\"2.0\",\"id\":0,\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2025-03-26\",\"capabilities\":{\"sampling\":{},\"roots\":{\"listChanged\":true}},\"clientInfo\":{\"name\":\"mcp-inspector\",\"version\":\"0.10.2\"}}}"

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

/// Run MCP server with stdio transport 
fn run_stdio_server() -> Nil {
  io.println("Starting MCP server with stdio transport...")
  io.println("Listening for JSON-RPC messages on stdin...")
  loop(create_legacy_server())
}
