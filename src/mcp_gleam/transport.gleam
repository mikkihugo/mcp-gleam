import gleam/erlang/process.{type Subject}
import gleam/io
import gleam/json.{type Json}
import gleam/option.{type Option}
import gleam/result
import mcp_gleam/server/stdio

/// Represents different transport mechanisms for MCP
pub type Transport {
  Stdio(StdioTransport)
  // WebSocket and SSE transports require mist dependency
  // They are available only when mist is compiled in
}

/// Configuration for stdio transport
pub type StdioTransport {
  StdioTransport
}

/// Configuration for WebSocket transport
pub type WebSocketTransport {
  WebSocketTransport(port: Int, host: String)
}

/// Configuration for Server-Sent Events transport
pub type SSETransport {
  SSETransport(port: Int, host: String, endpoint: String)
}

/// Message to be sent over any transport
pub type TransportMessage {
  TransportMessage(content: String, id: Option(String))
}

/// Events that can occur on a transport
pub type TransportEvent {
  MessageReceived(message: TransportMessage)
  ClientConnected(client_id: String)
  ClientDisconnected(client_id: String)
  TransportError(error: String)
}

/// Transport interface for sending and receiving messages
pub type TransportInterface {
  TransportInterface(
    send: fn(TransportMessage) -> Result(Nil, String),
    receive: fn() -> Result(TransportEvent, String),
    start: fn() -> Result(Subject(TransportEvent), String),
    stop: fn() -> Result(Nil, String),
  )
}

/// Create a transport interface for the given transport type
pub fn create_transport(transport: Transport) -> Result(TransportInterface, String) {
  case transport {
    Stdio(_) -> create_stdio_transport()
    // WebSocket and SSE transports are not available in stdio-only build
  }
}

/// Create stdio transport interface
fn create_stdio_transport() -> Result(TransportInterface, String) {
  Ok(TransportInterface(
    send: stdio_send,
    receive: stdio_receive,
    start: stdio_start,
    stop: stdio_stop,
  ))
}

/// Create WebSocket transport interface  
fn create_websocket_transport(config: WebSocketTransport) -> Result(TransportInterface, String) {
  Ok(TransportInterface(
    send: websocket_send,
    receive: websocket_receive,
    start: fn() { websocket_start(config) },
    stop: websocket_stop,
  ))
}

/// Create SSE transport interface
fn create_sse_transport(config: SSETransport) -> Result(TransportInterface, String) {
  Ok(TransportInterface(
    send: sse_send,
    receive: sse_receive,
    start: fn() { sse_start(config) },
    stop: sse_stop,
  ))
}

// Stdio transport implementations
fn stdio_send(message: TransportMessage) -> Result(Nil, String) {
  // Send to stdout
  io.println(message.content)
  Ok(Nil)
}

fn stdio_receive() -> Result(TransportEvent, String) {
  case mcp_gleam/server/stdio.read_message() {
    Ok(content) -> {
      let transport_msg = TransportMessage(content: content, id: None)
      Ok(MessageReceived(transport_msg))
    }
    Error(_) -> Error("Failed to read from stdin")
  }
}

fn stdio_start() -> Result(Subject(TransportEvent), String) {
  let event_subject = process.new_subject()
  // Stdio is always available, just return the subject
  Ok(event_subject)
}

fn stdio_stop() -> Result(Nil, String) {
  Ok(Nil)
}