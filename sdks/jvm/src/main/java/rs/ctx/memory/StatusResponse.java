package rs.ctx.memory;

import java.util.Map;

/** Response returned by {@link MemoryClient#status()}. */
public final class StatusResponse extends MemoryEnvelope {
    private final StatusRecord status;

    StatusResponse(Map<String, Object> canonical) {
        super(canonical);
        this.status = StatusRecord.from(payload("status"));
    }

    public StatusRecord getStatus() {
        return status;
    }

    public StatusRecord status() {
        return status;
    }
}
