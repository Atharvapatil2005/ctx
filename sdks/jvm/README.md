# ctx JVM SDK

Experimental in-repo JVM SDK for the ctx `memory-v1` contract.

This SDK is not published to Maven Central or any package registry. It is plain
Java source for now so Java and Kotlin callers can evaluate the API without a
large dependency footprint.

## API

`MemoryClient.local()` exposes typed Java 11 response classes for:

- `status()` -> `StatusResponse`
- `init(InitOptions)` -> `InitResponse`
- `sources()` -> `SourcesResponse`
- `importMemory(ImportOptions)` / `sync(ImportOptions)` -> `ImportResponse`
- `search(SearchOptions)` -> `SearchResponse`
- `showEvent(String, ShowEventOptions)` -> `ShowEventResponse`
- `showSession(String, ShowSessionOptions)` -> `ShowSessionResponse`
- `locateEvent(String)` -> `LocateEventResponse`
- `locateSession(String)` -> `LocateSessionResponse`
- `version()` -> `VersionInfo`

All data responses extend `MemoryEnvelope`, with `contractVersion`,
`schemaVersion`, `operation`, backend metadata, `asMap()`, and operation payload
access. Local mode shells out to the `ctx` CLI and performs no network calls or
provider API calls.

Hosted configuration is present as `MemoryClient.hosted(HostedConfig)` and
returns a structured `not_supported` error until a hosted ctx service exists.

## Example

```bash
sdks/jvm/scripts/test
```

The test script also compiles and runs `examples/ToyMemoryApp.java`, a fake
transport toy app that exercises `status`, `search`, `showEvent`, and
`locateEvent` without reading local private history.

## Tests

```bash
sdks/jvm/scripts/test
```

The script uses `javac` and `java` directly. It has no external dependencies.
