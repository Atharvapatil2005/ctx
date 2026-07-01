package rs.ctx.memory;

import java.util.Map;

/** agent-history-v1 structured error payload. */
public final class MemoryError {
    private final Map<String, Object> fields;

    MemoryError(Map<String, Object> fields) {
        this.fields = MemoryValue.copyObject(fields);
    }

    static MemoryError from(Object value) {
        return new MemoryError(MemoryValue.object(value));
    }

    public String getCode() {
        return MemoryValue.string(fields.get("code"));
    }

    public String code() {
        return getCode();
    }

    public String getMessage() {
        return MemoryValue.string(fields.get("message"));
    }

    public String message() {
        return getMessage();
    }

    public Boolean getRetryable() {
        return MemoryValue.bool(fields.get("retryable"));
    }

    public Boolean retryable() {
        return getRetryable();
    }

    public Map<String, Object> getDetails() {
        return MemoryValue.object(fields.get("details"));
    }

    public Map<String, Object> details() {
        return getDetails();
    }

    public String getCause() {
        return MemoryValue.string(fields.get("cause"));
    }

    public String cause() {
        return getCause();
    }

    public Map<String, Object> asMap() {
        return fields;
    }
}
