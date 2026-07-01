package rs.ctx.memory;

import java.util.List;
import java.util.Map;

/** Search operation payload. */
public final class SearchResult {
    private final Map<String, Object> fields;
    private final SearchFilters filters;
    private final Freshness freshness;
    private final List<SearchHit> results;
    private final SearchPagination pagination;
    private final SearchTruncation truncation;

    SearchResult(Map<String, Object> fields) {
        this.fields = MemoryValue.copyObject(fields);
        this.filters = SearchFilters.from(fields.get("filters"));
        this.freshness = Freshness.from(fields.get("freshness"));
        this.results = MemoryValue.objectList(fields.get("results"), SearchHit::new);
        this.pagination = SearchPagination.from(fields.get("pagination"));
        this.truncation = SearchTruncation.from(fields.get("truncation"));
    }

    static SearchResult from(Object value) {
        return new SearchResult(MemoryValue.object(value));
    }

    public String getQuery() {
        return MemoryValue.string(fields.get("query"));
    }

    public String query() {
        return getQuery();
    }

    public SearchFilters getFilters() {
        return filters;
    }

    public SearchFilters filters() {
        return filters;
    }

    public Freshness getFreshness() {
        return freshness;
    }

    public Freshness freshness() {
        return freshness;
    }

    public String getGeneratedAt() {
        return MemoryValue.string(fields.get("generatedAt"));
    }

    public String generatedAt() {
        return getGeneratedAt();
    }

    public List<SearchHit> getResults() {
        return results;
    }

    public List<SearchHit> results() {
        return results;
    }

    public SearchPagination getPagination() {
        return pagination;
    }

    public SearchPagination pagination() {
        return pagination;
    }

    public SearchTruncation getTruncation() {
        return truncation;
    }

    public SearchTruncation truncation() {
        return truncation;
    }

    public Map<String, Object> asMap() {
        return fields;
    }
}
