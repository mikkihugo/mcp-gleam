import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/io
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import mcp_toolkit_gleam/core/protocol as mcp
import mcp_toolkit_gleam/core/transport.{type Transport, type TransportEvent, type TransportMessage}
import jsonrpc

/// Bidirectional server state
pub type BidirectionalServer {
  BidirectionalServer(
    server: mcp_gleam/server.Server,
    transports: List(Transport),
    active_connections: Dict(String, ConnectionInfo),
    message_subject: Subject(ServerMessage),
    next_request_id: Int,
  )
}

/// Connection information
pub type ConnectionInfo {
  ConnectionInfo(
    id: String,
    transport_type: String,
    capabilities: Option(mcp.ClientCapabilities),
  )
}

/// Internal server messages
pub type ServerMessage {
  TransportEventReceived(TransportEvent)
  SendNotification(method: String, params: json.Json, target: Option(String))
  SendRequest(method: String, params: json.Json, target: Option(String))
  RequestResponse(id: String, result: Result(json.Json, mcp.McpError))
}

/// Bidirectional server capabilities
pub type BidirectionalCapabilities {
  BidirectionalCapabilities(
    server_initiated_requests: Bool,
    notifications: Bool,
    resource_subscriptions: Bool,
    prompt_subscriptions: Bool,
    tool_subscriptions: Bool,
  )
}

/// Create a new bidirectional server
pub fn new_bidirectional_server(
  server: mcp_gleam/server.Server,
  transports: List(Transport),
) -> Result(BidirectionalServer, String) {
  let message_subject = process.new_subject()
  
  Ok(BidirectionalServer(
    server: server,
    transports: transports,
    active_connections: dict.new(),
    message_subject: message_subject,
    next_request_id: 1,
  ))
}

/// Start the bidirectional server
pub fn start_bidirectional_server(
  server: BidirectionalServer,
) -> Result(Subject(ServerMessage), String) {
  // Start all transports
  use transport_results <- result.try(
    server.transports
    |> list.map(transport.create_transport)
    |> result.all
  )
  
  // Start transport event handlers
  list.each(transport_results, fn(transport_interface) {
    case transport_interface.start() {
      Ok(event_subject) -> {
        spawn_transport_handler(event_subject, server.message_subject)
      }
      Error(err) -> {
        io.println("Failed to start transport: " <> err)
      }
    }
  })
  
  // Start the main server actor
  let server_actor = actor.start_spec(actor.Spec(
    init: fn() { 
      actor.Ready(server, process.new_selector() 
        |> process.selecting(server.message_subject, fn(msg) { msg }))
    },
    init_timeout: 5000,
    loop: handle_server_message,
  ))
  
  case server_actor {
    Ok(actor_subject) -> {
      io.println("Bidirectional MCP server started")
      Ok(server.message_subject)
    }
    Error(err) -> Error("Failed to start server actor: " <> string.inspect(err))
  }
}

/// Handle server messages
fn handle_server_message(
  message: ServerMessage,
  state: BidirectionalServer,
) -> actor.Next(ServerMessage, BidirectionalServer) {
  case message {
    TransportEventReceived(event) -> {
      handle_transport_event(event, state)
    }
    SendNotification(method, params, target) -> {
      send_notification_to_clients(method, params, target, state)
      actor.continue(state)
    }
    SendRequest(method, params, target) -> {
      send_request_to_clients(method, params, target, state)
    }
    RequestResponse(id, result) -> {
      handle_request_response(id, result, state)
      actor.continue(state)
    }
  }
}

/// Handle transport events
fn handle_transport_event(
  event: TransportEvent,
  state: BidirectionalServer,
) -> actor.Next(ServerMessage, BidirectionalServer) {
  case event {
    transport.MessageReceived(message) -> {
      handle_incoming_message(message, state)
    }
    transport.ClientConnected(client_id) -> {
      let connection_info = ConnectionInfo(
        id: client_id,
        transport_type: "unknown", // Would be determined by transport
        capabilities: None,
      )
      let new_state = BidirectionalServer(
        ..state,
        active_connections: dict.insert(state.active_connections, client_id, connection_info),
      )
      io.println("Client connected: " <> client_id)
      actor.continue(new_state)
    }
    transport.ClientDisconnected(client_id) -> {
      let new_state = BidirectionalServer(
        ..state,
        active_connections: dict.delete(state.active_connections, client_id),
      )
      io.println("Client disconnected: " <> client_id)
      actor.continue(new_state)
    }
    transport.TransportError(error) -> {
      io.println("Transport error: " <> error)
      actor.continue(state)
    }
  }
}

/// Handle incoming messages from clients
fn handle_incoming_message(
  message: TransportMessage,
  state: BidirectionalServer,
) -> actor.Next(ServerMessage, BidirectionalServer) {
  // Parse JSON-RPC message
  case json.decode(message.content, jsonrpc.decode_message) {
    Ok(rpc_message) -> {
      case rpc_message {
        jsonrpc.Request(id, method, params) -> {
          // Handle client request using existing server
          case mcp_gleam/server.handle_message(state.server, message.content) {
            Ok(Some(response)) -> {
              // Send response back through transport
              let transport_msg = TransportMessage(
                content: json.to_string(response),
                id: Some(string.inspect(id)),
              )
              // In a full implementation, would route to correct transport
              actor.continue(state)
            }
            Ok(None) -> actor.continue(state)
            Error(error_response) -> {
              let transport_msg = TransportMessage(
                content: json.to_string(error_response),
                id: Some(string.inspect(id)),
              )
              actor.continue(state)
            }
          }
        }
        jsonrpc.Notification(method, params) -> {
          // Handle client notification
          handle_client_notification(method, params, state)
        }
        jsonrpc.Response(id, result) -> {
          // Handle response to server-initiated request
          handle_client_response(id, result, state)
        }
        jsonrpc.ErrorResponse(id, error) -> {
          // Handle error response to server-initiated request
          let mcp_error = mcp.ApplicationError(error.message)
          process.send(state.message_subject, RequestResponse(string.inspect(id), Error(mcp_error)))
          actor.continue(state)
        }
      }
    }
    Error(_) -> {
      io.println("Failed to parse JSON-RPC message: " <> message.content)
      actor.continue(state)
    }
  }
}

/// Handle client notifications
fn handle_client_notification(
  method: String,
  params: Option(json.Json),
  state: BidirectionalServer,
) -> actor.Next(ServerMessage, BidirectionalServer) {
  case method {
    "initialized" -> {
      io.println("Client initialized")
      actor.continue(state)
    }
    "notifications/message" -> {
      // Handle notification from client
      actor.continue(state)
    }
    _ -> {
      io.println("Unknown notification method: " <> method)
      actor.continue(state)
    }
  }
}

/// Handle client responses to server-initiated requests
fn handle_client_response(
  id: json.Json,
  result: Result(json.Json, jsonrpc.Error),
  state: BidirectionalServer,
) -> actor.Next(ServerMessage, BidirectionalServer) {
  let id_str = json.to_string(id)
  case result {
    Ok(result_json) -> {
      process.send(state.message_subject, RequestResponse(id_str, Ok(result_json)))
    }
    Error(error) -> {
      let mcp_error = mcp.ApplicationError(error.message)
      process.send(state.message_subject, RequestResponse(id_str, Error(mcp_error)))
    }
  }
  actor.continue(state)
}

/// Send notification to all or specific clients
fn send_notification_to_clients(
  method: String,
  params: json.Json,
  target: Option(String),
  state: BidirectionalServer,
) -> Nil {
  let notification = jsonrpc.Notification(method, Some(params))
  let message_content = json.to_string(jsonrpc.encode_message(notification))
  
  case target {
    Some(client_id) -> {
      // Send to specific client
      send_to_client(client_id, message_content, state)
    }
    None -> {
      // Send to all clients
      dict.each(state.active_connections, fn(client_id, _) {
        send_to_client(client_id, message_content, state)
      })
    }
  }
}

/// Send request to clients
fn send_request_to_clients(
  method: String,
  params: json.Json,
  target: Option(String),
  state: BidirectionalServer,
) -> actor.Next(ServerMessage, BidirectionalServer) {
  let request_id = json.int(state.next_request_id)
  let request = jsonrpc.Request(request_id, method, Some(params))
  let message_content = json.to_string(jsonrpc.encode_message(request))
  
  case target {
    Some(client_id) -> {
      send_to_client(client_id, message_content, state)
    }
    None -> {
      dict.each(state.active_connections, fn(client_id, _) {
        send_to_client(client_id, message_content, state)
      })
    }
  }
  
  let new_state = BidirectionalServer(..state, next_request_id: state.next_request_id + 1)
  actor.continue(new_state)
}

/// Send message to specific client
fn send_to_client(client_id: String, content: String, state: BidirectionalServer) -> Nil {
  // In a full implementation, this would route to the correct transport
  // and send the message through the appropriate connection
  io.println("Sending to client " <> client_id <> ": " <> content)
}

/// Spawn a transport event handler
fn spawn_transport_handler(
  event_subject: Subject(TransportEvent),
  server_subject: Subject(ServerMessage),
) -> Nil {
  // In a full implementation, this would spawn an actor that listens
  // for transport events and forwards them to the server
  process.send(server_subject, TransportEventReceived(transport.ClientConnected("example")))
}

/// Notify clients of resource changes
pub fn notify_resource_changed(
  server: BidirectionalServer,
  uri: String,
) -> Nil {
  let params = json.object([
    #("uri", json.string(uri)),
  ])
  process.send(server.message_subject, SendNotification("notifications/resources/list_changed", params, None))
}

/// Notify clients of prompt changes
pub fn notify_prompt_changed(
  server: BidirectionalServer,
) -> Nil {
  let params = json.object([])
  process.send(server.message_subject, SendNotification("notifications/prompts/list_changed", params, None))
}

/// Notify clients of tool changes
pub fn notify_tool_changed(
  server: BidirectionalServer,
) -> Nil {
  let params = json.object([])
  process.send(server.message_subject, SendNotification("notifications/tools/list_changed", params, None))
}