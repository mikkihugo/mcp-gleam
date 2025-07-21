/// Comprehensive protocol tests using gleunit and birdie
import birdie
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import mcp_toolkit_gleam/core/protocol as mcp

pub fn main() {
  gleeunit.main()
}

// Test protocol version
pub fn protocol_version_test() {
  mcp.protocol_version
  |> should.equal("2025-06-18")
}

// Test error types
pub fn mcp_error_test() {
  let parse_error = mcp.ParseError
  let invalid_request = mcp.InvalidRequest
  let method_not_found = mcp.MethodNotFound
  let invalid_params = mcp.InvalidParams
  let internal_error = mcp.InternalError
  let app_error = mcp.ApplicationError("test error")
  
  // Test that all error types are properly constructed
  parse_error |> should.not_equal(invalid_request)
  app_error |> should.not_equal(internal_error)
}

// Test content types
pub fn content_types_test() {
  let text_content = mcp.TextContent(
    type_: "text",
    text: "Hello, world!",
    annotations: None,
  )
  
  let image_content = mcp.ImageContent(
    type_: "image",
    data: "base64data",
    mime_type: "image/png",
    annotations: None,
  )
  
  text_content.text |> should.equal("Hello, world!")
  image_content.mime_type |> should.equal("image/png")
}

// Test tool schema creation
pub fn tool_schema_test() {
  let schema_json = "{
    \"type\": \"object\",
    \"properties\": {
      \"name\": {
        \"type\": \"string\"
      }
    }
  }"
  
  case mcp.tool_input_schema(schema_json) {
    Ok(_schema) -> {
      // Schema should be valid - just test that it succeeded
      should.equal(True, True)
    }
    Error(_) -> should.fail()
  }
}

// Test prompt creation
pub fn prompt_creation_test() {
  let prompt = mcp.Prompt(
    name: "test_prompt",
    description: Some("A test prompt"),
    arguments: Some([
      mcp.PromptArgument(
        name: "param1",
        description: Some("Parameter 1"),
        required: Some(True),
      ),
    ])
  )
  
  prompt.name |> should.equal("test_prompt")
  prompt.description |> should.equal(Some("A test prompt"))
}

// Test resource creation
pub fn resource_creation_test() {
  let resource = mcp.Resource(
    name: "test_resource",
    uri: "file:///test.txt",
    description: Some("A test resource"),
    mime_type: Some("text/plain"),
    size: Some(100),
    annotations: None,
  )
  
  resource.name |> should.equal("test_resource")
  resource.uri |> should.equal("file:///test.txt")
  resource.mime_type |> should.equal(Some("text/plain"))
  resource.size |> should.equal(Some(100))
}

// Test tool creation
pub fn tool_creation_test() {
  let assert Ok(schema) = mcp.tool_input_schema("{\"type\": \"object\"}")
  
  let tool = mcp.Tool(
    name: "test_tool",
    input_schema: schema,
    description: Some("A test tool"),
    annotations: None,
  )
  
  tool.name |> should.equal("test_tool")
  tool.description |> should.equal(Some("A test tool"))
}

// Test role types
pub fn role_types_test() {
  let user_role = mcp.User
  let assistant_role = mcp.Assistant
  
  user_role |> should.not_equal(assistant_role)
}

// Test message structures
pub fn message_structures_test() {
  let text_content = mcp.TextContent(
    type_: "text",
    text: "Test message",
    annotations: None,
  )
  
  let prompt_message = mcp.PromptMessage(
    role: mcp.User,
    content: mcp.TextPromptContent(text_content),
  )
  
  prompt_message.role |> should.equal(mcp.User)
}

// Test initialization structures
pub fn initialization_test() {
  let client_info = mcp.Implementation(
    name: "test_client",
    version: "1.0.0",
  )
  
  let server_capabilities = mcp.ServerCapabilities(
    completions: None,
    logging: None,
    prompts: Some(mcp.ServerCapabilitiesPrompts(list_changed: Some(True))),
    resources: Some(mcp.ServerCapabilitiesResources(
      subscribe: Some(True),
      list_changed: Some(True),
    )),
    tools: Some(mcp.ServerCapabilitiesTools(list_changed: Some(True))),
  )
  
  client_info.name |> should.equal("test_client")
  client_info.version |> should.equal("1.0.0")
}

// Birdie snapshot tests for JSON serialization
pub fn json_serialization_snapshot_test() {
  let prompt = mcp.Prompt(
    name: "code_review",
    description: Some("Generate a code review"),
    arguments: Some([
      mcp.PromptArgument(
        name: "language",
        description: Some("Programming language"),
        required: Some(True),
      ),
      mcp.PromptArgument(
        name: "focus",
        description: Some("Review focus area"),
        required: Some(False),
      ),
    ])
  )
  
  // This will create a snapshot for comparison
  prompt
  |> mcp.prompt_to_json
  |> json.to_string
  |> birdie.snap(title: "prompt_json_serialization")
}

pub fn resource_json_snapshot_test() {
  let resource = mcp.Resource(
    name: "project_docs",
    uri: "file:///docs/README.md",
    description: Some("Project documentation"),
    mime_type: Some("text/markdown"),
    size: Some(1024),
    annotations: Some(mcp.Annotations(
      audience: Some([mcp.User]),
      priority: Some(0.8),
    )),
  )
  
  resource
  |> mcp.resource_to_json
  |> json.to_string
  |> birdie.snap(title: "resource_json_serialization")
}

pub fn tool_json_snapshot_test() {
  let assert Ok(schema) = mcp.tool_input_schema("{
    \"type\": \"object\",
    \"properties\": {
      \"query\": {
        \"type\": \"string\",
        \"description\": \"Search query\"
      }
    },
    \"required\": [\"query\"]
  }")
  
  let tool = mcp.Tool(
    name: "search",
    input_schema: schema,
    description: Some("Search for information"),
    annotations: Some(mcp.ToolAnnotations(
      destructive_hint: Some(False),
      idempotent_hint: Some(True),
      open_world_hint: Some(False),
      read_only_hint: Some(True),
      title: Some("Search Tool"),
    )),
  )
  
  tool
  |> mcp.tool_to_json
  |> json.to_string
  |> birdie.snap(title: "tool_json_serialization")
}

// Test complex nested structures
pub fn complex_structures_test() {
  let get_prompt_result = mcp.GetPromptResult(
    messages: [
      mcp.PromptMessage(
        role: mcp.User,
        content: mcp.TextPromptContent(mcp.TextContent(
          type_: "text",
          text: "Complex prompt message",
          annotations: Some(mcp.Annotations(
            audience: Some([mcp.User]),
            priority: Some(0.9),
          )),
        )),
      ),
    ],
    description: Some("Complex prompt result"),
    meta: Some(mcp.Meta(progress_token: Some(mcp.ProgressTokenString("test-token")))),
  )
  
  get_prompt_result.messages
  |> list.length
  |> should.equal(1)
  
  get_prompt_result.description
  |> should.equal(Some("Complex prompt result"))
}

// Test error handling and edge cases
pub fn error_handling_test() {
  // Test invalid JSON schema
  case mcp.tool_input_schema("invalid json") {
    Error(_) -> should.be_true(True)
    Ok(_) -> should.fail()
  }
  
  // Test minimal valid schema
  case mcp.tool_input_schema("{\"type\": \"object\"}") {
    Ok(_) -> should.be_true(True)
    Error(_) -> should.fail()
  }
}

// Test boundary conditions
pub fn boundary_conditions_test() {
  // Test empty string content
  let empty_content = mcp.TextContent(
    type_: "text",
    text: "",
    annotations: None,
  )
  
  empty_content.text |> should.equal("")
  
  // Test very long content
  let long_text = string.repeat("a", 10000)
  let long_content = mcp.TextContent(
    type_: "text",
    text: long_text,
    annotations: None,
  )
  
  long_content.text 
  |> string.length 
  |> should.equal(10000)
}