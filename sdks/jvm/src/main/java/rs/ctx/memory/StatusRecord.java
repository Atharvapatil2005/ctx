package rs.ctx.memory;

import java.util.Map;

/** Local agent history index status. */
public final class StatusRecord {
    private final Map<String, Object> fields;
    private final Freshness freshness;

    StatusRecord(Map<String, Object> fields) {
        this.fields = MemoryValue.copyObject(fields);
        this.freshness = Freshness.from(fields.get("freshness"));
    }

    static StatusRecord from(Object value) {
        return new StatusRecord(MemoryValue.object(value));
    }

    public Boolean getInitialized() {
        return MemoryValue.bool(fields.get("initialized"));
    }

    public Boolean initialized() {
        return getInitialized();
    }

    public Boolean getLocalOnly() {
        return MemoryValue.bool(fields.get("localOnly"));
    }

    public Boolean localOnly() {
        return getLocalOnly();
    }

    public String getDataRoot() {
        return MemoryValue.string(fields.get("dataRoot"));
    }

    public String dataRoot() {
        return getDataRoot();
    }

    public Integer getIndexedItems() {
        return MemoryValue.integer(fields.get("indexedItems"));
    }

    public Integer indexedItems() {
        return getIndexedItems();
    }

    public Integer getIndexedSources() {
        return MemoryValue.integer(fields.get("indexedSources"));
    }

    public Integer indexedSources() {
        return getIndexedSources();
    }

    public Integer getCatalogedSessions() {
        return MemoryValue.integer(fields.get("catalogedSessions"));
    }

    public Integer catalogedSessions() {
        return getCatalogedSessions();
    }

    public Integer getIndexedCatalogSessions() {
        return MemoryValue.integer(fields.get("indexedCatalogSessions"));
    }

    public Integer indexedCatalogSessions() {
        return getIndexedCatalogSessions();
    }

    public Integer getPendingCatalogSessions() {
        return MemoryValue.integer(fields.get("pendingCatalogSessions"));
    }

    public Integer pendingCatalogSessions() {
        return getPendingCatalogSessions();
    }

    public Integer getFailedCatalogSessions() {
        return MemoryValue.integer(fields.get("failedCatalogSessions"));
    }

    public Integer failedCatalogSessions() {
        return getFailedCatalogSessions();
    }

    public Integer getStaleCatalogSessions() {
        return MemoryValue.integer(fields.get("staleCatalogSessions"));
    }

    public Integer staleCatalogSessions() {
        return getStaleCatalogSessions();
    }

    public Freshness getFreshness() {
        return freshness;
    }

    public Freshness freshness() {
        return freshness;
    }

    public Map<String, Object> asMap() {
        return fields;
    }
}
