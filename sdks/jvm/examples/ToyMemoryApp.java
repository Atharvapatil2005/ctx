import java.util.LinkedHashMap;
import java.util.Map;
import rs.ctx.memory.LocateEventResponse;
import rs.ctx.memory.MemoryClient;
import rs.ctx.memory.MemoryOperation;
import rs.ctx.memory.MemoryOptions;
import rs.ctx.memory.MemoryTransport;
import rs.ctx.memory.SearchResponse;
import rs.ctx.memory.ShowEventResponse;
import rs.ctx.memory.StatusResponse;

public final class ToyMemoryApp {
    public static void main(String[] args) {
        MemoryClient client = MemoryClient.withTransport(new FakeMemoryTransport());

        StatusResponse status = client.status();
        SearchResponse search = client.search(MemoryOptions.search()
                .query("local memory")
                .provider("codex")
                .refresh("off")
                .limit(Integer.valueOf(5)));
        ShowEventResponse shown = client.showEvent("evt-toy-1", MemoryOptions.showEvent().window(Integer.valueOf(1)));
        LocateEventResponse located = client.locateEvent("evt-toy-1");

        System.out.println("status.initialized=" + status.getStatus().getInitialized());
        System.out.println("search.results=" + search.getSearch().getResults().size());
        System.out.println("show.event=" + shown.getEvent().getEvent().getCtxEventId());
        System.out.println("locate.path=" + located.getLocation().getSource().getPath());
    }

    private static final class FakeMemoryTransport implements MemoryTransport {
        private final Map<String, String> responses = new LinkedHashMap<>();

        FakeMemoryTransport() {
            responses.put("status", "{"
                    + "\"schema_version\":1,"
                    + "\"initialized\":true,"
                    + "\"local_only\":true,"
                    + "\"indexed_items\":1,"
                    + "\"indexed_sources\":1"
                    + "}");
            responses.put("search", "{"
                    + "\"query\":\"local memory\","
                    + "\"filters\":{\"provider\":\"codex\"},"
                    + "\"freshness\":{\"mode\":\"off\",\"status\":\"skipped\",\"source_count\":0},"
                    + "\"results\":[{"
                    + "\"ctx_event_id\":\"evt-toy-1\","
                    + "\"ctx_session_id\":\"ses-toy-1\","
                    + "\"result_scope\":\"event\","
                    + "\"provider\":\"codex\","
                    + "\"snippet\":\"toy local memory result\","
                    + "\"citations\":[{\"label\":\"toy event\",\"ctx_event_id\":\"evt-toy-1\"}]"
                    + "}],"
                    + "\"pagination\":{\"limit\":5},"
                    + "\"truncation\":{\"truncated\":false}"
                    + "}");
            responses.put("showEvent", "{"
                    + "\"event\":{\"ctx_event_id\":\"evt-toy-1\",\"ctx_session_id\":\"ses-toy-1\","
                    + "\"sequence\":1,\"event_type\":\"message\",\"role\":\"assistant\","
                    + "\"source\":\"codex\",\"text\":\"toy local memory result\"},"
                    + "\"events\":[{\"ctx_event_id\":\"evt-toy-1\",\"ctx_session_id\":\"ses-toy-1\",\"sequence\":1}],"
                    + "\"source\":{\"path\":\"/tmp/ctx-jvm-toy/session.jsonl\",\"cursor\":\"line:1\",\"exists\":false}"
                    + "}");
            responses.put("locateEvent", "{"
                    + "\"ctx_session_id\":\"ses-toy-1\","
                    + "\"ctx_event_id\":\"evt-toy-1\","
                    + "\"provider\":\"codex\","
                    + "\"provider_session_id\":\"provider-toy-1\","
                    + "\"source\":{\"path\":\"/tmp/ctx-jvm-toy/session.jsonl\",\"cursor\":\"line:1\",\"exists\":false},"
                    + "\"resume\":{\"cursor\":\"line:1\"}"
                    + "}");
        }

        @Override
        public String name() {
            return "local-fake";
        }

        @Override
        public String execute(MemoryOperation operation) {
            String response = responses.get(operation.name());
            if (response == null) {
                throw new IllegalArgumentException("unsupported toy operation: " + operation.name());
            }
            return response;
        }
    }
}
