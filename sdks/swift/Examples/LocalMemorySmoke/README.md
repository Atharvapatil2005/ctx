# LocalMemorySmoke

Fake-by-default Swift smoke executable for the local ctx memory SDK.

Run from `sdks/swift`:

```bash
swift run LocalMemorySmoke
```

The default mode uses an in-memory fake `CommandRunner` and exercises
`status`, `initMemory`, `importMemory`, `sync`, `search`, `showEvent`,
`showSession`, `locateEvent`, and `locateSession` without reading real local
history.

Real ctx CLI mode is explicit:

```bash
swift run LocalMemorySmoke --real --ctx-path /path/to/ctx --data-root /tmp/ctx-smoke
```
