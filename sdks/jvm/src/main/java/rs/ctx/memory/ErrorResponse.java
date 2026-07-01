package rs.ctx.memory;

import java.util.Map;

/** Response wrapper for canonical memory-v1 error fixtures. */
public final class ErrorResponse extends MemoryEnvelope {
    private final MemoryError error;

    ErrorResponse(Map<String, Object> canonical) {
        super(canonical);
        this.error = MemoryError.from(payload("error"));
    }

    public MemoryError getError() {
        return error;
    }

    public MemoryError error() {
        return error;
    }
}
