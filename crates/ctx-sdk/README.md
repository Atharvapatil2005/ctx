# ctx-sdk for Rust

Experimental in-repo Rust SDK for the ctx `agent-history-v1` contract.

This crate is not published to crates.io. Its API may change while the SDK
contract is being shaped in-repo.

## Use

```rust
use ctx_sdk::{LocalBackendConfig, MemoryClient, SearchOptions, SearchRefresh};

let client = MemoryClient::local(LocalBackendConfig::default());
let status = client.status()?;
let results = client.search(SearchOptions {
    query: Some("release notes".to_owned()),
    refresh: SearchRefresh::Off,
    ..SearchOptions::default()
})?;
# Ok::<(), ctx_sdk::MemoryError>(())
```

## Backends

- Local backend: shells out to `ctx` JSON commands and never performs network
  calls or provider API calls.
- Hosted backend: accepted for future compatibility but currently returns a
  structured `not_supported` error.

## Public Operations

`status`, `init`, `sources`, `import_memory`, `sync`, `search`, `show_event`,
`show_session`, `locate_event`, and `locate_session`.

The SDK returns `MemoryEnvelope` values from `ctx-protocol` with stable
`agent-history-v1` fields. CLI JSON remains an adapter detail.
