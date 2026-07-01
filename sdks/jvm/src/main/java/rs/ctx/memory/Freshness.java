package rs.ctx.memory;

import java.util.Map;

/** Optional pre-search refresh metadata. */
public final class Freshness {
    private final Map<String, Object> fields;
    private final Totals totals;

    Freshness(Map<String, Object> fields) {
        this.fields = MemoryValue.copyObject(fields);
        this.totals = fields.containsKey("totals") ? Totals.from(fields.get("totals")) : null;
    }

    static Freshness from(Object value) {
        Map<String, Object> fields = MemoryValue.objectOrNull(value);
        return fields == null ? null : new Freshness(fields);
    }

    public String getMode() {
        return MemoryValue.string(fields.get("mode"));
    }

    public String mode() {
        return getMode();
    }

    public String getStatus() {
        return MemoryValue.string(fields.get("status"));
    }

    public String status() {
        return getStatus();
    }

    public Integer getSourceCount() {
        return MemoryValue.integer(fields.get("sourceCount"));
    }

    public Integer sourceCount() {
        return getSourceCount();
    }

    public Totals getTotals() {
        return totals;
    }

    public Totals totals() {
        return totals;
    }

    public String getError() {
        return MemoryValue.string(fields.get("error"));
    }

    public String error() {
        return getError();
    }

    public Map<String, Object> asMap() {
        return fields;
    }
}
