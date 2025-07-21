/// Tests for method constants
import gleam/list
import gleeunit
import gleeunit/should
import mcp_toolkit_gleam/core/method

pub fn main() {
  gleeunit.main()
}

// Test core protocol methods
pub fn core_methods_test() {
  method.initialize |> should.equal("initialize")
  method.ping |> should.equal("ping")
}

// Test resource methods
pub fn resource_methods_test() {
  method.resources_list |> should.equal("resources/list")
  method.resources_templates_list |> should.equal("resources/templates/list")
  method.resources_read |> should.equal("resources/read")
}

// Test prompt methods
pub fn prompt_methods_test() {
  method.prompts_list |> should.equal("prompts/list")
  method.prompts_get |> should.equal("prompts/get")
}

// Test tool methods
pub fn tool_methods_test() {
  method.tools_list |> should.equal("tools/list")
  method.tools_call |> should.equal("tools/call")
}

// Test notification methods
pub fn notification_methods_test() {
  method.notification_resources_list_changed |> should.equal("notifications/resources/list_changed")
  method.notification_resource_updated |> should.equal("notifications/resources/updated")
  method.notification_prompts_list_changed |> should.equal("notifications/prompts/list_changed")
  method.notification_tools_list_changed |> should.equal("notifications/tools/list_changed")
  method.notification_cancelled |> should.equal("notifications/cancelled")
}

// Test completion method
pub fn completion_methods_test() {
  method.completion_complete |> should.equal("completion/complete")
}

// Test method constants are strings
pub fn method_constants_are_strings_test() {
  // Test method constants are all defined
  should.equal(list.length([
    method.initialize,
    method.ping,
    method.resources_list,
    method.resources_templates_list,
    method.resources_read,
    method.prompts_list,
    method.prompts_get,
    method.tools_list,
    method.tools_call,
    method.notification_resources_list_changed,
    method.notification_resource_updated,
    method.notification_prompts_list_changed,
    method.notification_tools_list_changed,
    method.notification_cancelled,
    method.completion_complete,
  ]), 15)
}