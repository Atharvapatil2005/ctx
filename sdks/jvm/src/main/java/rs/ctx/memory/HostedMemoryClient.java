package rs.ctx.memory;

import java.util.LinkedHashMap;
import java.util.Map;

/** Explicit hosted placeholder. It never performs network calls. */
public final class HostedMemoryClient extends MemoryClient {
    private final HostedConfig config;

    public HostedMemoryClient(HostedConfig config) {
        super(new HostedTransport(config));
        this.config = config == null ? HostedConfig.builder().build() : config;
    }

    public HostedConfig config() {
        return config;
    }

    @Override
    protected Backend backend() {
        return new Backend("hosted", null, config.baseUrl());
    }

    private static final class HostedTransport implements MemoryTransport {
        private final HostedConfig config;

        HostedTransport(HostedConfig config) {
            this.config = config == null ? HostedConfig.builder().build() : config;
        }

        @Override
        public String name() {
            return "hosted-placeholder";
        }

        @Override
        public String execute(MemoryOperation operation) {
            Map<String, Object> details = new LinkedHashMap<>();
            details.put("backend", "hosted");
            details.put("baseUrl", config.baseUrl());
            details.put("operation", operation.name());
            throw new CtxMemoryException.Unsupported(
                    "hosted ctx memory backend is not available in this in-repo SDK",
                    details);
        }
    }
}
