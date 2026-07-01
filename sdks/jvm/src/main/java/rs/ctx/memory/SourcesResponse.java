package rs.ctx.memory;

import java.util.List;
import java.util.Map;

/** Response returned by {@link MemoryClient#sources()}. */
public final class SourcesResponse extends MemoryEnvelope {
    private final List<ProviderSource> sources;

    SourcesResponse(Map<String, Object> canonical) {
        super(canonical);
        this.sources = MemoryValue.objectList(payload("sources"), ProviderSource::new);
    }

    public List<ProviderSource> getSources() {
        return sources;
    }

    public List<ProviderSource> sources() {
        return sources;
    }
}
