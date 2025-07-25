# GitHub Copilot Instructions for MCP Toolkit Gleam

## Project Overview
This is a production-ready Model Context Protocol (MCP) Toolkit implementation in Gleam, providing comprehensive server functionality with multi-transport support.

## Code Standards and Style Guidelines

### Naming Conventions
- Use `snake_case` for functions, variables, and module names (following Gleam conventions)
- Use `PascalCase` for types and constructors
- Use descriptive, clear names that explain purpose
- Prefer full words over abbreviations

### Code Organization
- Core protocol definitions in `src/mcp_toolkit_gleam/core/`
- Transport implementations in `src/mcp_toolkit_gleam/transport/`
- Optional transports requiring external deps in `src/mcp_toolkit_gleam/transport_optional/`
- Main executables as direct files in `src/`

### Best Practices
- Always include comprehensive error handling
- Use `Result` types for operations that can fail
- Write clear, descriptive comments for complex logic
- Follow functional programming patterns
- Keep functions small and focused
- Use pattern matching effectively

### Documentation Standards
- Document all public functions and types
- Include usage examples in documentation
- Explain complex algorithms or business logic
- Document error conditions and edge cases

### Testing Guidelines
- Write tests for all public APIs
- Include both positive and negative test cases
- Test error conditions and edge cases
- Use descriptive test names that explain what is being tested

## MCP Protocol Specifics
- Follow MCP specification 2025-06-18
- Implement proper JSON-RPC 2.0 messaging
- Support all required MCP methods
- Handle optional features gracefully
- Maintain backward compatibility when possible

## Dependencies and OTP Compatibility
- Target OTP 28 for all dependencies
- Keep dependencies minimal for core functionality
- Use optional dependencies for advanced features
- Regularly update to latest compatible versions

## When Making Suggestions
- Prioritize code clarity and maintainability
- Consider performance implications
- Ensure OTP 28 compatibility
- Follow Gleam idioms and conventions
- Suggest improvements for error handling
- Recommend testing strategies