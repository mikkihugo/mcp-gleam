pub fn read_message() -> Result(String, Nil) {
  case read_line() {
    Error(_) -> Error(Nil)
    Ok("[") -> batch_loop("[")
    Ok(msg) -> Ok(msg)
  }
}

fn batch_loop(acc: String) {
  case read_line() {
    Ok("]") -> Ok(acc <> "]")
    Ok(line) -> batch_loop(acc <> line)
    Error(_) -> Error(Nil)
  }
}

@external(erlang, "mcp_ffi", "read_line")
@external(javascript, "../../mcp_ffi.mjs", "read_line")
fn read_line() -> Result(String, Nil)
