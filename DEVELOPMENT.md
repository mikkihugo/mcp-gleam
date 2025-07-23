# Development Environment Setup

This document explains how to set up a development environment for the MCP Toolkit Gleam project.

## Requirements

- **Gleam**: 1.11.1 (latest stable)
- **Erlang/OTP**: 27 (required for `gleam_json` v2.3.0+ compatibility)
- **Rebar3**: 3 (for Erlang build tools)

## Quick Start

### Using DevContainer (Recommended)

The project includes a preconfigured DevContainer that sets up the complete development environment:

1. Open the project in VS Code
2. When prompted, click "Reopen in Container" or use Command Palette → "Dev Containers: Reopen in Container"
3. The container will automatically:
   - Use Erlang/OTP 27 base image
   - Install Gleam 1.11.1
   - Download project dependencies
   - Configure VS Code with Gleam extension

### Manual Setup

If you prefer to set up the environment manually:

1. **Install Erlang/OTP 27**:
   ```bash
   # On Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install -y erlang

   # On macOS with Homebrew
   brew install erlang

   # Verify version
   erl -eval 'io:format("~s~n", [erlang:system_info(otp_release)]), halt().'
   ```

2. **Install Gleam 1.11.1**:
   ```bash
   # Download and install Gleam
   curl -L -o gleam.tar.gz "https://github.com/gleam-lang/gleam/releases/download/v1.11.1/gleam-v1.11.1-x86_64-unknown-linux-musl.tar.gz"
   tar -xzf gleam.tar.gz -C /usr/local/bin
   rm gleam.tar.gz

   # Verify installation
   gleam --version
   ```

3. **Install dependencies and run tests**:
   ```bash
   gleam deps download
   gleam test
   ```

## CI/CD Configuration

All GitHub Actions workflows are configured to use:
- `erlef/setup-beam@v1` action
- Erlang/OTP version 27
- Gleam version 1.11.1
- Rebar3 version 3

This ensures consistent environments across development, testing, and deployment.

## Troubleshooting

### "Insufficient Erlang/OTP version" Error

If you see errors like:
```
{erlang_otp_27_required,<<"Insufficient Erlang/OTP version.\n\n`gleam_json` uses the Erlang `json` module introduced in Erlang/OTP 27.\nYou are using Erlang/OTP 25">>}
```

**Solution**: Ensure you're using Erlang/OTP 27 or higher. The current `gleam_json` dependency (v2.3.0+) requires OTP 27.

### Build Failures

If you encounter build failures:

1. Verify Gleam version: `gleam --version` should show `gleam 1.11.1`
2. Verify OTP version: `erl -eval 'io:format("~s~n", [erlang:system_info(otp_release)]), halt().'` should show `27`
3. Clean and rebuild: `rm -rf build && gleam deps download && gleam test`

### DevContainer Issues

If the DevContainer fails to build:
1. Ensure Docker is running
2. Try rebuilding the container: Command Palette → "Dev Containers: Rebuild Container"
3. Check the container logs for specific error messages

## Testing

Run the full test suite:
```bash
gleam test
```

The project includes 71 tests covering:
- Core MCP protocol functionality
- Transport layer functionality  
- JSON schema validation
- Integration tests
- Birdie snapshot tests

All tests should pass with the correct environment setup.