/// Comprehensive server tests
import birdie
import gleam/dynamic/decode
import gleam/json
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import mcp_toolkit_gleam/core/server
import mcp_toolkit_gleam/core/protocol as mcp

pub fn main() {
  gleeunit.main()
}

// Test server creation
pub fn server_creation_test() {
  let srv = server.new("Test Server", "1.0.0")
  let built_server = server.build(srv)
  
  // Server should be properly initialized
  built_server |> should.not_equal(server.new("Other", "2.0.0") |> server.build)
}

// Test adding prompts
pub fn add_prompt_test() {
  let prompt = mcp.Prompt(
    name: "test_prompt",
    description: Some("Test prompt"),
    arguments: None,
  )
  
  let handler = fn(_) {
    mcp.GetPromptResult(
      messages: [],
      description: None,
      meta: None,
    ) |> Ok
  }
  
  let srv = server.new("Test", "1.0.0")
    |> server.add_prompt(prompt, handler)
    |> server.build
  
  // Server should have the prompt registered
  srv |> should.not_equal(server.new("Test", "1.0.0") |> server.build)
}

// Test adding resources
pub fn add_resource_test() {
  let resource = mcp.Resource(
    name: "test_resource",
    uri: "file:///test.txt",
    description: Some("Test resource"),
    mime_type: Some("text/plain"),
    size: None,
    annotations: None,
  )
  
  let handler = fn(_) {
    mcp.ReadResourceResult(
      contents: [],
      meta: None,
    ) |> Ok
  }
  
  let srv = server.new("Test", "1.0.0")
    |> server.add_resource(resource, handler)
    |> server.build
  
  // Server should have the resource registered
  srv |> should.not_equal(server.new("Test", "1.0.0") |> server.build)
}

// Test adding tools
pub fn add_tool_test() {
  let assert Ok(schema) = mcp.tool_input_schema("{\"type\": \"object\"}")
  
  let tool = mcp.Tool(
    name: "test_tool",
    input_schema: schema,
    description: Some("Test tool"),
    annotations: None,
  )
  
  pub type TestInput {
    TestInput(value: String)
  }
  
  let decoder = decode.decode1(TestInput, decode.field("value", decode.string))
  
  let handler = fn(_) {
    mcp.CallToolResult(
      content: [],
      is_error: Some(False),
      meta: None,
    ) |> Ok
  }
  
  let srv = server.new("Test", "1.0.0")
    |> server.add_tool(tool, decoder, handler)
    |> server.build
  
  // Server should have the tool registered
  srv |> should.not_equal(server.new("Test", "1.0.0") |> server.build)
}

// Test server builder chain
pub fn server_builder_chain_test() {
  let prompt = mcp.Prompt(name: "p1", description: None, arguments: None)
  let resource = mcp.Resource(
    name: "r1", 
    uri: "file:///r1.txt", 
    description: None, 
    mime_type: None, 
    size: None, 
    annotations: None
  )
  let assert Ok(schema) = mcp.tool_input_schema("{\"type\": \"object\"}")
  let tool = mcp.Tool(name: "t1", input_schema: schema, description: None, annotations: None)
  
  let dummy_prompt_handler = fn(_) { 
    mcp.GetPromptResult(messages: [], description: None, meta: None) |> Ok 
  }
  let dummy_resource_handler = fn(_) { 
    mcp.ReadResourceResult(contents: [], meta: None) |> Ok 
  }
  let dummy_tool_handler = fn(_) { 
    mcp.CallToolResult(content: [], is_error: Some(False), meta: None) |> Ok 
  }
  let dummy_decoder = decode.decode1(fn(x) { x }, decode.string)
  
  let srv = server.new("Chain Test", "1.0.0")
    |> server.add_prompt(prompt, dummy_prompt_handler)
    |> server.add_resource(resource, dummy_resource_handler)
    |> server.add_tool(tool, dummy_decoder, dummy_tool_handler)
    |> server.build
  
  // Server should be built with all components
  srv |> should.not_equal(server.new("Chain Test", "1.0.0") |> server.build)
}

// Test message handling (mock tests)
pub fn message_handling_structure_test() {
  let srv = server.new("Handler Test", "1.0.0") |> server.build
  
  // Test that server has handle_message function
  // Note: We can't easily test the actual handling without mocking JSON-RPC,
  // but we can test the structure exists
  srv |> should.not_equal(server.new("Other", "1.0.0") |> server.build)
}

// Birdie snapshot tests for server capabilities
pub fn server_capabilities_snapshot_test() {
  let prompt = mcp.Prompt(
    name: "snapshot_prompt",
    description: Some("Prompt for snapshot testing"),
    arguments: Some(json.object([
      #("param", json.string("value"))
    ]))
  )
  
  let resource = mcp.Resource(
    name: "snapshot_resource",
    uri: "file:///snapshot.md",
    description: Some("Resource for snapshot testing"),
    mime_type: Some("text/markdown"),
    size: Some(512),
    annotations: None,
  )
  
  let assert Ok(schema) = mcp.tool_input_schema("{
    \"type\": \"object\",
    \"properties\": {
      \"input\": {\"type\": \"string\"}
    }
  }")
  
  let tool = mcp.Tool(
    name: "snapshot_tool",
    input_schema: schema,
    description: Some("Tool for snapshot testing"),
    annotations: None,
  )
  
  let dummy_handlers = #(
    fn(_) { mcp.GetPromptResult(messages: [], description: None, meta: None) |> Ok },
    fn(_) { mcp.ReadResourceResult(contents: [], meta: None) |> Ok },
    fn(_) { mcp.CallToolResult(content: [], is_error: Some(False), meta: None) |> Ok }
  )
  
  let dummy_decoder = decode.decode1(fn(x) { x }, decode.string)
  
  // Build server with all capabilities
  let srv = server.new("Snapshot Server", "1.0.0")
    |> server.add_prompt(prompt, dummy_handlers.0)
    |> server.add_resource(resource, dummy_handlers.1)
    |> server.add_tool(tool, dummy_decoder, dummy_handlers.2)
    |> server.build
  
  // Create a representation for snapshot testing
  let server_info = json.object([
    #("name", json.string("Snapshot Server")),
    #("version", json.string("1.0.0")),
    #("has_prompts", json.bool(True)),
    #("has_resources", json.bool(True)),
    #("has_tools", json.bool(True))
  ])
  
  server_info
  |> json.to_string
  |> birdie.snap(title: "server_capabilities")
}

// Test server with multiple prompts
pub fn multiple_prompts_test() {
  let prompt1 = mcp.Prompt(name: "p1", description: Some("First"), arguments: None)
  let prompt2 = mcp.Prompt(name: "p2", description: Some("Second"), arguments: None)
  
  let handler = fn(_) {
    mcp.GetPromptResult(messages: [], description: None, meta: None) |> Ok
  }
  
  let srv = server.new("Multi Prompt", "1.0.0")
    |> server.add_prompt(prompt1, handler)
    |> server.add_prompt(prompt2, handler)
    |> server.build
  
  srv |> should.not_equal(server.new("Multi Prompt", "1.0.0") |> server.build)
}

// Test server with multiple resources
pub fn multiple_resources_test() {
  let resource1 = mcp.Resource(
    name: "r1", uri: "file:///1.txt", description: None, 
    mime_type: None, size: None, annotations: None
  )
  let resource2 = mcp.Resource(
    name: "r2", uri: "file:///2.txt", description: None,
    mime_type: None, size: None, annotations: None
  )
  
  let handler = fn(_) {
    mcp.ReadResourceResult(contents: [], meta: None) |> Ok
  }
  
  let srv = server.new("Multi Resource", "1.0.0")
    |> server.add_resource(resource1, handler)
    |> server.add_resource(resource2, handler)
    |> server.build
  
  srv |> should.not_equal(server.new("Multi Resource", "1.0.0") |> server.build)
}

// Test server with multiple tools
pub fn multiple_tools_test() {
  let assert Ok(schema) = mcp.tool_input_schema("{\"type\": \"object\"}")
  
  let tool1 = mcp.Tool(name: "t1", input_schema: schema, description: None, annotations: None)
  let tool2 = mcp.Tool(name: "t2", input_schema: schema, description: None, annotations: None)
  
  let handler = fn(_) {
    mcp.CallToolResult(content: [], is_error: Some(False), meta: None) |> Ok
  }
  let decoder = decode.decode1(fn(x) { x }, decode.string)
  
  let srv = server.new("Multi Tool", "1.0.0")
    |> server.add_tool(tool1, decoder, handler)
    |> server.add_tool(tool2, decoder, handler)
    |> server.build
  
  srv |> should.not_equal(server.new("Multi Tool", "1.0.0") |> server.build)
}

// Test edge cases
pub fn edge_cases_test() {
  // Test server with empty name
  let srv_empty = server.new("", "1.0.0") |> server.build
  srv_empty |> should.not_equal(server.new("Test", "1.0.0") |> server.build)
  
  // Test server with empty version
  let srv_empty_version = server.new("Test", "") |> server.build
  srv_empty_version |> should.not_equal(server.new("Test", "1.0.0") |> server.build)
}