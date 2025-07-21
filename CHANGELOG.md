# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] 

### Fixed
- Fixed compilation errors in mcpserver.gleam by disabling optional transport modules
- Updated deprecated dynamic function calls to use gleam/dynamic/decode module
- Fixed type mismatches in prompt argument definitions
- Corrected repository references in documentation from "mcp-gleam" to "mcp_toolkit_gleam"
- Renamed test file from gleamcp_test.gleam to mcp_toolkit_gleam_test.gleam for consistency
- Removed unused imports to clean up warnings

### Changed  
- Disabled WebSocket, SSE, and bridge transport functionality (modules exist but are disabled)
- Optional HTTP transport dependencies (mist, wisp) are commented out in gleam.toml
- mcpserver now only supports stdio transport until optional dependencies are enabled
- Improved code organization and naming consistency

### Current Status
- **Functional Features**:
  - stdio transport with MCP protocol support
  - Core server functionality with resources, tools, and prompts
  - Comprehensive type definitions for MCP protocol
  - JSON schema validation support
- **Disabled Features**:
  - WebSocket transport (requires mist dependency)
  - Server-Sent Events transport (requires mist dependency)
  - Transport bridging functionality
  - Bidirectional communication

## [1.0.0] - Initial Release

### Added
- Initial MCP Toolkit implementation in Gleam
- Core MCP protocol support (stdio transport)
- Modular architecture with separation between core and transport layers
- Basic server builder with resource, tool, and prompt support
- JSON schema validation
- Comprehensive test suite with birdie snapshots
- Documentation and examples

### Note on Transport Features
The codebase includes infrastructure for WebSocket and SSE transports, but these are currently disabled pending resolution of dependency management. To enable these features, uncomment the `mist` and `wisp` dependencies in `gleam.toml` and rename the `.disabled` files in `src/mcp_toolkit_gleam/transport_optional/`.

## Support

For questions, issues, or contributions:
- GitHub Issues: [https://github.com/mikkihugo/mcp_toolkit_gleam/issues](https://github.com/mikkihugo/mcp_toolkit_gleam/issues)
- MCP Specification: [https://modelcontextprotocol.io/](https://modelcontextprotocol.io/)
- Gleam Language: [https://gleam.run/](https://gleam.run/)