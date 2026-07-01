package rs.ctx.memory;

/** Transport for agent-history-v1 operations. */
public interface MemoryTransport {
    String name();

    String execute(MemoryOperation operation);

    default String ctxVersion() {
        return null;
    }
}

