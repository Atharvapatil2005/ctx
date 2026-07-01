using System.Text.Json.Nodes;

namespace Ctx.Memory;

/// <summary>Executes adapter-specific memory-v1 operations.</summary>
public interface IMemoryTransport
{
    string Name { get; }

    JsonObject Backend(JsonObject? raw = null);

    Task<JsonObject> ExecuteJsonAsync(
        string operation,
        IReadOnlyList<string> args,
        CancellationToken cancellationToken = default);

    Task<string?> GetCtxVersionAsync(CancellationToken cancellationToken = default);
}
