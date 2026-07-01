package rs.ctx.memory;

import java.util.Map;

/** Source citation attached to search hits and events. */
public final class Citation {
    private final Map<String, Object> fields;

    Citation(Map<String, Object> fields) {
        this.fields = MemoryValue.copyObject(fields);
    }

    public String getItemId() {
        return MemoryValue.string(fields.get("itemId"));
    }

    public String itemId() {
        return getItemId();
    }

    public String getItemType() {
        return MemoryValue.string(fields.get("itemType"));
    }

    public String itemType() {
        return getItemType();
    }

    public String getCtxEventId() {
        return MemoryValue.string(fields.get("ctxEventId"));
    }

    public String ctxEventId() {
        return getCtxEventId();
    }

    public String getCtxSessionId() {
        return MemoryValue.string(fields.get("ctxSessionId"));
    }

    public String ctxSessionId() {
        return getCtxSessionId();
    }

    public String getLabel() {
        return MemoryValue.string(fields.get("label"));
    }

    public String label() {
        return getLabel();
    }

    public String getTime() {
        return MemoryValue.string(fields.get("time"));
    }

    public String time() {
        return getTime();
    }

    public String getProvider() {
        return MemoryValue.string(fields.get("provider"));
    }

    public String provider() {
        return getProvider();
    }

    public String getSessionId() {
        return MemoryValue.string(fields.get("sessionId"));
    }

    public String sessionId() {
        return getSessionId();
    }

    public Integer getEventSeq() {
        return MemoryValue.integer(fields.get("eventSeq"));
    }

    public Integer eventSeq() {
        return getEventSeq();
    }

    public String getSourcePath() {
        return MemoryValue.string(fields.get("sourcePath"));
    }

    public String sourcePath() {
        return getSourcePath();
    }

    public Boolean getSourceExists() {
        return MemoryValue.bool(fields.get("sourceExists"));
    }

    public Boolean sourceExists() {
        return getSourceExists();
    }

    public String getCursor() {
        return MemoryValue.string(fields.get("cursor"));
    }

    public String cursor() {
        return getCursor();
    }

    public Map<String, Object> asMap() {
        return fields;
    }
}
