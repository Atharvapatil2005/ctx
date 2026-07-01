//! Experimental in-repo Rust SDK for ctx memory.
//!
//! This SDK is intentionally not published. The local backend shells out to the
//! `ctx` CLI and adapts its private JSON into the public `memory-v1` envelope.

use std::{
    path::{Path, PathBuf},
    process::{Command, Stdio},
    thread,
    time::{Duration, Instant},
};

use ctx_protocol::{camel_alias_object, camelize_object_keys, JsonObject};
pub use ctx_protocol::{
    BackendInfo, BackendKind, EventResult, Freshness, ImportResult, LocationResult, MemoryEnvelope,
    MemoryErrorBody, MemoryErrorCode, MemoryEvent, MemoryOperation, MemoryStatus, ProviderSource,
    SearchHit, SearchResult, SessionResult, SourceLocation, Totals, CONTRACT_VERSION,
    SCHEMA_VERSION,
};
use serde::de::DeserializeOwned;
use serde_json::{json, Value};
use thiserror::Error;

#[derive(Debug, Error)]
#[error("{body:?}")]
pub struct MemoryError {
    pub body: MemoryErrorBody,
}

impl MemoryError {
    fn new(code: MemoryErrorCode, message: impl Into<String>, retryable: bool) -> Self {
        Self {
            body: MemoryErrorBody::new(code, message, retryable),
        }
    }

    fn with_cause(mut self, cause: impl Into<String>) -> Self {
        self.body.cause = Some(cause.into());
        self
    }
}

#[derive(Debug, Clone)]
pub enum MemoryBackend {
    Local(LocalBackendConfig),
    Hosted(HostedBackendConfig),
}

#[derive(Debug, Clone)]
pub struct LocalBackendConfig {
    pub ctx_binary: PathBuf,
    pub data_root: Option<PathBuf>,
    pub timeout: Duration,
}

impl Default for LocalBackendConfig {
    fn default() -> Self {
        Self {
            ctx_binary: PathBuf::from("ctx"),
            data_root: None,
            timeout: Duration::from_secs(30),
        }
    }
}

#[derive(Debug, Clone)]
pub struct HostedBackendConfig {
    pub base_url: String,
    pub timeout: Duration,
}

#[derive(Debug, Clone, Default)]
pub struct InitOptions {
    pub catalog_only: bool,
}

#[derive(Debug, Clone, Default)]
pub struct ImportOptions {
    pub provider: Option<String>,
    pub path: Option<PathBuf>,
    pub all: bool,
    pub resume: bool,
}

#[derive(Debug, Clone)]
pub struct SearchOptions {
    pub query: Option<String>,
    pub terms: Vec<String>,
    pub limit: usize,
    pub provider: Option<String>,
    pub workspace: Option<String>,
    pub since: Option<String>,
    pub file: Option<PathBuf>,
    pub session: Option<String>,
    pub events: bool,
    pub refresh: SearchRefresh,
    pub include_current_session: bool,
}

impl Default for SearchOptions {
    fn default() -> Self {
        Self {
            query: None,
            terms: Vec::new(),
            limit: 20,
            provider: None,
            workspace: None,
            since: None,
            file: None,
            session: None,
            events: false,
            refresh: SearchRefresh::Auto,
            include_current_session: false,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SearchRefresh {
    Auto,
    Off,
    Strict,
}

impl SearchRefresh {
    fn as_arg(self) -> &'static str {
        match self {
            Self::Auto => "auto",
            Self::Off => "off",
            Self::Strict => "strict",
        }
    }
}

#[derive(Debug, Clone, Default)]
pub struct ShowEventOptions {
    pub before: usize,
    pub after: usize,
    pub window: Option<usize>,
}

#[derive(Debug, Clone)]
pub struct ShowSessionOptions {
    pub mode: String,
}

impl Default for ShowSessionOptions {
    fn default() -> Self {
        Self {
            mode: "lite".to_owned(),
        }
    }
}

#[derive(Debug, Clone)]
pub struct MemoryClient {
    backend: MemoryBackend,
}

impl MemoryClient {
    pub fn local(config: LocalBackendConfig) -> Self {
        Self {
            backend: MemoryBackend::Local(config),
        }
    }

    pub fn hosted(config: HostedBackendConfig) -> Self {
        Self {
            backend: MemoryBackend::Hosted(config),
        }
    }

    pub fn backend_info(&self) -> BackendInfo {
        match &self.backend {
            MemoryBackend::Local(config) => BackendInfo::local(
                config
                    .data_root
                    .as_ref()
                    .map(|path| path.to_string_lossy().into_owned()),
            ),
            MemoryBackend::Hosted(config) => BackendInfo::hosted(Some(config.base_url.clone())),
        }
    }

    pub fn status(&self) -> Result<MemoryEnvelope, MemoryError> {
        self.local_json(MemoryOperation::Status, &["status", "--json"])
    }

    pub fn init(&self, options: InitOptions) -> Result<MemoryEnvelope, MemoryError> {
        let mut args = vec!["setup", "--json", "--progress", "none"];
        if options.catalog_only {
            args.push("--catalog-only");
        }
        self.local_json(MemoryOperation::Init, &args)
    }

    pub fn sources(&self) -> Result<MemoryEnvelope, MemoryError> {
        self.local_json(MemoryOperation::Sources, &["sources", "--json"])
    }

    pub fn import_memory(&self, options: ImportOptions) -> Result<MemoryEnvelope, MemoryError> {
        self.import_or_sync(MemoryOperation::Import, options)
    }

    pub fn sync(&self, options: ImportOptions) -> Result<MemoryEnvelope, MemoryError> {
        self.import_or_sync(MemoryOperation::Sync, options)
    }

    pub fn search(&self, options: SearchOptions) -> Result<MemoryEnvelope, MemoryError> {
        let mut owned = Vec::<String>::new();
        owned.push("search".to_owned());
        if let Some(query) = options.query {
            owned.push(query);
        }
        for term in options.terms {
            owned.push("--term".to_owned());
            owned.push(term);
        }
        owned.extend(["--limit".to_owned(), options.limit.to_string()]);
        push_opt(&mut owned, "--provider", options.provider);
        push_opt(&mut owned, "--workspace", options.workspace);
        push_opt(&mut owned, "--since", options.since);
        if let Some(file) = options.file {
            push_opt(
                &mut owned,
                "--file",
                Some(file.to_string_lossy().into_owned()),
            );
        }
        push_opt(&mut owned, "--session", options.session);
        if options.events {
            owned.push("--events".to_owned());
        }
        owned.extend(["--refresh".to_owned(), options.refresh.as_arg().to_owned()]);
        if options.include_current_session {
            owned.push("--include-current-session".to_owned());
        }
        owned.push("--json".to_owned());
        self.local_json_owned(MemoryOperation::Search, owned)
    }

    pub fn show_event(
        &self,
        id: impl AsRef<str>,
        options: ShowEventOptions,
    ) -> Result<MemoryEnvelope, MemoryError> {
        let mut owned = vec![
            "show".to_owned(),
            "event".to_owned(),
            id.as_ref().to_owned(),
            "--format".to_owned(),
            "json".to_owned(),
        ];
        if options.before > 0 {
            owned.extend(["--before".to_owned(), options.before.to_string()]);
        }
        if options.after > 0 {
            owned.extend(["--after".to_owned(), options.after.to_string()]);
        }
        if let Some(window) = options.window {
            owned.extend(["--window".to_owned(), window.to_string()]);
        }
        self.local_json_owned(MemoryOperation::ShowEvent, owned)
    }

    pub fn show_session(
        &self,
        id: impl AsRef<str>,
        options: ShowSessionOptions,
    ) -> Result<MemoryEnvelope, MemoryError> {
        self.local_json_owned(
            MemoryOperation::ShowSession,
            vec![
                "show".to_owned(),
                "session".to_owned(),
                id.as_ref().to_owned(),
                "--mode".to_owned(),
                options.mode,
                "--format".to_owned(),
                "json".to_owned(),
            ],
        )
    }

    pub fn locate_event(&self, id: impl AsRef<str>) -> Result<MemoryEnvelope, MemoryError> {
        self.local_json_owned(
            MemoryOperation::LocateEvent,
            vec![
                "locate".to_owned(),
                "event".to_owned(),
                id.as_ref().to_owned(),
                "--format".to_owned(),
                "json".to_owned(),
            ],
        )
    }

    pub fn locate_session(&self, id: impl AsRef<str>) -> Result<MemoryEnvelope, MemoryError> {
        self.local_json_owned(
            MemoryOperation::LocateSession,
            vec![
                "locate".to_owned(),
                "session".to_owned(),
                id.as_ref().to_owned(),
                "--format".to_owned(),
                "json".to_owned(),
            ],
        )
    }

    fn import_or_sync(
        &self,
        operation: MemoryOperation,
        options: ImportOptions,
    ) -> Result<MemoryEnvelope, MemoryError> {
        let mut owned = vec![
            "import".to_owned(),
            "--json".to_owned(),
            "--progress".to_owned(),
            "none".to_owned(),
        ];
        push_opt(&mut owned, "--provider", options.provider);
        if let Some(path) = options.path {
            push_opt(
                &mut owned,
                "--path",
                Some(path.to_string_lossy().into_owned()),
            );
        }
        if options.all {
            owned.push("--all".to_owned());
        }
        if options.resume {
            owned.push("--resume".to_owned());
        }
        self.local_json_owned(operation, owned)
    }

    fn local_json(
        &self,
        operation: MemoryOperation,
        args: &[&str],
    ) -> Result<MemoryEnvelope, MemoryError> {
        self.local_json_owned(
            operation,
            args.iter().map(|arg| (*arg).to_owned()).collect(),
        )
    }

    fn local_json_owned(
        &self,
        operation: MemoryOperation,
        args: Vec<String>,
    ) -> Result<MemoryEnvelope, MemoryError> {
        let config = match &self.backend {
            MemoryBackend::Local(config) => config,
            MemoryBackend::Hosted(config) => {
                let mut details = JsonObject::new();
                details.insert("backend".to_owned(), json!("hosted"));
                return Err(MemoryError {
                    body: MemoryErrorBody {
                        details: Some(details),
                        ..MemoryErrorBody::new(
                            MemoryErrorCode::NotSupported,
                            "hosted ctx memory backend is not available in this in-repo SDK",
                            false,
                        )
                    },
                }
                .with_cause(config.base_url.clone()));
            }
        };

        let raw = run_ctx_json(config, &args)?;
        normalize(operation, self.backend_info(), raw)
    }
}

fn push_opt(args: &mut Vec<String>, name: &str, value: Option<String>) {
    if let Some(value) = value {
        args.push(name.to_owned());
        args.push(value);
    }
}

fn run_ctx_json(config: &LocalBackendConfig, args: &[String]) -> Result<Value, MemoryError> {
    let mut command = Command::new(&config.ctx_binary);
    command
        .args(args)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped());
    if let Some(data_root) = &config.data_root {
        command.env("CTX_DATA_ROOT", data_root);
    }
    let mut child = command.spawn().map_err(|err| {
        MemoryError::new(
            MemoryErrorCode::BackendUnavailable,
            "failed to start ctx CLI",
            true,
        )
        .with_cause(err.to_string())
    })?;
    let started = Instant::now();
    loop {
        if let Some(status) = child.try_wait().map_err(|err| {
            MemoryError::new(
                MemoryErrorCode::AdapterError,
                "failed to wait for ctx CLI",
                true,
            )
            .with_cause(err.to_string())
        })? {
            let output = child.wait_with_output().map_err(|err| {
                MemoryError::new(
                    MemoryErrorCode::AdapterError,
                    "failed to collect ctx CLI output",
                    true,
                )
                .with_cause(err.to_string())
            })?;
            if !status.success() {
                let stderr = String::from_utf8_lossy(&output.stderr);
                return Err(MemoryError::new(
                    classify_stderr(&stderr),
                    stderr.trim().to_owned(),
                    false,
                ));
            }
            return serde_json::from_slice(&output.stdout).map_err(|err| {
                MemoryError::new(
                    MemoryErrorCode::DecodeError,
                    "failed to decode ctx JSON",
                    false,
                )
                .with_cause(err.to_string())
            });
        }
        if started.elapsed() > config.timeout {
            let _ = child.kill();
            return Err(MemoryError::new(
                MemoryErrorCode::Timeout,
                "ctx CLI command timed out",
                true,
            ));
        }
        thread::sleep(Duration::from_millis(20));
    }
}

fn classify_stderr(stderr: &str) -> MemoryErrorCode {
    let lower = stderr.to_ascii_lowercase();
    if lower.contains("not found") || lower.contains("no such") {
        MemoryErrorCode::NotFound
    } else if lower.contains("not initialized") || lower.contains("setup") {
        MemoryErrorCode::NotInitialized
    } else {
        MemoryErrorCode::AdapterError
    }
}

fn normalize(
    operation: MemoryOperation,
    backend: BackendInfo,
    raw: Value,
) -> Result<MemoryEnvelope, MemoryError> {
    let mut envelope = MemoryEnvelope::new(operation.clone(), Some(backend));
    match operation {
        MemoryOperation::Status => envelope.status = Some(normalize_status(&raw)?),
        MemoryOperation::Init => envelope.status = Some(normalize_status(&raw)?),
        MemoryOperation::Sources => {
            envelope.sources = Some(decode_payload(
                camelize_object_keys(&raw.get("sources").cloned().unwrap_or_else(|| json!([]))),
                "sources",
            )?)
        }
        MemoryOperation::Import | MemoryOperation::Sync => {
            envelope.import_result = Some(normalize_import(&raw)?)
        }
        MemoryOperation::Search => envelope.search = Some(normalize_search(&raw)?),
        MemoryOperation::ShowEvent => envelope.event = Some(normalize_event(&raw)?),
        MemoryOperation::ShowSession => envelope.session = Some(normalize_session(&raw)?),
        MemoryOperation::LocateEvent | MemoryOperation::LocateSession => {
            envelope.location = Some(normalize_location(&raw)?)
        }
        MemoryOperation::Error => {}
    }
    Ok(envelope)
}

fn decode_payload<T: DeserializeOwned>(value: Value, payload: &str) -> Result<T, MemoryError> {
    serde_json::from_value(value).map_err(|err| {
        MemoryError::new(
            MemoryErrorCode::DecodeError,
            format!("failed to decode memory-v1 {payload} payload"),
            false,
        )
        .with_cause(err.to_string())
    })
}

fn normalize_status(raw: &Value) -> Result<MemoryStatus, MemoryError> {
    let mut value = camel_alias_object(
        raw,
        &[
            ("schema_version", "schemaVersion"),
            ("data_root", "dataRoot"),
            ("indexed_items", "indexedItems"),
            ("indexed_sources", "indexedSources"),
            ("cataloged_sessions", "catalogedSessions"),
            ("indexed_catalog_sessions", "indexedCatalogSessions"),
            ("pending_catalog_sessions", "pendingCatalogSessions"),
            ("failed_catalog_sessions", "failedCatalogSessions"),
            ("stale_catalog_sessions", "staleCatalogSessions"),
            ("local_only", "localOnly"),
        ],
    );
    if let Some(object) = value.as_object_mut() {
        if !object.contains_key("initialized") {
            let initialized = object
                .get("mode")
                .and_then(Value::as_str)
                .map(|mode| matches!(mode, "ready" | "catalog_only"))
                .unwrap_or(true);
            object.insert("initialized".to_owned(), Value::Bool(initialized));
        }
        if !object.contains_key("localOnly") {
            object.insert("localOnly".to_owned(), Value::Bool(true));
        }
    }
    decode_payload(camelize_object_keys(&value), "status")
}

fn normalize_import(raw: &Value) -> Result<ImportResult, MemoryError> {
    let value = camel_alias_object(raw, &[("resume_mode", "resumeMode")]);
    decode_payload(camelize_object_keys(&value), "import")
}

fn normalize_search(raw: &Value) -> Result<SearchResult, MemoryError> {
    let value = camel_alias_object(raw, &[("generated_at", "generatedAt")]);
    decode_payload(camelize_object_keys(&value), "search")
}

fn normalize_event(raw: &Value) -> Result<EventResult, MemoryError> {
    let value = json!({
        "event": raw.get("event").cloned(),
        "events": raw.get("events").cloned().unwrap_or_else(|| json!([])),
        "source": raw.get("source").cloned()
    });
    decode_payload(camelize_object_keys(&value), "event")
}

fn normalize_session(raw: &Value) -> Result<SessionResult, MemoryError> {
    let value = json!({
        "session": raw.get("session").cloned(),
        "events": raw.get("events").cloned().unwrap_or_else(|| json!([])),
        "source": raw.get("source").cloned(),
        "mode": raw.get("mode").cloned(),
        "format": raw.get("format").cloned()
    });
    decode_payload(camelize_object_keys(&value), "session")
}

fn normalize_location(raw: &Value) -> Result<LocationResult, MemoryError> {
    let value = camel_alias_object(
        raw,
        &[
            ("ctx_session_id", "ctxSessionId"),
            ("ctx_event_id", "ctxEventId"),
            ("provider_session_id", "providerSessionId"),
        ],
    );
    decode_payload(camelize_object_keys(&value), "location")
}

pub fn fixture_path(name: impl AsRef<Path>) -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("../../contracts/memory-v1/fixtures")
        .join(name)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;

    #[cfg(unix)]
    use std::os::unix::fs::PermissionsExt;

    #[test]
    fn reads_shared_search_fixture() {
        let value: MemoryEnvelope = serde_json::from_str(include_str!(
            "../../../contracts/memory-v1/fixtures/search.results.json"
        ))
        .unwrap();
        assert_eq!(value.contract_version, CONTRACT_VERSION);
        assert_eq!(value.operation, MemoryOperation::Search);
        let search = value.search.unwrap();
        assert_eq!(search.query.as_deref(), Some("local memory"));
        assert_eq!(search.results.len(), 1);
        assert_eq!(
            search.results[0].ctx_event_id.as_deref(),
            Some("11111111-1111-4111-8111-111111111111")
        );
    }

    #[test]
    fn init_normalizes_real_setup_json_into_status_contract() {
        let envelope = normalize(
            MemoryOperation::Init,
            BackendInfo::local(Some("/tmp/ctx".to_owned())),
            json!({
                "schema_version": 1,
                "data_root": "/tmp/ctx",
                "database_path": "/tmp/ctx/history.sqlite3",
                "config_path": "/tmp/ctx/config.toml",
                "mode": "ready",
                "indexed_items": 12,
                "network_required": false,
                "catalog": {"cataloged_sessions": 4},
                "import": {"resume": false, "totals": {}}
            }),
        )
        .unwrap();

        assert_eq!(envelope.operation, MemoryOperation::Init);
        let status = envelope.status.unwrap();
        assert!(status.initialized);
        assert!(status.local_only);
        assert_eq!(status.data_root.as_deref(), Some("/tmp/ctx"));
        assert_eq!(status.indexed_items, Some(12));
        assert!(status.extra.contains_key("mode"));
        assert!(status.extra.contains_key("networkRequired"));
    }

    #[test]
    fn hosted_backend_returns_structured_error() {
        let client = MemoryClient::hosted(HostedBackendConfig {
            base_url: "https://ctx.example.invalid".to_owned(),
            timeout: Duration::from_secs(1),
        });
        let err = client.status().unwrap_err();
        assert_eq!(err.body.code, MemoryErrorCode::NotSupported);
        assert!(!err.body.retryable);
    }

    #[test]
    fn builds_search_cli_arguments_without_running_for_public_options() {
        let options = SearchOptions {
            query: Some("memory".to_owned()),
            terms: vec!["ctx".to_owned()],
            limit: 3,
            provider: Some("codex".to_owned()),
            refresh: SearchRefresh::Off,
            events: true,
            ..SearchOptions::default()
        };
        assert_eq!(options.refresh.as_arg(), "off");
        assert_eq!(options.terms, vec!["ctx"]);
    }

    #[test]
    fn local_client_can_dogfood_fake_ctx_without_private_history() {
        let temp = tempfile::tempdir().unwrap();
        let script = temp.path().join("ctx-fake");
        fs::write(
            &script,
            r#"#!/bin/sh
set -eu
if [ "$1" = "status" ]; then
  printf '%s\n' '{"initialized":true,"local_only":true,"data_root":"'"$CTX_DATA_ROOT"'","indexed_items":2}'
  exit 0
fi
if [ "$1" = "search" ]; then
  printf '%s\n' '{"query":"rust sdk","generated_at":"2026-07-01T12:00:00Z","results":[{"ctx_event_id":"event-1","ctx_session_id":"session-1","result_scope":"event","snippet":"typed ergonomics"}]}'
  exit 0
fi
echo "unexpected command: $*" >&2
exit 2
"#,
        )
        .unwrap();
        #[cfg(unix)]
        fs::set_permissions(&script, fs::Permissions::from_mode(0o755)).unwrap();

        let data_root = temp.path().join("data-root");
        let client = MemoryClient::local(LocalBackendConfig {
            ctx_binary: script,
            data_root: Some(data_root.clone()),
            timeout: Duration::from_secs(5),
        });

        let status = client.status().unwrap();
        let status_body = status.status.unwrap();
        assert!(status_body.initialized);
        assert!(status_body.local_only);
        assert_eq!(
            status_body.data_root.as_deref(),
            Some(data_root.to_string_lossy().as_ref())
        );
        assert_eq!(status_body.indexed_items, Some(2));

        let search = client
            .search(SearchOptions {
                query: Some("rust sdk".to_owned()),
                refresh: SearchRefresh::Off,
                limit: 1,
                ..SearchOptions::default()
            })
            .unwrap();
        let search_body = search.search.unwrap();
        assert_eq!(search_body.results.len(), 1);
        assert_eq!(search_body.results[0].result_scope, "event");
        assert_eq!(
            search_body.results[0].snippet.as_deref(),
            Some("typed ergonomics")
        );
    }
}
