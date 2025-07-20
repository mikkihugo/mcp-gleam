import gleam/bytes_tree
import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/http.{type Header}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import mcp_toolkit_gleam/core/transport.{type TransportEvent, type TransportMessage}
import mist.{type Connection, type ResponseData}

/// SSE connection state
pub type SSEConnection {
  SSEConnection(
    id: String,
    connection: Connection,
    subject: Subject(SSEMessage),
  )
}

/// Internal SSE messages
pub type SSEMessage {
  SendEvent(data: String, event_type: Option(String), id: Option(String))
  ClientDisconnected
}

/// SSE server state
pub type SSEServer {
  SSEServer(
    connections: Dict(String, SSEConnection),
    port: Int,
    host: String,
    endpoint: String,
    event_subject: Subject(TransportEvent),
  )
}

/// Start an SSE server for MCP
pub fn start_sse_server(
  port: Int,
  host: String,
  endpoint: String,
  event_subject: Subject(TransportEvent),
) -> Result(Subject(TransportEvent), String) {
  let handler = fn(req: Request(Connection)) -> Response(ResponseData) {
    case list.contains(request.path_segments(req), endpoint) {
      True -> {
        case request.get_method(req) {
          http.Get -> handle_sse_connection(req, event_subject)
          http.Post -> handle_sse_message(req, event_subject)
          _ -> {
            response.new(405)
            |> response.set_body(mist.Bytes(bytes_tree.new()))
            |> response.set_header("Allow", "GET, POST")
          }
        }
      }
      False -> {
        response.new(404)
        |> response.set_body(mist.Bytes(bytes_tree.new()))
      }
    }
  }

  case mist.new(handler) |> mist.port(port) |> mist.start_http {
    Ok(_) -> {
      io.println("SSE server started on " <> host <> ":" <> string.inspect(port) <> "/" <> endpoint)
      Ok(event_subject)
    }
    Error(err) -> Error("Failed to start SSE server: " <> string.inspect(err))
  }
}

/// Handle SSE connection (GET request)
fn handle_sse_connection(
  req: Request(Connection),
  event_subject: Subject(TransportEvent),
) -> Response(ResponseData) {
  let connection_id = generate_connection_id()
  
  // Notify that a client connected
  process.send(event_subject, transport.ClientConnected(connection_id))

  // Set SSE headers
  response.new(200)
  |> response.set_header("Content-Type", "text/event-stream")
  |> response.set_header("Cache-Control", "no-cache")
  |> response.set_header("Connection", "keep-alive")
  |> response.set_header("Access-Control-Allow-Origin", "*")
  |> response.set_header("Access-Control-Allow-Headers", "Content-Type")
  |> response.set_body(mist.Chunked(sse_chunk_iterator(connection_id, event_subject)))
}

/// Handle SSE message (POST request for bidirectional communication)
fn handle_sse_message(
  req: Request(Connection),
  event_subject: Subject(TransportEvent),
) -> Response(ResponseData) {
  // In a real implementation, we would parse the request body
  // and forward the message to the appropriate handler
  case request.get_body(req) {
    Ok(body) -> {
      let transport_msg = transport.TransportMessage(content: string.inspect(body), id: None)
      process.send(event_subject, transport.MessageReceived(transport_msg))
      
      response.new(200)
      |> response.set_header("Content-Type", "application/json")
      |> response.set_body(mist.Bytes(bytes_tree.from_string("{\"status\":\"ok\"}")))
    }
    Error(_) -> {
      response.new(400)
      |> response.set_body(mist.Bytes(bytes_tree.from_string("{\"error\":\"Invalid request body\"}")))
    }
  }
}

/// Create an iterator for SSE chunks
fn sse_chunk_iterator(
  connection_id: String,
  event_subject: Subject(TransportEvent),
) -> Iterator(bytes_tree.BytesTree) {
  // This is a simplified implementation
  // In a real scenario, this would be connected to a message queue
  // that receives messages to send to the SSE client
  
  let initial_message = format_sse_event(
    data: "{\"jsonrpc\":\"2.0\",\"method\":\"initialized\",\"params\":{}}",
    event_type: Some("mcp-message"),
    id: Some("init-" <> connection_id)
  )
  
  // Return an iterator that yields the initial message
  // In a full implementation, this would be a proper iterator
  // that yields messages from a queue
  iterator.single(bytes_tree.from_string(initial_message))
}

/// Format an SSE event
fn format_sse_event(
  data: String,
  event_type: Option(String),
  id: Option(String),
) -> String {
  let event_lines = []
  
  let event_lines = case id {
    Some(id_val) -> ["id: " <> id_val, ..event_lines]
    None -> event_lines
  }
  
  let event_lines = case event_type {
    Some(type_val) -> ["event: " <> type_val, ..event_lines]
    None -> event_lines
  }
  
  let event_lines = ["data: " <> data, ..event_lines]
  let event_lines = ["", ..event_lines] // Empty line to end the event
  
  list.reverse(event_lines)
  |> string.join("\n")
}

/// Send message to SSE client
pub fn send_sse_message(
  connection: SSEConnection,
  message: TransportMessage,
) -> Result(Nil, String) {
  let event_type = Some("mcp-message")
  process.send(connection.subject, SendEvent(message.content, event_type, message.id))
  Ok(Nil)
}

/// Generate a unique connection ID
fn generate_connection_id() -> String {
  let timestamp = process.system_time(process.Millisecond)
  "sse_" <> string.inspect(timestamp)
}

// Import iterator if not available
import gleam/iterator