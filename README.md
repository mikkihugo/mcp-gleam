# MCP Gleam

[![Package Version](https://img.shields.io/hexpm/v/mcp_gleam)](https://hex.pm/packages/mcp_gleam)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/mcp_gleam/)

A production-ready Model Context Protocol (MCP) server implementation in Gleam with support for multiple transports.

## Features

- **Production-Ready**: Clean, minimal codebase designed for production use
- **Multiple Transport Support**: stdio (core), WebSocket, and Server-Sent Events (SSE) (optional)
- **Optional Dependencies**: Use only what you need - stdio works without any HTTP dependencies
- **Full MCP Protocol Compliance**: Latest 2025-03-26 specification with backward compatibility
- **Resource, Tools & Prompts**: Complete implementation of MCP capabilities
- **Extensible Architecture**: Easy to add new transports and capabilities

## Quick Start

### Stdio Only (No External Dependencies)

```sh
gleam add mcp_gleam
```

For stdio-only usage (most common), no additional dependencies are needed:

```gleam
import mcp_gleam

pub fn main() -> Nil {
  // Run with stdio transport (default)
  mcp_gleam.main()
}
```

### With WebSocket/SSE Support

To enable WebSocket and SSE transports, add the `mist` dependency:

```sh
gleam add mist
```
### Basic Usage Examples

#### Stdio Transport (Core)

```sh
# Default stdio mode
gleam run

# Explicit stdio mode  
gleam run stdio
```

#### WebSocket/SSE (Requires mist dependency)

For full transport support, see `mcp_full.gleam`:

```sh
# WebSocket server on localhost:8080
gleam run -m mcp_full websocket

# Server-Sent Events on localhost:8081  
gleam run -m mcp_full sse

# Full server with all transports
gleam run -m mcp_full full
```

## Architecture

### Core (stdio-only)
- **mcp_gleam**: Main entry point with stdio transport
- **mcp_gleam/transport**: Transport abstraction (stdio implementation)
- **mcp_gleam/server**: MCP server implementation
- **mcp_gleam/mcp**: Protocol types and handlers

### Optional (requires mist)
- **mcp_gleam/transport_optional/websocket**: WebSocket transport
- **mcp_gleam/transport_optional/sse**: Server-Sent Events transport
- **mcp_gleam/transport_optional/bidirectional**: Bidirectional communication
- **mcp_gleam/transport_optional/bridge**: Transport bridging

## Transport Types

### Stdio Transport (Core)

The traditional MCP transport using stdin/stdout for JSON-RPC communication. Works without any external dependencies.

```gleam
import mcp_gleam/transport

let stdio_transport = transport.Stdio(transport.StdioTransport)
```

Real-time bidirectional communication over WebSocket.

```gleam
let ws_transport = transport.WebSocket(transport.WebSocketTransport(
  port: 8080,
  host: "localhost"
))
```

Clients can connect to: `ws://localhost:8080/mcp`

### Server-Sent Events (SSE) Transport

One-way server-to-client communication with HTTP POST for client-to-server.

```gleam
let sse_transport = transport.ServerSentEvents(transport.SSETransport(
  port: 8081,
  host: "localhost",
  endpoint: "mcp"
))
```

- SSE endpoint: `http://localhost:8081/mcp` (GET)
- Message endpoint: `http://localhost:8081/mcp` (POST)

## Bidirectional Communication

The server supports server-initiated requests and notifications:

```gleam
import gleamcp/bidirectional

// Notify clients of resource changes
bidirectional.notify_resource_changed(server, "file://example.txt")

// Notify clients of tool changes  
bidirectional.notify_tool_changed(server)

// Send custom notifications
let params = json.object([#("message", json.string("Hello!"))])
process.send(server.message_subject, 
  bidirectional.SendNotification("custom/notification", params, None))
```

## Transport Bridging

Connect different transports to create hybrid communication patterns:

```gleam
import gleamcp/bridge

// Create a bridge between stdio and WebSocket
let stdio_transport = transport.Stdio(transport.StdioTransport)
let ws_transport = transport.WebSocket(transport.WebSocketTransport(
  port: 8080, host: "localhost"
))

let bridge_config = bridge.create_simple_bridge(
  "stdio-to-websocket",
  stdio_transport, 
  ws_transport
)

// Add message filtering
let filtered_bridge = bridge.create_filtered_bridge(
  "requests-only",
  stdio_transport,
  ws_transport, 
  bridge.requests_only_filter()
)
```

## Advanced Server Setup

```gleam
import gleamcp/server
import gleamcp/transport
import gleamcp/bidirectional

pub fn advanced_server() {
  // Create server with capabilities
  let server = server.new("My MCP Server", "1.0.0")
    |> server.description("Advanced MCP server example")
    |> server.add_resource(my_resource(), my_resource_handler)
    |> server.add_tool(my_tool(), my_tool_decoder(), my_tool_handler)
    |> server.resource_capabilities(True, True) // Enable subscriptions
    |> server.tool_capabilities(True) // Enable list_changed notifications
    |> server.enable_logging()
    |> server.build()

  // Configure multiple transports
  let transports = [
    transport.Stdio(transport.StdioTransport),
    transport.WebSocket(transport.WebSocketTransport(port: 8080, host: "0.0.0.0")),
    transport.ServerSentEvents(transport.SSETransport(port: 8081, host: "0.0.0.0", endpoint: "mcp")),
  ]

  // Start bidirectional server
  case bidirectional.new_bidirectional_server(server, transports) {
    Ok(bidir_server) -> {
      bidirectional.start_bidirectional_server(bidir_server)
    }
    Error(err) -> {
      io.println("Failed to start server: " <> err)
    }
  }
}
```

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

## Core Concepts

### Server

The server is your core interface to the MCP protocol. It handles connection management, protocol compliance, and message routing:

```gleam
let srv = server.new("My Server", "1.0.0")

// For stdio transport (legacy)
server.serve_stdio(srv) // Result(Pid?, StartError)
process.sleep_forever()

// For multiple transports (new)
bidirectional.start_bidirectional_server(srv)
```

### Resources

Resources are how you expose data to LLMs. They can be anything - files, API responses, database queries, system information, etc. Resources can be:

- Static (fixed URI)
- Dynamic (using URI templates)

Here's a simple example of a static resource:

```gleam
// static resource example - exposing a README file
let res = resource.new("docs://readme", "Project README")
  |> resource.description("The project's README file")
  |> resource.mime_type("text/markdown")

server.new()
  |> server.add_resource(res, fn(req) {
    let content = simplifile.read_file("README.md")
    resource.TextContents(
      uri: "docs://readme",
      mime_type: "text/markdown",
      text: content,
    )
  })
```

## Transport Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   MCP Client    │◄──►│  Transport Layer │◄──►│   MCP Server    │
│                 │    │                  │    │                 │
│  • Claude       │    │  • stdio         │    │  • Resources    │
│  • VS Code      │    │  • WebSocket     │    │  • Tools        │
│  • Custom App   │    │  • SSE           │    │  • Prompts      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                       ┌──────▼──────┐
                       │   Bridge    │
                       │             │
                       │ • Filter    │
                       │ • Transform │
                       │ • Route     │
                       └─────────────┘
```

## Protocol Support

### Supported Features
- ✅ Resources (static and templates)
- ✅ Tools with JSON schema validation
- ✅ Prompts and prompt templates
- ✅ Bidirectional communication
- ✅ Server-initiated notifications
- ✅ Resource/tool/prompt change notifications
- ✅ Multiple transport support
- ✅ Transport bridging
- ✅ Logging capabilities

### Partially Supported
- ⚠️ Sampling (basic support)
- ⚠️ Progress tracking (_meta field)

### Not Yet Supported
- ❌ Batch messages
- ❌ Pagination for large lists
- ❌ Experimental fields
- ❌ Resource templates with URI patterns

## Examples

See the `examples/` directory for more usage examples:

- `basic_stdio.gleam` - Simple stdio MCP server
- `websocket_server.gleam` - WebSocket MCP server
- `bridge_example.gleam` - Transport bridging
- `full_server.gleam` - Complete bidirectional server

Further documentation can be found at <https://hexdocs.pm/gleamcp>.
