package rs.ctx.memory;

import java.util.Map;

/** Response returned by {@link MemoryClient#showEvent(String, MemoryOptions.ShowEvent)}. */
public final class ShowEventResponse extends MemoryEnvelope {
    private final EventResult event;

    ShowEventResponse(Map<String, Object> canonical) {
        super(canonical);
        this.event = EventResult.from(payload("event"));
    }

    public EventResult getEvent() {
        return event;
    }

    public EventResult event() {
        return event;
    }
}
