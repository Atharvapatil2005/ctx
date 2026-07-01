package rs.ctx.memory;

import java.util.Map;

/** Source provenance for show and locate results. */
public final class SourceLocation {
    private final Map<String, Object> fields;

    SourceLocation(Map<String, Object> fields) {
        this.fields = MemoryValue.copyObject(fields);
    }

    static SourceLocation from(Object value) {
        Map<String, Object> fields = MemoryValue.objectOrNull(value);
        return fields == null ? null : new SourceLocation(fields);
    }

    public String getPath() {
        return MemoryValue.string(fields.get("path"));
    }

    public String path() {
        return getPath();
    }

    public String getCursor() {
        return MemoryValue.string(fields.get("cursor"));
    }

    public String cursor() {
        return getCursor();
    }

    public Boolean getExists() {
        return MemoryValue.bool(fields.get("exists"));
    }

    public Boolean exists() {
        return getExists();
    }

    public String getSourceId() {
        return MemoryValue.string(fields.get("sourceId"));
    }

    public String sourceId() {
        return getSourceId();
    }

    public String getSourceFormat() {
        return MemoryValue.string(fields.get("sourceFormat"));
    }

    public String sourceFormat() {
        return getSourceFormat();
    }

    public Map<String, Object> asMap() {
        return fields;
    }
}
