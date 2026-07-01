package rs.ctx.memory;

import java.util.Map;

/** Resume metadata returned by locate operations. */
public final class ResumeLocation {
    private final Map<String, Object> fields;

    ResumeLocation(Map<String, Object> fields) {
        this.fields = MemoryValue.copyObject(fields);
    }

    static ResumeLocation from(Object value) {
        Map<String, Object> fields = MemoryValue.objectOrNull(value);
        return fields == null ? null : new ResumeLocation(fields);
    }

    public String getCursor() {
        return MemoryValue.string(fields.get("cursor"));
    }

    public String cursor() {
        return getCursor();
    }

    public String getPath() {
        return MemoryValue.string(fields.get("path"));
    }

    public String path() {
        return getPath();
    }

    public Map<String, Object> asMap() {
        return fields;
    }
}
