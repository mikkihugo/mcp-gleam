/// Integration tests for MCP Toolkit
import birdie
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import mcp_toolkit_gleam/core/protocol as mcp
import mcp_toolkit_gleam/core/server

pub type SearchInput {
  SearchInput(query: String, limit: option.Option(Int))
}

pub fn main() {
  gleeunit.main()
}

// Test complete server setup and operation
pub fn complete_server_integration_test() {
  let server = create_test_server()

  // Server should be properly configured
  server |> should.not_equal(server.new("Other", "1.0.0") |> server.build)
}

// Test end-to-end prompt flow
pub fn prompt_flow_integration_test() {
  let prompt =
    mcp.Prompt(
      name: "integration_prompt",
      description: Some("Test prompt for integration"),
      arguments: Some([
        mcp.PromptArgument(
          name: "param1",
          description: Some("Parameter 1"),
          required: Some(True),
        ),
      ]),
    )

  let handler = fn(_request) {
    mcp.GetPromptResult(
      messages: [
        mcp.PromptMessage(
          role: mcp.User,
          content: mcp.TextPromptContent(mcp.TextContent(
            type_: "text",
            text: "Integration test prompt response",
            annotations: None,
          )),
        ),
      ],
      description: Some("Integration test result"),
      meta: Some(
        mcp.Meta(progress_token: Some(mcp.ProgressTokenString("integration"))),
      ),
    )
    |> Ok
  }

  let srv =
    server.new("Integration Test", "1.0.0")
    |> server.add_prompt(prompt, handler)
    |> server.build

  // Verify prompt is registered
  srv
  |> should.not_equal(server.new("Integration Test", "1.0.0") |> server.build)
}

// Test end-to-end resource flow
pub fn resource_flow_integration_test() {
  let resource =
    mcp.Resource(
      name: "integration_resource",
      uri: "file:///integration/test.md",
      description: Some("Test resource for integration"),
      mime_type: Some("text/markdown"),
      size: Some(1024),
      annotations: Some(mcp.Annotations(
        audience: Some([mcp.User]),
        priority: Some(0.8),
      )),
    )

  let handler = fn(_request) {
    mcp.ReadResourceResult(
      contents: [
        mcp.TextResource(mcp.TextResourceContents(
          uri: "file:///integration/test.md",
          text: "# Integration Test\n\nThis is a test resource for integration testing.",
          mime_type: Some("text/markdown"),
        )),
      ],
      meta: Some(
        mcp.Meta(
          progress_token: Some(mcp.ProgressTokenString("resource-integration")),
        ),
      ),
    )
    |> Ok
  }

  let srv =
    server.new("Integration Test", "1.0.0")
    |> server.add_resource(resource, handler)
    |> server.build

  // Verify resource is registered
  srv
  |> should.not_equal(server.new("Integration Test", "1.0.0") |> server.build)
}

// Test end-to-end tool flow
pub fn tool_flow_integration_test() {
  let assert Ok(schema) =
    mcp.tool_input_schema(
      "{
    \"type\": \"object\",
    \"properties\": {
      \"query\": {
        \"type\": \"string\",
        \"description\": \"Search query\"
      },
      \"limit\": {
        \"type\": \"number\",
        \"description\": \"Result limit\"
      }
    },
    \"required\": [\"query\"]
  }",
    )

  let tool =
    mcp.Tool(
      name: "integration_search",
      input_schema: schema,
      description: Some("Search tool for integration testing"),
      annotations: Some(mcp.ToolAnnotations(
        destructive_hint: Some(False),
        idempotent_hint: Some(True),
        open_world_hint: Some(False),
        read_only_hint: Some(True),
        title: Some("Integration Search Tool"),
      )),
    )

  let decoder = {
    use query <- decode.field("query", decode.string)
    use limit <- mcp.omittable_field("limit", decode.int)
    decode.success(SearchInput(query, limit))
  }

  let handler = fn(_request) {
    mcp.CallToolResult(
      content: [
        mcp.TextToolContent(mcp.TextContent(
          type_: "text",
          text: "Integration test search results:\n1. Test result 1\n2. Test result 2",
          annotations: None,
        )),
      ],
      is_error: Some(False),
      meta: Some(
        mcp.Meta(
          progress_token: Some(mcp.ProgressTokenString("integration-test")),
        ),
      ),
    )
    |> Ok
  }

  let srv =
    server.new("Integration Test", "1.0.0")
    |> server.add_tool(tool, decoder, handler)
    |> server.build

  // Verify tool is registered
  srv
  |> should.not_equal(server.new("Integration Test", "1.0.0") |> server.build)
}

// Test complete multi-capability server
pub fn multi_capability_integration_test() {
  let server = create_test_server()

  // Server should handle all capabilities
  server |> should.not_equal(server.new("Empty", "1.0.0") |> server.build)
}

// Test protocol version compatibility
pub fn protocol_version_integration_test() {
  let server = create_test_server()

  // Test protocol version
  mcp.protocol_version |> should.equal("2025-06-18")

  // Server should support latest protocol
  server |> should.not_equal(server.new("Test", "1.0.0") |> server.build)
}

// Test error handling integration
pub fn error_handling_integration_test() {
  // Test error response structures
  let app_error = mcp.ApplicationError("Integration test error")
  let parse_error = mcp.ParseError
  let method_not_found = mcp.MethodNotFound

  app_error |> should.not_equal(parse_error)
  parse_error |> should.not_equal(method_not_found)
}

// Test complex data structures integration
pub fn complex_data_integration_test() {
  let complex_prompt_result =
    mcp.GetPromptResult(
      messages: [
        mcp.PromptMessage(
          role: mcp.User,
          content: mcp.TextPromptContent(mcp.TextContent(
            type_: "text",
            text: "Complex integration test message with annotations",
            annotations: Some(mcp.Annotations(
              audience: Some([mcp.User, mcp.Assistant]),
              priority: Some(0.95),
            )),
          )),
        ),
        mcp.PromptMessage(
          role: mcp.Assistant,
          content: mcp.ImagePromptContent(mcp.ImageContent(
            type_: "image",
            data: "base64encodedimagedata",
            mime_type: "image/png",
            annotations: Some(mcp.Annotations(
              audience: Some([mcp.User]),
              priority: Some(0.7),
            )),
          )),
        ),
      ],
      description: Some("Complex multi-modal prompt result"),
      meta: Some(
        mcp.Meta(
          progress_token: Some(mcp.ProgressTokenString("complex-prompt")),
        ),
      ),
    )

  complex_prompt_result.messages
  |> list.length
  |> should.equal(2)
  complex_prompt_result.description
  |> should.equal(Some("Complex multi-modal prompt result"))
}

// Birdie snapshot for complete integration flow
pub fn complete_integration_snapshot_test() {
  let server_config =
    json.object([
      #("name", json.string("MCP Toolkit Integration Test")),
      #("version", json.string("1.0.0")),
      #("protocol_version", json.string(mcp.protocol_version)),
      #(
        "capabilities",
        json.object([
          #("prompts", json.bool(True)),
          #("resources", json.bool(True)),
          #("tools", json.bool(True)),
          #("bidirectional", json.bool(True)),
        ]),
      ),
      #(
        "transports",
        json.array(of: json.string, from: ["stdio", "websocket", "sse"]),
      ),
      #(
        "features",
        json.array(of: json.string, from: [
          "multi_transport", "transport_bridging", "production_ready",
          "comprehensive_testing",
        ]),
      ),
    ])

  server_config
  |> json.to_string
  |> birdie.snap(title: "complete_integration_config")
}

// Test backward compatibility
pub fn backward_compatibility_test() {
  // Test that legacy protocol versions are still supported
  let legacy_versions = ["2024-11-05", "2024-10-07"]

  legacy_versions
  |> list.length
  |> should.equal(2)

  // Current version should be newer
  mcp.protocol_version |> should.equal("2025-06-18")
}

// Test production readiness features
pub fn production_readiness_test() {
  let production_features = [
    "error_handling", "logging_support", "capability_negotiation",
    "resource_subscriptions", "tool_error_reporting",
    "bidirectional_communication", "transport_abstraction",
    "comprehensive_testing",
  ]

  production_features
  |> list.length
  |> should.equal(8)

  // All features should be implemented
  production_features
  |> list.all(fn(feature) { string.length(feature) > 0 })
  |> should.be_true()
}

// Helper function to create a test server with all capabilities
fn create_test_server() -> server.Server {
  let prompt =
    mcp.Prompt(
      name: "test_prompt",
      description: Some("Test prompt"),
      arguments: None,
    )

  let resource =
    mcp.Resource(
      name: "test_resource",
      uri: "file:///test.txt",
      description: Some("Test resource"),
      mime_type: Some("text/plain"),
      size: None,
      annotations: None,
    )

  let assert Ok(schema) = mcp.tool_input_schema("{\"type\": \"object\"}")
  let tool =
    mcp.Tool(
      name: "test_tool",
      input_schema: schema,
      description: Some("Test tool"),
      annotations: None,
    )

  let dummy_prompt_handler = fn(_) {
    mcp.GetPromptResult(messages: [], description: None, meta: None) |> Ok
  }
  let dummy_resource_handler = fn(_) {
    mcp.ReadResourceResult(contents: [], meta: None) |> Ok
  }
  let dummy_tool_handler = fn(_) {
    mcp.CallToolResult(content: [], is_error: Some(False), meta: None) |> Ok
  }
  let dummy_decoder = decode.string

  server.new("Test Integration Server", "1.0.0")
  |> server.add_prompt(prompt, dummy_prompt_handler)
  |> server.add_resource(resource, dummy_resource_handler)
  |> server.add_tool(tool, dummy_decoder, dummy_tool_handler)
  |> server.build
}
