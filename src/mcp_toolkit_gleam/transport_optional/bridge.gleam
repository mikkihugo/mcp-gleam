import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import mcp_toolkit_gleam/core/transport.{type Transport, type TransportEvent, type TransportMessage, type TransportInterface}

/// Bridge configuration for connecting different transports
pub type Bridge {
  Bridge(
    id: String,
    source_transport: Transport,
    target_transport: Transport,
    message_filter: Option(MessageFilter),
    transformation: Option(MessageTransformation),
    bidirectional: Bool,
  )
}

/// Message filter function type
pub type MessageFilter = fn(TransportMessage) -> Bool

/// Message transformation function type  
pub type MessageTransformation = fn(TransportMessage) -> TransportMessage

/// Bridge manager state
pub type BridgeManager {
  BridgeManager(
    bridges: Dict(String, BridgeInfo),
    transport_interfaces: Dict(String, TransportInterface),
    message_subject: Subject(BridgeMessage),
  )
}

/// Bridge information
pub type BridgeInfo {
  BridgeInfo(
    bridge: Bridge,
    source_subject: Subject(TransportEvent),
    target_subject: Subject(TransportEvent),
    active: Bool,
  )
}

/// Internal bridge messages
pub type BridgeMessage {
  StartBridge(String)
  StopBridge(String)
  MessageForwarded(source: String, target: String, message: TransportMessage)
  BridgeError(bridge_id: String, error: String)
  TransportEventReceived(bridge_id: String, source: String, event: TransportEvent)
}

/// Create a new bridge manager
pub fn new_bridge_manager() -> BridgeManager {
  BridgeManager(
    bridges: dict.new(),
    transport_interfaces: dict.new(),
    message_subject: process.new_subject(),
  )
}

/// Add a bridge to the manager
pub fn add_bridge(
  manager: BridgeManager,
  bridge: Bridge,
) -> Result(BridgeManager, String) {
  // Create transport interfaces
  use source_interface <- result.try(transport.create_transport(bridge.source_transport))
  use target_interface <- result.try(transport.create_transport(bridge.target_transport))
  
  // Start transports
  use source_subject <- result.try(source_interface.start())
  use target_subject <- result.try(target_interface.start())
  
  let bridge_info = BridgeInfo(
    bridge: bridge,
    source_subject: source_subject,
    target_subject: target_subject,
    active: False,
  )
  
  let new_manager = BridgeManager(
    ..manager,
    bridges: dict.insert(manager.bridges, bridge.id, bridge_info),
    transport_interfaces: manager.transport_interfaces
      |> dict.insert("source_" <> bridge.id, source_interface)
      |> dict.insert("target_" <> bridge.id, target_interface),
  )
  
  Ok(new_manager)
}

/// Start the bridge manager
pub fn start_bridge_manager(
  manager: BridgeManager,
) -> Result(Subject(BridgeMessage), String) {
  let bridge_actor = actor.start_spec(actor.Spec(
    init: fn() {
      actor.Ready(manager, process.new_selector()
        |> process.selecting(manager.message_subject, fn(msg) { msg }))
    },
    init_timeout: 5000,
    loop: handle_bridge_message,
  ))
  
  case bridge_actor {
    Ok(_) -> {
      io.println("Bridge manager started")
      Ok(manager.message_subject)
    }
    Error(err) -> Error("Failed to start bridge manager: " <> string.inspect(err))
  }
}

/// Handle bridge manager messages
fn handle_bridge_message(
  message: BridgeMessage,
  state: BridgeManager,
) -> actor.Next(BridgeMessage, BridgeManager) {
  case message {
    StartBridge(bridge_id) -> {
      start_bridge(bridge_id, state)
    }
    StopBridge(bridge_id) -> {
      stop_bridge(bridge_id, state)
    }
    MessageForwarded(source, target, message) -> {
      io.println("Message forwarded from " <> source <> " to " <> target <> ": " <> message.content)
      actor.continue(state)
    }
    BridgeError(bridge_id, error) -> {
      io.println("Bridge error in " <> bridge_id <> ": " <> error)
      actor.continue(state)
    }
    TransportEventReceived(bridge_id, source, event) -> {
      handle_transport_event_for_bridge(bridge_id, source, event, state)
    }
  }
}

/// Start a specific bridge
fn start_bridge(
  bridge_id: String,
  state: BridgeManager,
) -> actor.Next(BridgeMessage, BridgeManager) {
  case dict.get(state.bridges, bridge_id) {
    Ok(bridge_info) -> {
      // Spawn event handlers for the bridge
      spawn_bridge_event_handlers(bridge_info, state.message_subject)
      
      let updated_bridge_info = BridgeInfo(..bridge_info, active: True)
      let new_state = BridgeManager(
        ..state,
        bridges: dict.insert(state.bridges, bridge_id, updated_bridge_info),
      )
      
      io.println("Bridge started: " <> bridge_id)
      actor.continue(new_state)
    }
    Error(_) -> {
      io.println("Bridge not found: " <> bridge_id)
      actor.continue(state)
    }
  }
}

/// Stop a specific bridge
fn stop_bridge(
  bridge_id: String,
  state: BridgeManager,
) -> actor.Next(BridgeMessage, BridgeManager) {
  case dict.get(state.bridges, bridge_id) {
    Ok(bridge_info) -> {
      let updated_bridge_info = BridgeInfo(..bridge_info, active: False)
      let new_state = BridgeManager(
        ..state,
        bridges: dict.insert(state.bridges, bridge_id, updated_bridge_info),
      )
      
      io.println("Bridge stopped: " <> bridge_id)
      actor.continue(new_state)
    }
    Error(_) -> {
      io.println("Bridge not found: " <> bridge_id)
      actor.continue(state)
    }
  }
}

/// Handle transport events for a specific bridge
fn handle_transport_event_for_bridge(
  bridge_id: String,
  source: String,
  event: TransportEvent,
  state: BridgeManager,
) -> actor.Next(BridgeMessage, BridgeManager) {
  case dict.get(state.bridges, bridge_id) {
    Ok(bridge_info) if bridge_info.active -> {
      case event {
        transport.MessageReceived(message) -> {
          forward_message(bridge_info, source, message, state)
        }
        transport.ClientConnected(client_id) -> {
          io.println("Client connected to bridge " <> bridge_id <> " via " <> source <> ": " <> client_id)
          actor.continue(state)
        }
        transport.ClientDisconnected(client_id) -> {
          io.println("Client disconnected from bridge " <> bridge_id <> " via " <> source <> ": " <> client_id)
          actor.continue(state)
        }
        transport.TransportError(error) -> {
          process.send(state.message_subject, BridgeError(bridge_id, error))
          actor.continue(state)
        }
      }
    }
    _ -> {
      // Bridge not found or not active
      actor.continue(state)
    }
  }
}

/// Forward a message through the bridge
fn forward_message(
  bridge_info: BridgeInfo,
  source: String,
  message: TransportMessage,
  state: BridgeManager,
) -> actor.Next(BridgeMessage, BridgeManager) {
  // Apply message filter if configured
  let should_forward = case bridge_info.bridge.message_filter {
    Some(filter) -> filter(message)
    None -> True
  }
  
  case should_forward {
    True -> {
      // Apply message transformation if configured
      let transformed_message = case bridge_info.bridge.transformation {
        Some(transform) -> transform(message)
        None -> message
      }
      
      // Determine target transport
      let target_transport_id = case source {
        s if string.starts_with(s, "source_") -> "target_" <> bridge_info.bridge.id
        _ -> "source_" <> bridge_info.bridge.id
      }
      
      // Send message to target transport
      case dict.get(state.transport_interfaces, target_transport_id) {
        Ok(target_interface) -> {
          case target_interface.send(transformed_message) {
            Ok(_) -> {
              process.send(state.message_subject, MessageForwarded(source, target_transport_id, transformed_message))
              actor.continue(state)
            }
            Error(err) -> {
              process.send(state.message_subject, BridgeError(bridge_info.bridge.id, "Failed to send message: " <> err))
              actor.continue(state)
            }
          }
        }
        Error(_) -> {
          process.send(state.message_subject, BridgeError(bridge_info.bridge.id, "Target transport not found: " <> target_transport_id))
          actor.continue(state)
        }
      }
    }
    False -> {
      // Message filtered out
      actor.continue(state)
    }
  }
}

/// Spawn event handlers for a bridge
fn spawn_bridge_event_handlers(
  bridge_info: BridgeInfo,
  manager_subject: Subject(BridgeMessage),
) -> Nil {
  // In a full implementation, these would be proper actors
  // that listen for transport events and forward them to the bridge manager
  
  // Simplified event forwarding for source transport
  process.send(manager_subject, TransportEventReceived(
    bridge_info.bridge.id,
    "source_" <> bridge_info.bridge.id,
    transport.ClientConnected("example_source"),
  ))
  
  // Simplified event forwarding for target transport  
  process.send(manager_subject, TransportEventReceived(
    bridge_info.bridge.id,
    "target_" <> bridge_info.bridge.id,
    transport.ClientConnected("example_target"),
  ))
}

/// Create a simple bridge between two transports
pub fn create_simple_bridge(
  id: String,
  source: Transport,
  target: Transport,
) -> Bridge {
  Bridge(
    id: id,
    source_transport: source,
    target_transport: target,
    message_filter: None,
    transformation: None,
    bidirectional: True,
  )
}

/// Create a filtered bridge that only forwards certain messages
pub fn create_filtered_bridge(
  id: String,
  source: Transport,
  target: Transport,
  filter: MessageFilter,
) -> Bridge {
  Bridge(
    id: id,
    source_transport: source,
    target_transport: target,
    message_filter: Some(filter),
    transformation: None,
    bidirectional: True,
  )
}

/// Create a transforming bridge that modifies messages
pub fn create_transforming_bridge(
  id: String,
  source: Transport,
  target: Transport,
  transformation: MessageTransformation,
) -> Bridge {
  Bridge(
    id: id,
    source_transport: source,
    target_transport: target,
    message_filter: None,
    transformation: Some(transformation),
    bidirectional: True,
  )
}

/// Predefined message filters

/// Filter for JSON-RPC requests only
pub fn requests_only_filter() -> MessageFilter {
  fn(message: TransportMessage) -> Bool {
    case json.decode(message.content, json.dynamic) {
      Ok(parsed) -> {
        // Check if it's a request (has method and id)
        json.to_string(parsed) |> string.contains("\"method\"") && 
        json.to_string(parsed) |> string.contains("\"id\"")
      }
      Error(_) -> False
    }
  }
}

/// Filter for JSON-RPC notifications only
pub fn notifications_only_filter() -> MessageFilter {
  fn(message: TransportMessage) -> Bool {
    case json.decode(message.content, json.dynamic) {
      Ok(parsed) -> {
        // Check if it's a notification (has method but no id)
        let content = json.to_string(parsed)
        string.contains(content, "\"method\"") && 
        !string.contains(content, "\"id\"")
      }
      Error(_) -> False
    }
  }
}

/// Predefined message transformations

/// Add a prefix to message content
pub fn add_prefix_transformation(prefix: String) -> MessageTransformation {
  fn(message: TransportMessage) -> TransportMessage {
    TransportMessage(
      content: prefix <> message.content,
      id: message.id,
    )
  }
}

/// Transform message IDs 
pub fn transform_id_transformation(transform_fn: fn(String) -> String) -> MessageTransformation {
  fn(message: TransportMessage) -> TransportMessage {
    TransportMessage(
      content: message.content,
      id: case message.id {
        Some(id) -> Some(transform_fn(id))
        None -> None
      },
    )
  }
}