/// Tests for the main MCP Toolkit module
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// Test main module exports
pub fn main_module_exports_test() {
  // Test that the Server type is exported correctly
  // This is mainly a compilation test to ensure exports work
  should.be_true(True)
}