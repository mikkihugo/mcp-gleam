import gleam/bit_array
import gleam/bytes_tree
import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/http.{type Header}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import gleamcp/transport.{type TransportEvent, type TransportMessage}
import mist.{type Connection, type ResponseData}

/// WebSocket connection state
pub type WebSocketConnection {
  WebSocketConnection(
    id: String,
    connection: Connection,
    subject: Subject(WebSocketMessage),
  )
}

/// Internal WebSocket messages
pub type WebSocketMessage {
  SendMessage(TransportMessage)
  ClientMessage(String)
  ClientDisconnected
}

/// WebSocket server state
pub type WebSocketServer {
  WebSocketServer(
    connections: Dict(String, WebSocketConnection),
    port: Int,
    host: String,
    event_subject: Subject(TransportEvent),
  )
}

/// Start a WebSocket server for MCP
pub fn start_websocket_server(
  port: Int,
  host: String,
  event_subject: Subject(TransportEvent),
) -> Result(Subject(TransportEvent), String) {
  let handler = fn(req: Request(Connection)) -> Response(ResponseData) {
    case request.path_segments(req) {
      ["mcp"] -> {
        mist.websocket(
          request: req,
          on_init: on_websocket_init(event_subject),
          on_close: on_websocket_close,
          handler: handle_websocket_message,
        )
      }
      _ -> {
        response.new(404)
        |> response.set_body(mist.Bytes(bytes_tree.new()))
      }
    }
  }

  case mist.new(handler) |> mist.port(port) |> mist.start_http {
    Ok(_) -> {
      io.println("WebSocket server started on " <> host <> ":" <> string.inspect(port))
      Ok(event_subject)
    }
    Error(err) -> Error("Failed to start WebSocket server: " <> string.inspect(err))
  }
}

/// Initialize WebSocket connection
fn on_websocket_init(
  event_subject: Subject(TransportEvent),
) -> fn(Connection) -> #(WebSocketConnection, Option(process.Selector(WebSocketMessage))) {
  fn(connection: Connection) -> #(WebSocketConnection, Option(process.Selector(WebSocketMessage))) {
    let connection_id = generate_connection_id()
    let websocket_subject = process.new_subject()
    
    let ws_connection = WebSocketConnection(
      id: connection_id,
      connection: connection,
      subject: websocket_subject,
    )

    // Notify that a client connected
    process.send(event_subject, transport.ClientConnected(connection_id))

    let selector = process.new_selector()
      |> process.selecting(websocket_subject, fn(msg) { msg })

    #(ws_connection, Some(selector))
  }
}

/// Handle WebSocket close
fn on_websocket_close(state: WebSocketConnection) -> Nil {
  // Connection cleanup is handled automatically
  Nil
}

/// Handle WebSocket messages
fn handle_websocket_message(
  state: WebSocketConnection,
  conn: Connection,
  message: mist.WebsocketMessage(WebSocketMessage),
) -> actor.Next(WebSocketMessage, WebSocketConnection) {
  case message {
    mist.Text(text) -> {
      let transport_msg = transport.TransportMessage(content: text, id: None)
      // Forward to main transport event handler
      actor.continue(state)
    }
    mist.Binary(_) -> {
      // MCP uses text-based JSON-RPC, so binary messages are not expected
      actor.continue(state)
    }
    mist.Custom(SendMessage(msg)) -> {
      // Send message to WebSocket client
      case mist.send_text_frame(conn, msg.content) {
        Ok(_) -> actor.continue(state)
        Error(_) -> actor.continue(state)
      }
    }
    mist.Custom(ClientMessage(text)) -> {
      // Handle message from client
      actor.continue(state)
    }
    mist.Custom(ClientDisconnected) -> {
      // Handle client disconnection
      actor.Stop(process.Normal)
    }
    mist.Closed | mist.Shutdown -> {
      actor.Stop(process.Normal)
    }
  }
}

/// Send message to WebSocket client
pub fn send_websocket_message(
  connection: WebSocketConnection,
  message: TransportMessage,
) -> Result(Nil, String) {
  process.send(connection.subject, SendMessage(message))
  Ok(Nil)
}

/// Generate a unique connection ID
fn generate_connection_id() -> String {
  // Simple ID generation - in production, use a more robust method
  let timestamp = process.system_time(process.Millisecond)
  "ws_" <> string.inspect(timestamp)
}