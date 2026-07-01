using System.Text.Json.Nodes;

namespace Ctx.Memory;

/// <summary>Client for the experimental ctx memory-v1 API.</summary>
public sealed class MemoryClient
{
    private readonly IMemoryTransport _transport;

    public MemoryClient(IMemoryTransport transport)
    {
        _transport = transport;
    }

    public IMemoryTransport Transport => _transport;

    public static MemoryClient Local(LocalMemoryConfig? config = null)
    {
        return new MemoryClient(new LocalCliAdapter(config));
    }

    public static MemoryClient Hosted(HostedMemoryConfig config)
    {
        return new MemoryClient(new HostedAdapter(config));
    }

    public async Task<StatusResponse> StatusAsync(CancellationToken cancellationToken = default)
    {
        var raw = await InvokeAsync("status", ["status", "--json"], cancellationToken).ConfigureAwait(false);
        var envelope = MemoryContract.Envelope("status", _transport.Backend(raw), "status", MemoryContract.NormalizeStatus(raw));
        return new StatusResponse(envelope);
    }

    public async Task<InitResponse> InitAsync(InitOptions? options = null, CancellationToken cancellationToken = default)
    {
        options ??= new InitOptions();
        var args = new List<string> { "setup", "--json" };
        AddOption(args, "--progress", options.Progress);
        if (options.CatalogOnly)
        {
            args.Add("--catalog-only");
        }

        var raw = await InvokeAsync("init", args, cancellationToken).ConfigureAwait(false);
        var envelope = MemoryContract.Envelope("init", _transport.Backend(raw), "status", MemoryContract.NormalizeStatus(raw));
        return new InitResponse(envelope);
    }

    public async Task<SourcesResponse> SourcesAsync(CancellationToken cancellationToken = default)
    {
        var raw = await InvokeAsync("sources", ["sources", "--json"], cancellationToken).ConfigureAwait(false);
        var envelope = MemoryContract.Envelope("sources", _transport.Backend(raw), "sources", MemoryContract.NormalizeSources(raw));
        return new SourcesResponse(envelope);
    }

    public async Task<ImportResponse> ImportMemoryAsync(ImportOptions? options = null, CancellationToken cancellationToken = default)
    {
        return await ImportLikeAsync("import", options, cancellationToken).ConfigureAwait(false);
    }

    public async Task<ImportResponse> ImportAsync(ImportOptions? options = null, CancellationToken cancellationToken = default)
    {
        return await ImportMemoryAsync(options, cancellationToken).ConfigureAwait(false);
    }

    public async Task<ImportResponse> SyncAsync(ImportOptions? options = null, CancellationToken cancellationToken = default)
    {
        return await ImportLikeAsync("sync", options, cancellationToken).ConfigureAwait(false);
    }

    public async Task<SearchResponse> SearchAsync(SearchOptions? options = null, CancellationToken cancellationToken = default)
    {
        options ??= new SearchOptions();
        var args = new List<string> { "search" };
        if (!string.IsNullOrWhiteSpace(options.Query))
        {
            args.Add(options.Query);
        }
        foreach (var term in options.Terms ?? [])
        {
            AddOption(args, "--term", term);
        }
        if (options.Limit is > 0)
        {
            AddOption(args, "--limit", options.Limit.Value.ToString(System.Globalization.CultureInfo.InvariantCulture));
        }
        AddOption(args, "--provider", options.Provider);
        AddOption(args, "--workspace", options.Workspace);
        AddOption(args, "--since", options.Since);
        if (options.PrimaryOnly)
        {
            args.Add("--primary-only");
        }
        if (options.IncludeSubagents)
        {
            args.Add("--include-subagents");
        }
        AddOption(args, "--event-type", options.EventType);
        AddOption(args, "--file", options.File);
        AddOption(args, "--session", options.Session);
        if (options.Events)
        {
            args.Add("--events");
        }
        AddOption(args, "--refresh", options.Refresh);
        if (options.IncludeCurrentSession)
        {
            args.Add("--include-current-session");
        }
        args.Add("--json");

        var raw = await InvokeAsync("search", args, cancellationToken).ConfigureAwait(false);
        var envelope = MemoryContract.Envelope("search", _transport.Backend(raw), "search", MemoryContract.NormalizeSearch(raw));
        return new SearchResponse(envelope);
    }

    public async Task<ShowEventResponse> ShowEventAsync(
        string eventId,
        ShowEventOptions? options = null,
        CancellationToken cancellationToken = default)
    {
        RequireValue(eventId, "event id");
        options ??= new ShowEventOptions();

        var args = new List<string> { "show", "event", eventId, "--format", "json" };
        AddNumberOption(args, "--before", options.Before);
        AddNumberOption(args, "--after", options.After);
        AddNumberOption(args, "--window", options.Window);

        var raw = await InvokeAsync("showEvent", args, cancellationToken).ConfigureAwait(false);
        var envelope = MemoryContract.Envelope("showEvent", _transport.Backend(raw), "event", MemoryContract.NormalizeEvent(raw));
        return new ShowEventResponse(envelope);
    }

    public async Task<ShowSessionResponse> ShowSessionAsync(
        string sessionId,
        ShowSessionOptions? options = null,
        CancellationToken cancellationToken = default)
    {
        options = (options ?? new ShowSessionOptions()) with { Id = sessionId };
        return await ShowSessionAsync(options, cancellationToken).ConfigureAwait(false);
    }

    public async Task<ShowSessionResponse> ShowSessionAsync(
        ShowSessionOptions options,
        CancellationToken cancellationToken = default)
    {
        var args = BuildSessionLookupArgs("show", "session", options);
        AddOption(args, "--mode", options.Mode);
        args.Add("--format");
        args.Add("json");

        var raw = await InvokeAsync("showSession", args, cancellationToken).ConfigureAwait(false);
        var envelope = MemoryContract.Envelope("showSession", _transport.Backend(raw), "session", MemoryContract.NormalizeSession(raw));
        return new ShowSessionResponse(envelope);
    }

    public async Task<LocateEventResponse> LocateEventAsync(string eventId, CancellationToken cancellationToken = default)
    {
        RequireValue(eventId, "event id");
        var raw = await InvokeAsync(
            "locateEvent",
            ["locate", "event", eventId, "--format", "json"],
            cancellationToken).ConfigureAwait(false);
        var envelope = MemoryContract.Envelope("locateEvent", _transport.Backend(raw), "location", MemoryContract.NormalizeLocation(raw));
        return new LocateEventResponse(envelope);
    }

    public async Task<LocateSessionResponse> LocateSessionAsync(string sessionId, CancellationToken cancellationToken = default)
    {
        return await LocateSessionAsync(new SessionLookupOptions { Id = sessionId }, cancellationToken).ConfigureAwait(false);
    }

    public async Task<LocateSessionResponse> LocateSessionAsync(
        SessionLookupOptions options,
        CancellationToken cancellationToken = default)
    {
        var args = BuildSessionLookupArgs("locate", "session", options);
        args.Add("--format");
        args.Add("json");

        var raw = await InvokeAsync("locateSession", args, cancellationToken).ConfigureAwait(false);
        var envelope = MemoryContract.Envelope("locateSession", _transport.Backend(raw), "location", MemoryContract.NormalizeLocation(raw));
        return new LocateSessionResponse(envelope);
    }

    public async Task<VersionInfo> VersionAsync(CancellationToken cancellationToken = default)
    {
        var ctxVersion = await _transport.GetCtxVersionAsync(cancellationToken).ConfigureAwait(false);
        return new VersionInfo(
            CtxMemoryVersions.SdkVersion,
            CtxMemoryVersions.ContractVersion,
            _transport.Name,
            ctxVersion);
    }

    public async Task<VersionInfo> VersioningAsync(CancellationToken cancellationToken = default)
    {
        return await VersionAsync(cancellationToken).ConfigureAwait(false);
    }

    private async Task<ImportResponse> ImportLikeAsync(
        string operation,
        ImportOptions? options,
        CancellationToken cancellationToken)
    {
        options ??= new ImportOptions();
        var args = new List<string> { "import", "--json" };
        AddOption(args, "--progress", options.Progress);
        if (options.All)
        {
            args.Add("--all");
        }
        AddOption(args, "--provider", options.Provider);
        AddOption(args, "--path", options.Path);
        if (options.Resume)
        {
            args.Add("--resume");
        }

        var raw = await InvokeAsync(operation, args, cancellationToken).ConfigureAwait(false);
        var envelope = MemoryContract.Envelope(operation, _transport.Backend(raw), "import", MemoryContract.NormalizeImport(raw));
        return new ImportResponse(envelope);
    }

    private async Task<JsonObject> InvokeAsync(
        string operation,
        IReadOnlyList<string> args,
        CancellationToken cancellationToken)
    {
        var raw = await _transport.ExecuteJsonAsync(operation, args, cancellationToken).ConfigureAwait(false);
        MemoryContract.EnsureSupportedSchema(raw, operation);
        return raw;
    }

    private static List<string> BuildSessionLookupArgs(string command, string kind, SessionLookupOptions options)
    {
        var args = new List<string> { command, kind };
        if (!string.IsNullOrWhiteSpace(options.Id))
        {
            args.Add(options.Id);
        }
        else if (!string.IsNullOrWhiteSpace(options.ProviderSessionId))
        {
            AddOption(args, "--provider", options.Provider);
            AddOption(args, "--provider-session", options.ProviderSessionId);
        }
        else
        {
            throw new CtxMemoryValidationException($"{kind} lookup requires an id or provider session id");
        }
        return args;
    }

    private static void RequireValue(string value, string name)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new CtxMemoryValidationException($"{name} is required");
        }
    }

    private static void AddOption(List<string> args, string flag, string? value)
    {
        if (!string.IsNullOrWhiteSpace(value))
        {
            args.Add(flag);
            args.Add(value);
        }
    }

    private static void AddNumberOption(List<string> args, string flag, int? value)
    {
        if (value is > 0)
        {
            args.Add(flag);
            args.Add(value.Value.ToString(System.Globalization.CultureInfo.InvariantCulture));
        }
    }
}
