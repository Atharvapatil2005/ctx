package rs.ctx.memory;

import java.util.Map;

/** Response returned by import and sync operations. */
public final class ImportResponse extends MemoryEnvelope {
    private final ImportResult importResult;

    ImportResponse(Map<String, Object> canonical) {
        super(canonical);
        this.importResult = ImportResult.from(payload("import"));
    }

    public ImportResult getImportResult() {
        return importResult;
    }

    public ImportResult getImport() {
        return importResult;
    }

    public ImportResult importResult() {
        return importResult;
    }
}
