using System.Text.Json.Nodes;

namespace Ctx.Memory;

/// <summary>Base structured exception for ctx memory SDK failures.</summary>
public class CtxMemoryException : Exception
{
    public CtxMemoryException(
        string message,
        string code = "unknown",
        bool retryable = false,
        JsonObject? details = null,
        Exception? innerException = null)
        : base(message, innerException)
    {
        Code = code;
        Retryable = retryable;
        Details = details ?? new JsonObject();
    }

    public string Code { get; }
    public bool Retryable { get; }
    public JsonObject Details { get; }

    public JsonObject ToMemoryError()
    {
        return new JsonObject
        {
            ["code"] = Code,
            ["message"] = Message,
            ["retryable"] = Retryable,
            ["details"] = JsonHelpers.Clone(Details),
            ["cause"] = InnerException?.Message
        };
    }
}

public sealed class CtxMemoryCliException : CtxMemoryException
{
    public CtxMemoryCliException(
        string message,
        IReadOnlyList<string> command,
        int exitCode,
        string stdout,
        string stderr,
        string code = "adapter_error",
        bool retryable = false,
        Exception? innerException = null)
        : base(
            message,
            code,
            retryable: retryable,
            details: BuildDetails(command, exitCode, stdout, stderr),
            innerException)
    {
        Command = command.ToArray();
        ExitCode = exitCode;
        Stdout = stdout;
        Stderr = stderr;
    }

    public IReadOnlyList<string> Command { get; }
    public int ExitCode { get; }
    public string Stdout { get; }
    public string Stderr { get; }

    private static JsonObject BuildDetails(IReadOnlyList<string> command, int exitCode, string stdout, string stderr)
    {
        return new JsonObject
        {
            ["command"] = JsonHelpers.ToJsonArray(command),
            ["exitCode"] = exitCode,
            ["stdout"] = stdout,
            ["stderr"] = stderr
        };
    }
}

public sealed class CtxMemoryProtocolException : CtxMemoryException
{
    public CtxMemoryProtocolException(string message, JsonObject? details = null, Exception? innerException = null)
        : base(message, "decode_error", retryable: false, details, innerException)
    {
    }
}

public sealed class CtxMemoryValidationException : CtxMemoryException
{
    public CtxMemoryValidationException(string message, JsonObject? details = null)
        : base(message, "invalid_request", retryable: false, details)
    {
    }
}

public sealed class HostedTransportNotImplementedException : CtxMemoryException
{
    public HostedTransportNotImplementedException(string method, HostedMemoryConfig config)
        : base(
            "hosted ctx agent history backend is not available in this in-repo SDK",
            "not_supported",
            retryable: false,
            details: BuildDetails(method, config))
    {
        Method = method;
    }

    public string Method { get; }

    private static JsonObject BuildDetails(string method, HostedMemoryConfig config)
    {
        var details = new JsonObject
        {
            ["backend"] = "hosted",
            ["method"] = method
        };
        if (!string.IsNullOrWhiteSpace(config.BaseUrl))
        {
            details["baseUrl"] = config.BaseUrl;
        }
        return details;
    }
}
