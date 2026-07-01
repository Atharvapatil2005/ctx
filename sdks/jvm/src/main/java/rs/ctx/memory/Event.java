package rs.ctx.memory;

import java.util.List;
import java.util.Map;

/** A agent-history-v1 transcript event. */
public final class Event {
    private final Map<String, Object> fields;
    private final List<Citation> citations;

    Event(Map<String, Object> fields) {
        this.fields = MemoryValue.copyObject(fields);
        this.citations = MemoryValue.objectList(fields.get("citations"), Citation::new);
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

    public Integer getSequence() {
        return MemoryValue.integer(fields.get("sequence"));
    }

    public Integer sequence() {
        return getSequence();
    }

    public String getEventType() {
        return MemoryValue.string(fields.get("eventType"));
    }

    public String eventType() {
        return getEventType();
    }

    public String getRole() {
        return MemoryValue.string(fields.get("role"));
    }

    public String role() {
        return getRole();
    }

    public String getOccurredAt() {
        return MemoryValue.string(fields.get("occurredAt"));
    }

    public String occurredAt() {
        return getOccurredAt();
    }

    public String getSource() {
        return MemoryValue.string(fields.get("source"));
    }

    public String source() {
        return getSource();
    }

    public String getCursor() {
        return MemoryValue.string(fields.get("cursor"));
    }

    public String cursor() {
        return getCursor();
    }

    public String getText() {
        return MemoryValue.string(fields.get("text"));
    }

    public String text() {
        return getText();
    }

    public String getPreview() {
        return MemoryValue.string(fields.get("preview"));
    }

    public String preview() {
        return getPreview();
    }

    public String getRedactionState() {
        return MemoryValue.string(fields.get("redactionState"));
    }

    public String redactionState() {
        return getRedactionState();
    }

    public List<Citation> getCitations() {
        return citations;
    }

    public List<Citation> citations() {
        return citations;
    }

    public Map<String, Object> asMap() {
        return fields;
    }
}
