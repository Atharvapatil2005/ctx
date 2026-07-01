package rs.ctx.memory;

import java.util.Map;

/** Session metadata returned by show-session. */
public final class SessionSummary {
    private final Map<String, Object> fields;

    SessionSummary(Map<String, Object> fields) {
        this.fields = MemoryValue.copyObject(fields);
    }

    static SessionSummary from(Object value) {
        Map<String, Object> fields = MemoryValue.objectOrNull(value);
        return fields == null ? null : new SessionSummary(fields);
    }

    public String getCtxSessionId() {
        return MemoryValue.string(fields.get("ctxSessionId"));
    }

    public String ctxSessionId() {
        return getCtxSessionId();
    }

    public String getProvider() {
        return MemoryValue.string(fields.get("provider"));
    }

    public String provider() {
        return getProvider();
    }

    public String getProviderSessionId() {
        return MemoryValue.string(fields.get("providerSessionId"));
    }

    public String providerSessionId() {
        return getProviderSessionId();
    }

    public String getTitle() {
        return MemoryValue.string(fields.get("title"));
    }

    public String title() {
        return getTitle();
    }

    public Map<String, Object> asMap() {
        return fields;
    }
}
