# ctx Go SDK

Experimental Go SDK for the local `ctx` memory-v1 JSON contract.

The SDK has no third-party dependencies and defaults to the local `ctx` CLI. It
does not require network access or API keys.

```go
package main

import (
	"context"
	"fmt"
	"log"

	ctxmemory "github.com/ctxrs/ctx/sdks/go"
)

func main() {
	client := ctxmemory.NewLocalClient()

	status, err := client.Status(context.Background())
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(status.Status.IndexedItems)
}
```

## API

The public client mirrors memory-v1 operations:

- `Status(ctx)`
- `Init(ctx, InitOptions)`
- `Sources(ctx)`
- `Import(ctx, ImportOptions)`
- `Sync(ctx, ImportOptions)`, an alias for local import/index refresh
- `Search(ctx, SearchOptions)`
- `ShowEvent(ctx, ShowEventOptions)`
- `ShowSession(ctx, ShowSessionOptions)`
- `LocateEvent(ctx, LocateEventOptions)`
- `LocateSession(ctx, LocateSessionOptions)`

Version constants:

- `APIVersion`
- `SchemaVersion`
- `SDKVersion`

## Local CLI

```go
client := ctxmemory.NewLocalClient(
	ctxmemory.WithCLIPath("/usr/local/bin/ctx"),
	ctxmemory.WithDataRoot("/tmp/ctx-data"),
)
```

The adapter runs JSON-producing CLI commands such as `ctx status --json`,
`ctx search --json`, and `ctx show event --format json`, then normalizes CLI
JSON into `memory-v1` wrappers with `contractVersion` and `schemaVersion`.

## Errors

SDK calls return `*ctxmemory.Error` for structured failures. Use
`ctxmemory.IsErrorKind(err, ctxmemory.ErrorKindCommandFailed)` when branching on
failure classes.

## Hosted Placeholder

`HostedConfig` and `NewHostedClient` reserve the hosted transport API. The
hosted transport is not implemented yet; operations return
`ErrorKindHostedNotImplemented` without making network calls.
