package rs.ctx.memory;

import java.util.Map;

/** Aggregate import and refresh counts. */
public final class Totals {
    private final Map<String, Object> fields;

    Totals(Map<String, Object> fields) {
        this.fields = MemoryValue.copyObject(fields);
    }

    static Totals from(Object value) {
        return new Totals(MemoryValue.object(value));
    }

    public Integer getSourceFiles() {
        return MemoryValue.integer(fields.get("sourceFiles"));
    }

    public Integer sourceFiles() {
        return getSourceFiles();
    }

    public Long getSourceBytes() {
        return MemoryValue.longValue(fields.get("sourceBytes"));
    }

    public Long sourceBytes() {
        return getSourceBytes();
    }

    public Integer getImportedSources() {
        return MemoryValue.integer(fields.get("importedSources"));
    }

    public Integer importedSources() {
        return getImportedSources();
    }

    public Integer getFailedSources() {
        return MemoryValue.integer(fields.get("failedSources"));
    }

    public Integer failedSources() {
        return getFailedSources();
    }

    public Integer getImportedSessions() {
        return MemoryValue.integer(fields.get("importedSessions"));
    }

    public Integer importedSessions() {
        return getImportedSessions();
    }

    public Integer getImportedEvents() {
        return MemoryValue.integer(fields.get("importedEvents"));
    }

    public Integer importedEvents() {
        return getImportedEvents();
    }

    public Integer getImportedEdges() {
        return MemoryValue.integer(fields.get("importedEdges"));
    }

    public Integer importedEdges() {
        return getImportedEdges();
    }

    public Integer getSkipped() {
        return MemoryValue.integer(fields.get("skipped"));
    }

    public Integer skipped() {
        return getSkipped();
    }

    public Integer getFailed() {
        return MemoryValue.integer(fields.get("failed"));
    }

    public Integer failed() {
        return getFailed();
    }

    public Map<String, Object> asMap() {
        return fields;
    }
}
