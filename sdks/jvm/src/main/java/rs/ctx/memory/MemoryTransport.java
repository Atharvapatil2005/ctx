package rs.ctx.memory;

/** Transport for memory-v1 operations. */
public interface MemoryTransport {
    String name();

    String execute(MemoryOperation operation);

    default String ctxVersion() {
        return null;
    }
}

