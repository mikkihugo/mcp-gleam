import argv
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleamcp/bidirectional
import gleamcp/bridge
import gleamcp/mcp
import gleamcp/resource
import gleamcp/server
import gleamcp/transport

/// Full MCP server example with multiple transports
pub fn main() {
  case argv.load().arguments {
    ["stdio"] -> run_stdio_server()
    ["websocket"] -> run_websocket_server()
    ["sse"] -> run_sse_server()
    ["bridge"] -> run_bridge_example()
    ["full"] -> run_full_server()
    _ -> {
      io.println("Usage: gleam run [stdio|websocket|sse|bridge|full]")
      io.println("")
      io.println("Examples:")
      io.println("  gleam run stdio     - Run MCP server with stdio transport")
      io.println("  gleam run websocket - Run MCP server with WebSocket transport")
      io.println("  gleam run sse       - Run MCP server with SSE transport")
      io.println("  gleam run bridge    - Run bridge between stdio and WebSocket")
      io.println("  gleam run full      - Run full bidirectional server with all transports")
    }
  }
}

/// Run MCP server with stdio transport only
fn run_stdio_server() -> Nil {
  io.println("Starting MCP server with stdio transport...")
  
  let server = create_example_server()
  let stdio_transport = transport.Stdio(transport.StdioTransport)
  
  case transport.create_transport(stdio_transport) {
    Ok(transport_interface) -> {
      case transport_interface.start() {
        Ok(_) -> {
          io.println("Stdio MCP server started. Send JSON-RPC messages via stdin.")
          stdio_message_loop(server, transport_interface)
        }
        Error(err) -> {
          io.println("Failed to start stdio transport: " <> err)
        }
      }
    }
    Error(err) -> {
      io.println("Failed to create stdio transport: " <> err)
    }
  }
}

/// Run MCP server with WebSocket transport
fn run_websocket_server() -> Nil {
  io.println("Starting MCP server with WebSocket transport...")
  
  let server = create_example_server()
  let ws_transport = transport.WebSocket(transport.WebSocketTransport(
    port: 8080,
    host: "localhost",
  ))
  
  case transport.create_transport(ws_transport) {
    Ok(transport_interface) -> {
      case transport_interface.start() {
        Ok(_) -> {
          io.println("WebSocket MCP server started on ws://localhost:8080/mcp")
          io.println("Press Ctrl+C to stop.")
          wait_forever()
        }
        Error(err) -> {
          io.println("Failed to start WebSocket transport: " <> err)
        }
      }
    }
    Error(err) -> {
      io.println("Failed to create WebSocket transport: " <> err)
    }
  }
}

/// Run MCP server with SSE transport
fn run_sse_server() -> Nil {
  io.println("Starting MCP server with SSE transport...")
  
  let server = create_example_server()
  let sse_transport = transport.ServerSentEvents(transport.SSETransport(
    port: 8081,
    host: "localhost", 
    endpoint: "mcp",
  ))
  
  case transport.create_transport(sse_transport) {
    Ok(transport_interface) -> {
      case transport_interface.start() {
        Ok(_) -> {
          io.println("SSE MCP server started on http://localhost:8081/mcp")
          io.println("Press Ctrl+C to stop.")
          wait_forever()
        }
        Error(err) -> {
          io.println("Failed to start SSE transport: " <> err)
        }
      }
    }
    Error(err) -> {
      io.println("Failed to create SSE transport: " <> err)
    }
  }
}

/// Run bridge example between stdio and WebSocket
fn run_bridge_example() -> Nil {
  io.println("Starting bridge between stdio and WebSocket...")
  
  let stdio_transport = transport.Stdio(transport.StdioTransport)
  let ws_transport = transport.WebSocket(transport.WebSocketTransport(
    port: 8080,
    host: "localhost",
  ))
  
  // Create a bridge
  let bridge_config = bridge.create_simple_bridge(
    "stdio-to-websocket",
    stdio_transport,
    ws_transport,
  )
  
  // Create bridge manager
  let manager = bridge.new_bridge_manager()
  
  case bridge.add_bridge(manager, bridge_config) {
    Ok(updated_manager) -> {
      case bridge.start_bridge_manager(updated_manager) {
        Ok(bridge_subject) -> {
          io.println("Bridge started successfully!")
          io.println("Messages from stdio will be forwarded to WebSocket clients on ws://localhost:8080/mcp")
          io.println("Press Ctrl+C to stop.")
          wait_forever()
        }
        Error(err) -> {
          io.println("Failed to start bridge manager: " <> err)
        }
      }
    }
    Error(err) -> {
      io.println("Failed to add bridge: " <> err)
    }
  }
}

/// Run full bidirectional server with all transports
fn run_full_server() -> Nil {
  io.println("Starting full bidirectional MCP server...")
  
  let server = create_example_server()
  
  // Configure all transports
  let transports = [
    transport.Stdio(transport.StdioTransport),
    transport.WebSocket(transport.WebSocketTransport(port: 8080, host: "localhost")),
    transport.ServerSentEvents(transport.SSETransport(port: 8081, host: "localhost", endpoint: "mcp")),
  ]
  
  case bidirectional.new_bidirectional_server(server, transports) {
    Ok(bidir_server) -> {
      case bidirectional.start_bidirectional_server(bidir_server) {
        Ok(_) -> {
          io.println("Full bidirectional MCP server started!")
          io.println("Available endpoints:")
          io.println("  - stdio: Send JSON-RPC messages via stdin")
          io.println("  - WebSocket: ws://localhost:8080/mcp")
          io.println("  - SSE: http://localhost:8081/mcp")
          io.println("")
          io.println("The server supports bidirectional communication and can send")
          io.println("notifications and requests to connected clients.")
          io.println("Press Ctrl+C to stop.")
          wait_forever()
        }
        Error(err) -> {
          io.println("Failed to start bidirectional server: " <> err)
        }
      }
    }
    Error(err) -> {
      io.println("Failed to create bidirectional server: " <> err)
    }
  }
}

/// Create an example MCP server with sample resources and tools
fn create_example_server() -> server.Server {
  server.new("Full MCP Server", "1.0.0")
  |> server.description("A full-featured MCP server with multiple transports")
  |> server.add_resource(example_resource(), example_resource_handler)
  |> server.add_tool(example_tool(), example_tool_decoder(), example_tool_handler)
  |> server.resource_capabilities(True, True) // Enable subscriptions and list_changed
  |> server.tool_capabilities(True) // Enable list_changed
  |> server.enable_logging()
  |> server.build()
}

/// Example resource
fn example_resource() -> resource.Resource {
  resource.Resource(
    name: "System Information",
    uri: "system://info",
    description: Some("Current system information"),
    mime_type: Some("application/json"),
    size: None,
    annotations: None,
  )
}

/// Example resource handler
fn example_resource_handler(_request) -> Result(mcp.ReadResourceResult, mcp.McpError) {
  Ok(mcp.ReadResourceResult(
    contents: [
      mcp.TextResource(mcp.TextResourceContents(
        uri: "system://info",
        text: "{\"hostname\":\"mcp-server\",\"uptime\":\"1h 23m\",\"memory\":\"512MB\"}",
        mime_type: Some("application/json"),
      )),
    ],
    meta: None,
  ))
}

/// Example tool
fn example_tool() -> mcp.Tool {
  let assert Ok(schema) = mcp.tool_input_schema("{
    \"type\": \"object\",
    \"properties\": {
      \"message\": {
        \"type\": \"string\",
        \"description\": \"Message to echo\"
      }
    },
    \"required\": [\"message\"]
  }")
  
  mcp.Tool(
    name: "echo",
    input_schema: schema,
    description: Some("Echo a message back"),
    annotations: None,
  )
}

/// Example tool decoder
fn example_tool_decoder() -> gleam/dynamic/decode.Decoder(EchoArgs) {
  use message <- gleam/dynamic/decode.field("message", gleam/dynamic/decode.string)
  gleam/dynamic/decode.success(EchoArgs(message:))
}

/// Example tool arguments type
pub type EchoArgs {
  EchoArgs(message: String)
}

/// Example tool handler
fn example_tool_handler(request: mcp.CallToolRequest(EchoArgs)) -> Result(mcp.CallToolResult, String) {
  case request.arguments {
    Some(args) -> {
      Ok(mcp.CallToolResult(
        content: [
          mcp.TextToolContent(mcp.TextContent(
            type_: "text",
            text: "Echo: " <> args.message,
            annotations: None,
          )),
        ],
        is_error: Some(False),
        meta: None,
      ))
    }
    None -> {
      Error("No message provided")
    }
  }
}

/// Simple message loop for stdio transport
fn stdio_message_loop(server: server.Server, transport_interface: transport.TransportInterface) -> Nil {
  case transport_interface.receive() {
    Ok(transport.MessageReceived(message)) -> {
      // Handle the message with the server
      case server.handle_message(server, message.content) {
        Ok(Some(response)) -> {
          let response_msg = transport.TransportMessage(
            content: gleam/json.to_string(response),
            id: message.id,
          )
          let _ = transport_interface.send(response_msg)
          Nil
        }
        Ok(None) -> Nil
        Error(error_response) -> {
          let error_msg = transport.TransportMessage(
            content: gleam/json.to_string(error_response),
            id: message.id,
          )
          let _ = transport_interface.send(error_msg)
          Nil
        }
      }
      stdio_message_loop(server, transport_interface)
    }
    Ok(_) -> {
      // Other events, continue loop
      stdio_message_loop(server, transport_interface)
    }
    Error(_) -> {
      // Error reading, exit loop
      Nil
    }
  }
}

/// Wait forever (for server processes)
fn wait_forever() -> Nil {
  gleam/erlang/process.sleep_forever()
}