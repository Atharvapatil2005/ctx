package rs.ctx.memory;

import java.util.Map;

/** Response returned by {@link MemoryClient#init(MemoryOptions.Init)}. */
public final class InitResponse extends MemoryEnvelope {
    private final StatusRecord status;

    InitResponse(Map<String, Object> canonical) {
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
