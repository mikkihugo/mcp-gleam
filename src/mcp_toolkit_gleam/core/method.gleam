/// Initiates connection and negotiates protocol capabilities.
/// https://modelcontextprotocol.io/specification/2025-06-18/basic/lifecycle/#initialization
pub const initialize = "initialize"

/// Verifies connection liveness between client and server.
/// https://modelcontextprotocol.io/specification/2025-06-18/basic/utilities/ping/
pub const ping = "ping"

/// Lists all available server resources.
/// https://modelcontextprotocol.io/specification/2025-06-18/server/resources/
pub const resources_list = "resources/list"

/// Provides URI templates for constructing resource URIs.
/// https://modelcontextprotocol.io/specification/2025-06-18/server/resources/
pub const resources_templates_list = "resources/templates/list"

/// Retrieves content of a specific resource by URI.
/// https://modelcontextprotocol.io/specification/2025-06-18/server/resources/
pub const resources_read = "resources/read"

/// Lists all available prompt templates.
/// https://modelcontextprotocol.io/specification/2025-06-18/server/prompts/
pub const prompts_list = "prompts/list"

/// Retrieves a specific prompt template with filled parameters.
/// https://modelcontextprotocol.io/specification/2025-06-18/server/prompts/
pub const prompts_get = "prompts/get"

/// Lists all available executable tools.
/// https://modelcontextprotocol.io/specification/2025-06-18/server/tools/
pub const tools_list = "tools/list"

/// Invokes a specific tool with provided parameters.
/// https://modelcontextprotocol.io/specification/2025-06-18/server/tools/
pub const tools_call = "tools/call"

/// Notifies when the list of available resources changes.
/// https://modelcontextprotocol.io/specification/2025-06-18/server/resources#list-changed-notification
pub const notification_resources_list_changed = "notifications/resources/list_changed"

pub const notification_resource_updated = "notifications/resources/updated"

/// Notifies when the list of available prompt templates changes.
/// https://modelcontextprotocol.io/specification/2025-06-18/server/prompts#list-changed-notification
pub const notification_prompts_list_changed = "notifications/prompts/list_changed"

/// Notifies when the list of available tools changes.
/// https://modelcontextprotocol.io/specification/2025-06-18/server/tools/list_changed/
pub const notification_tools_list_changed = "notifications/tools/list_changed"

/// Notifies that a previously-issued request is cancelled.
pub const notification_cancelled = "notifications/cancelled"

pub const completion_complete = "completion/complete"
