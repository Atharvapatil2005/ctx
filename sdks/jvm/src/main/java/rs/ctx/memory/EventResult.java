package rs.ctx.memory;

import java.util.List;
import java.util.Map;

/** Show-event payload containing the selected event and window. */
public final class EventResult {
    private final Map<String, Object> fields;
    private final Event event;
    private final List<Event> events;
    private final SourceLocation source;

    EventResult(Map<String, Object> fields) {
        this.fields = MemoryValue.copyObject(fields);
        Map<String, Object> eventFields = MemoryValue.objectAtOrNull(fields, "event");
        this.event = eventFields == null ? null : new Event(eventFields);
        this.events = MemoryValue.objectList(fields.get("events"), Event::new);
        this.source = SourceLocation.from(fields.get("source"));
    }

    static EventResult from(Object value) {
        return new EventResult(MemoryValue.object(value));
    }

    public Event getEvent() {
        return event;
    }

    public Event event() {
        return event;
    }

    public List<Event> getEvents() {
        return events;
    }

    public List<Event> events() {
        return events;
    }

    public SourceLocation getSource() {
        return source;
    }

    public SourceLocation source() {
        return source;
    }

    public Map<String, Object> asMap() {
        return fields;
    }
}
