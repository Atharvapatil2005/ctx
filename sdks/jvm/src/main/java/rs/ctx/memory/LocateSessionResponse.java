package rs.ctx.memory;

import java.util.Map;

/** Response returned by locate-session operations. */
public final class LocateSessionResponse extends MemoryEnvelope {
    private final LocationResult location;

    LocateSessionResponse(Map<String, Object> canonical) {
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
