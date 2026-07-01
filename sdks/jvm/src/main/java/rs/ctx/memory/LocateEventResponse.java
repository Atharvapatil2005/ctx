package rs.ctx.memory;

import java.util.Map;

/** Response returned by {@link MemoryClient#locateEvent(String)}. */
public final class LocateEventResponse extends MemoryEnvelope {
    private final LocationResult location;

    LocateEventResponse(Map<String, Object> canonical) {
        super(canonical);
        this.location = LocationResult.from(payload("location"));
    }

    public LocationResult getLocation() {
        return location;
    }

    public LocationResult location() {
        return location;
    }
}
