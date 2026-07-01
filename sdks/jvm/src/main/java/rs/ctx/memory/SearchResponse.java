package rs.ctx.memory;

import java.util.Map;

/** Response returned by {@link MemoryClient#search(MemoryOptions.Search)}. */
public final class SearchResponse extends MemoryEnvelope {
    private final SearchResult search;

    SearchResponse(Map<String, Object> canonical) {
        super(canonical);
        this.search = SearchResult.from(payload("search"));
    }

    public SearchResult getSearch() {
        return search;
    }

    public SearchResult search() {
        return search;
    }
}
