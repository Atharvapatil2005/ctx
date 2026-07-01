package rs.ctx.memory;

import java.util.Map;

/** Search filter metadata. Unknown additive filters remain available through asMap(). */
public final class SearchFilters {
    private final Map<String, Object> fields;

    SearchFilters(Map<String, Object> fields) {
        this.fields = MemoryValue.copyObject(fields);
    }

    static SearchFilters from(Object value) {
        Map<String, Object> fields = MemoryValue.objectOrNull(value);
        return fields == null ? null : new SearchFilters(fields);
    }

    public String getProvider() {
        return MemoryValue.string(fields.get("provider"));
    }

    public String provider() {
        return getProvider();
    }

    public String getWorkspace() {
        return MemoryValue.string(fields.get("workspace"));
    }

    public String workspace() {
        return getWorkspace();
    }

    public String getSince() {
        return MemoryValue.string(fields.get("since"));
    }

    public String since() {
        return getSince();
    }

    public Map<String, Object> asMap() {
        return fields;
    }
}
