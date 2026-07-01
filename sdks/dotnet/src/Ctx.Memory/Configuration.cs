namespace Ctx.Memory;

/// <summary>Configuration for the local ctx CLI adapter.</summary>
public sealed record LocalMemoryConfig
{
    public string CtxBinary { get; init; } = "ctx";
    public string? DataRoot { get; init; }
    public string? WorkingDirectory { get; init; }
    public IReadOnlyDictionary<string, string?>? Environment { get; init; }
    public TimeSpan? Timeout { get; init; }
}

/// <summary>Placeholder configuration for a future hosted memory-v1 transport.</summary>
public sealed record HostedMemoryConfig
{
    public HostedMemoryConfig(string baseUrl)
    {
        BaseUrl = baseUrl;
    }

    public string BaseUrl { get; init; }
    public string? ApiKey { get; init; }
    public TimeSpan? Timeout { get; init; }
}
