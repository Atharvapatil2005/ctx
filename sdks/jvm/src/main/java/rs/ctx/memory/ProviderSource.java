package rs.ctx.memory;

import java.util.Map;

/** One discovered local provider source. */
public final class ProviderSource {
    private final Map<String, Object> fields;

    ProviderSource(Map<String, Object> fields) {
        this.fields = MemoryValue.copyObject(fields);
    }

    public String getProvider() {
        return MemoryValue.string(fields.get("provider"));
    }

    public String provider() {
        return getProvider();
    }

    public String getPath() {
        return MemoryValue.string(fields.get("path"));
    }

    public String path() {
        return getPath();
    }

    public Boolean getExists() {
        return MemoryValue.bool(fields.get("exists"));
    }

    public Boolean exists() {
        return getExists();
    }

    public String getSourceFormat() {
        return MemoryValue.string(fields.get("sourceFormat"));
    }

    public String sourceFormat() {
        return getSourceFormat();
    }

    public String getStatus() {
        return MemoryValue.string(fields.get("status"));
    }

    public String status() {
        return getStatus();
    }

    public String getImportSupport() {
        return MemoryValue.string(fields.get("importSupport"));
    }

    public String importSupport() {
        return getImportSupport();
    }

    public Boolean getNativeImport() {
        return MemoryValue.bool(fields.get("nativeImport"));
    }

    public Boolean nativeImport() {
        return getNativeImport();
    }

    public Boolean getImportable() {
        return MemoryValue.bool(fields.get("importable"));
    }

    public Boolean importable() {
        return getImportable();
    }

    public String getRawRetention() {
        return MemoryValue.string(fields.get("rawRetention"));
    }

    public String rawRetention() {
        return getRawRetention();
    }

    public String getUnsupportedReason() {
        return MemoryValue.string(fields.get("unsupportedReason"));
    }

    public String unsupportedReason() {
        return getUnsupportedReason();
    }

    public Map<String, Object> asMap() {
        return fields;
    }
}
