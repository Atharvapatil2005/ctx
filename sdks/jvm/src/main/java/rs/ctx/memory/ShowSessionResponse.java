package rs.ctx.memory;

import java.util.Map;

/** Response returned by {@link MemoryClient#showSession(String, MemoryOptions.ShowSession)}. */
public final class ShowSessionResponse extends MemoryEnvelope {
    private final SessionResult session;

    ShowSessionResponse(Map<String, Object> canonical) {
        super(canonical);
        this.session = SessionResult.from(payload("session"));
    }

    public SessionResult getSession() {
        return session;
    }

    public SessionResult session() {
        return session;
    }
}
