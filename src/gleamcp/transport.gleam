import gleam/erlang/process.{type Subject}
import gleam/io
import gleam/json.{type Json}
import gleam/option.{type Option}
import gleam/result
import gleamcp/server/stdio

/// Represents different transport mechanisms for MCP
pub type Transport {
  Stdio(StdioTransport)
  WebSocket(WebSocketTransport)  
  ServerSentEvents(SSETransport)
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
    WebSocket(config) -> create_websocket_transport(config)
    ServerSentEvents(config) -> create_sse_transport(config)
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
  case gleamcp/server/stdio.read_message() {
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

// WebSocket transport implementations
fn websocket_send(message: TransportMessage) -> Result(Nil, String) {
  // This would send to all connected WebSocket clients
  // Implementation depends on connection management
  io.println("WebSocket send: " <> message.content)
  Ok(Nil)
}

fn websocket_receive() -> Result(TransportEvent, String) {
  // This would be handled by the WebSocket server's event loop
  Error("WebSocket receive should be handled by server events")
}

fn websocket_start(config: WebSocketTransport) -> Result(Subject(TransportEvent), String) {
  let event_subject = process.new_subject()
  case gleamcp/transport/websocket.start_websocket_server(config.port, config.host, event_subject) {
    Ok(subject) -> Ok(subject)
    Error(err) -> Error(err)
  }
}

fn websocket_stop() -> Result(Nil, String) {
  // Would stop the WebSocket server
  Ok(Nil)
}

// SSE transport implementations
fn sse_send(message: TransportMessage) -> Result(Nil, String) {
  // This would send to all connected SSE clients
  io.println("SSE send: " <> message.content)
  Ok(Nil)
}

fn sse_receive() -> Result(TransportEvent, String) {
  // SSE is primarily one-way (server to client)
  // Client messages come via HTTP POST
  Error("SSE receive should be handled by HTTP POST endpoints")
}

fn sse_start(config: SSETransport) -> Result(Subject(TransportEvent), String) {
  let event_subject = process.new_subject()
  case gleamcp/transport/sse.start_sse_server(config.port, config.host, config.endpoint, event_subject) {
    Ok(subject) -> Ok(subject)
    Error(err) -> Error(err)
  }
}

fn sse_stop() -> Result(Nil, String) {
  // Would stop the SSE server
  Ok(Nil)
}