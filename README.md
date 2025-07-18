# MCP Toolkit Gleam

Production-ready Model Context Protocol (MCP) Toolkit implementation in Gleam with comprehensive transport support, bidirectional communication, and enterprise-grade features.

## 🎯 Features

### Multi-Transport Support
- **stdio**: Dependency-free standard input/output transport
- **WebSocket**: Real-time bidirectional communication on `ws://localhost:8080/mcp`
- **Server-Sent Events (SSE)**: Server-to-client streaming on `http://localhost:8081/mcp`
- **Transport Bridging**: Connect any two transports with filtering and transformation

### Production-Ready Architecture
- **Latest MCP Specification**: Implements MCP 2025-06-18 with backward compatibility
- **Comprehensive Testing**: Full test coverage with birdie snapshots and gleunit
- **Type Safety**: Strong typing throughout with comprehensive error handling
- **Modular Design**: Clean separation between core protocol and transport layers
- **Optional Dependencies**: Core functionality works without external dependencies

### Enterprise Features
- Bidirectional communication with server-initiated requests
- Resource/tool/prompt change notifications
- Request/response correlation with unique IDs
- Client capability tracking and message routing
- Comprehensive logging and error reporting

## 🚀 Quick Start

### Installation

#### For Stdio Transport Only (Dependency-Free)
```bash
# Comment out mist dependency in gleam.toml for minimal installation
gleam build
gleam run -- mcpstdio
```

#### For Full Transport Support
```bash
# Includes WebSocket and SSE transports
gleam deps download
gleam build
gleam run -- mcpserver [transport]
```

### Usage Examples

```bash
# Stdio transport (no external dependencies)
gleam run -- mcpstdio

# WebSocket server
gleam run -- mcpserver websocket

# Server-Sent Events
gleam run -- mcpserver sse

# Transport bridging
gleam run -- mcpserver bridge

# Full server with all transports
gleam run -- mcpserver full
```

## 📁 Project Structure

```
src/
├── mcpstdio.gleam              # Stdio-only executable (dependency-free)
├── mcpserver.gleam             # Full server executable
└── mcp_toolkit_gleam/
    ├── core/                   # Core protocol implementation
    │   ├── protocol.gleam      # MCP protocol types and functions
    │   ├── server.gleam        # Server implementation
    │   ├── method.gleam        # MCP method constants
    │   └── json_schema*.gleam  # JSON schema handling
    ├── transport/              # Core transports (no external deps)
    │   └── stdio.gleam         # Standard I/O transport
    └── transport_optional/     # Optional transports (require mist)
        ├── websocket.gleam     # WebSocket transport
        ├── sse.gleam          # Server-Sent Events transport
        ├── bidirectional.gleam # Bidirectional communication
        └── bridge.gleam        # Transport bridging

test/
├── mcp_toolkit_gleam/
│   ├── core/                   # Core functionality tests
│   ├── transport/              # Transport layer tests
│   ├── transport_optional/     # Optional transport tests
│   └── integration/           # End-to-end integration tests
└── birdie_snapshots/          # Snapshot test data
```

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   MCP Client    │◄──►│  Transport Layer │◄──►│   MCP Server    │
│                 │    │                  │    │                 │
│  • Claude       │    │  • stdio         │    │  • Resources    │
│  • VS Code      │    │  • WebSocket     │    │  • Tools        │
│  • Custom App   │    │  • SSE           │    │  • Prompts      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                       ┌──────▼──────┐
                       │   Bridge    │
                       │             │
                       │ • Filter    │
                       │ • Transform │
                       │ • Route     │
                       └─────────────┘
```

## 🧪 Testing

The project includes comprehensive testing with 100% coverage:

```bash
# Run all tests
gleam test

# Run specific test modules
gleam test --module mcp_toolkit_gleam/core/protocol_test
gleam test --module mcp_toolkit_gleam/integration/full_test

# Generate test coverage report
gleam test --coverage
```

### Test Categories
- **Unit Tests**: Individual component testing with gleunit
- **Snapshot Tests**: JSON serialization testing with birdie
- **Integration Tests**: End-to-end functionality testing
- **Transport Tests**: Protocol compliance and error handling

## 📋 MCP Protocol Compliance

### Supported MCP Versions
- **2025-06-18** (Latest specification)
- **2025-03-26** (Backward compatible)
- **2024-11-05** (Backward compatible)

### Implemented Features
- ✅ Resource management with subscriptions
- ✅ Tool execution with error handling
- ✅ Prompt templates with parameters
- ✅ Bidirectional communication
- ✅ Server-initiated notifications
- ✅ Client capability negotiation
- ✅ Comprehensive logging support
- ✅ Progress tracking

## 🔧 Dependencies

### Core Dependencies (Required)
```toml
gleam_stdlib = ">= 0.44.0 and < 2.0.0"
gleam_http = ">= 4.0.0 and < 5.0.0"
gleam_json = ">= 2.3.0 and < 3.0.0"
jsonrpc = ">= 1.0.0 and < 2.0.0"
justin = ">= 1.0.1 and < 2.0.0"
gleam_erlang = ">= 0.34.0 and < 1.0.0"
```

### Optional Dependencies
```toml
# Only needed for WebSocket/SSE transports
mist = ">= 3.0.0 and < 4.0.0"
```

### Development Dependencies
```toml
gleeunit = ">= 1.0.0 and < 2.0.0"
birdie = ">= 1.2.7 and < 2.0.0"
argv = ">= 1.0.2 and < 2.0.0"
simplifile = ">= 2.2.1 and < 3.0.0"
```

## 🚦 Production Deployment

### Docker Deployment
```dockerfile
FROM gleam:latest
WORKDIR /app
COPY . .
RUN gleam deps download
RUN gleam build
EXPOSE 8080 8081
CMD ["gleam", "run", "--", "mcpserver", "full"]
```

### Environment Configuration
```bash
# Configure logging
export MCP_LOG_LEVEL=info
export MCP_LOG_FORMAT=json

# Configure transports
export MCP_WEBSOCKET_PORT=8080
export MCP_SSE_PORT=8081

# Configure security
export MCP_CORS_ENABLED=true
export MCP_AUTH_ENABLED=false
```

### Health Checks
The server provides health check endpoints:
- `GET /health` - Basic health status
- `GET /metrics` - Performance metrics
- `GET /version` - Protocol and server version

## 🔒 Security

### Security Features
- Input validation on all protocol messages
- JSON schema validation for tool parameters
- Request size limits and rate limiting
- CORS support for web clients
- Comprehensive error handling without information leakage

### Security Best Practices
- Run with minimal privileges
- Use TLS for production WebSocket/SSE transports
- Implement authentication for sensitive resources
- Monitor and log all protocol interactions

## 🤝 Contributing

### Development Setup
```bash
git clone https://github.com/mikkihugo/mcp-gleam.git
cd mcp-gleam
gleam deps download
gleam test
```

### Code Quality
- All code must pass `gleam format`
- 100% test coverage required
- Comprehensive documentation for public APIs
- Security review for transport implementations

## 📄 License

Apache-2.0 License. See [LICENSE](LICENSE) for details.

## 🔗 Links

- [Model Context Protocol Specification](https://modelcontextprotocol.io/specification/2025-06-18/)
- [Gleam Language](https://gleam.run/)
- [MCP SDK Documentation](https://github.com/modelcontextprotocol)

---

**MCP Toolkit Gleam** - Enterprise-grade Model Context Protocol implementation for production systems.