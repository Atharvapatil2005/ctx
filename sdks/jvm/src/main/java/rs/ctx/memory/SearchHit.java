package rs.ctx.memory;

import java.util.List;
import java.util.Map;

/** One memory search hit. */
public final class SearchHit {
    private final Map<String, Object> fields;
    private final List<String> whyMatched;
    private final List<Citation> citations;
    private final List<String> suggestedNextCommands;

    SearchHit(Map<String, Object> fields) {
        this.fields = MemoryValue.copyObject(fields);
        this.whyMatched = MemoryValue.stringList(fields.get("whyMatched"));
        this.citations = MemoryValue.objectList(fields.get("citations"), Citation::new);
        this.suggestedNextCommands = MemoryValue.stringList(fields.get("suggestedNextCommands"));
    }

    public String getCtxEventId() {
        return MemoryValue.string(fields.get("ctxEventId"));
    }

    public String ctxEventId() {
        return getCtxEventId();
    }

    public String getCtxSessionId() {
        return MemoryValue.string(fields.get("ctxSessionId"));
    }

    public String ctxSessionId() {
        return getCtxSessionId();
    }

    public String getProviderSessionId() {
        return MemoryValue.string(fields.get("providerSessionId"));
    }

    public String providerSessionId() {
        return getProviderSessionId();
    }

    public Integer getEventSeq() {
        return MemoryValue.integer(fields.get("eventSeq"));
    }

    public Integer eventSeq() {
        return getEventSeq();
    }

    public String getTitle() {
        return MemoryValue.string(fields.get("title"));
    }

    public String title() {
        return getTitle();
    }

    public String getSnippet() {
        return MemoryValue.string(fields.get("snippet"));
    }

    public String snippet() {
        return getSnippet();
    }

    public Double getRank() {
        return MemoryValue.doubleValue(fields.get("rank"));
    }

    public Double rank() {
        return getRank();
    }

    public String getResultScope() {
        return MemoryValue.string(fields.get("resultScope"));
    }

    public String resultScope() {
        return getResultScope();
    }

    public String getProvider() {
        return MemoryValue.string(fields.get("provider"));
    }

    public String provider() {
        return getProvider();
    }

    public String getTimestamp() {
        return MemoryValue.string(fields.get("timestamp"));
    }

    public String timestamp() {
        return getTimestamp();
    }

    public String getCwd() {
        return MemoryValue.string(fields.get("cwd"));
    }

    public String cwd() {
        return getCwd();
    }

    public String getSourcePath() {
        return MemoryValue.string(fields.get("sourcePath"));
    }

    public String sourcePath() {
        return getSourcePath();
    }

    public Boolean getSourceExists() {
        return MemoryValue.bool(fields.get("sourceExists"));
    }

    public Boolean sourceExists() {
        return getSourceExists();
    }

    public String getCursor() {
        return MemoryValue.string(fields.get("cursor"));
    }

    public String cursor() {
        return getCursor();
    }

    public List<String> getWhyMatched() {
        return whyMatched;
    }

    public List<String> whyMatched() {
        return whyMatched;
    }

    public List<Citation> getCitations() {
        return citations;
    }

    public List<Citation> citations() {
        return citations;
    }

    public List<String> getSuggestedNextCommands() {
        return suggestedNextCommands;
    }

    public List<String> suggestedNextCommands() {
        return suggestedNextCommands;
    }

    public String getVisibility() {
        return MemoryValue.string(fields.get("visibility"));
    }

    public String visibility() {
        return getVisibility();
    }

    public Map<String, Object> asMap() {
        return fields;
    }
}
