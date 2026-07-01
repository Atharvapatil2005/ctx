package rs.ctx.memory;

import java.util.Map;

/** Search pagination metadata. */
public final class SearchPagination {
    private final Map<String, Object> fields;

    SearchPagination(Map<String, Object> fields) {
        this.fields = MemoryValue.copyObject(fields);
    }

    static SearchPagination from(Object value) {
        Map<String, Object> fields = MemoryValue.objectOrNull(value);
        return fields == null ? null : new SearchPagination(fields);
    }

    public Integer getLimit() {
        return MemoryValue.integer(fields.get("limit"));
    }

    public Integer limit() {
        return getLimit();
    }

    public Integer getOffset() {
        return MemoryValue.integer(fields.get("offset"));
    }

    public Integer offset() {
        return getOffset();
    }

    public Integer getTotal() {
        return MemoryValue.integer(fields.get("total"));
    }

    public Integer total() {
        return getTotal();
    }

    public String getNextCursor() {
        return MemoryValue.string(fields.get("nextCursor"));
    }

    public String nextCursor() {
        return getNextCursor();
    }

    public Boolean getHasMore() {
        return MemoryValue.bool(fields.get("hasMore"));
    }

    public Boolean hasMore() {
        return getHasMore();
    }

    public Map<String, Object> asMap() {
        return fields;
    }
}
