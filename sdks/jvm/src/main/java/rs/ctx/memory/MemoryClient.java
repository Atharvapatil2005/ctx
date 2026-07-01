package rs.ctx.memory;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

public class MemoryClient {
    private final MemoryTransport transport;

    protected MemoryClient(MemoryTransport transport) {
        this.transport = transport;
    }

    public static MemoryClient local() {
        return local(LocalCliConfig.builder().build());
    }

    public static MemoryClient local(LocalCliConfig config) {
        return new MemoryClient(new LocalCliAdapter(config));
    }

    public static HostedMemoryClient hosted(HostedConfig config) {
        return new HostedMemoryClient(config);
    }

    public static MemoryClient withTransport(MemoryTransport transport) {
        return new MemoryClient(Objects.requireNonNull(transport, "transport"));
    }

    public StatusResponse status() {
        return new StatusResponse(executeEnvelope("status", list("status", "--json")));
    }

    public InitResponse init() {
        return init(MemoryOptions.init());
    }

    public InitResponse init(MemoryOptions.Init options) {
        MemoryOptions.Init safe = options == null ? MemoryOptions.init() : options;
        List<String> args = mutable("setup", "--json");
        if (safe.progress() != null) {
            args.add("--progress");
            args.add(safe.progress());
        } else {
            args.add("--progress");
            args.add("none");
        }
        if (safe.catalogOnly()) {
            args.add("--catalog-only");
        }
        return new InitResponse(executeEnvelope("init", args));
    }

    public SourcesResponse sources() {
        return new SourcesResponse(executeEnvelope("sources", list("sources", "--json")));
    }

    public ImportResponse importMemory() {
        return importMemory(MemoryOptions.importMemory());
    }

    public ImportResponse importMemory(MemoryOptions.ImportMemory options) {
        return new ImportResponse(executeEnvelope("import", importArgs(options)));
    }

    public ImportResponse sync() {
        return sync(MemoryOptions.importMemory());
    }

    public ImportResponse sync(MemoryOptions.ImportMemory options) {
        return new ImportResponse(executeEnvelope("sync", importArgs(options)));
    }

    public SearchResponse search() {
        return search(MemoryOptions.search());
    }

    public SearchResponse search(String query) {
        return search(MemoryOptions.search().query(query));
    }

    public SearchResponse search(MemoryOptions.Search options) {
        MemoryOptions.Search safe = options == null ? MemoryOptions.search() : options;
        List<String> args = new ArrayList<>();
        args.add("search");
        if (safe.query() != null && !safe.query().isEmpty()) {
            args.add(safe.query());
        }
        args.add("--json");
        if (safe.limit() != null) {
            args.add("--limit");
            args.add(String.valueOf(safe.limit()));
        }
        for (String term : safe.terms()) {
            args.add("--term");
            args.add(term);
        }
        add(args, "--provider", safe.provider());
        add(args, "--workspace", safe.workspace());
        add(args, "--since", safe.since());
        add(args, "--event-type", safe.eventType());
        add(args, "--file", safe.file());
        add(args, "--session", safe.session());
        add(args, "--refresh", safe.refresh());
        if (safe.primaryOnly()) args.add("--primary-only");
        if (safe.includeSubagents()) args.add("--include-subagents");
        if (safe.events()) args.add("--events");
        if (safe.includeCurrentSession()) args.add("--include-current-session");
        return new SearchResponse(executeEnvelope("search", args));
    }

    public ShowEventResponse showEvent(String id, MemoryOptions.ShowEvent options) {
        if (id == null || id.isEmpty()) {
            throw new CtxMemoryException.Validation("event id is required");
        }
        MemoryOptions.ShowEvent safe = options == null ? MemoryOptions.showEvent() : options;
        List<String> args = mutable("show", "event", id, "--format", "json");
        addInt(args, "--before", safe.before());
        addInt(args, "--after", safe.after());
        addInt(args, "--window", safe.window());
        return new ShowEventResponse(executeEnvelope("showEvent", args));
    }

    public ShowEventResponse showEvent(String id) {
        return showEvent(id, MemoryOptions.showEvent());
    }

    public ShowSessionResponse showSession(String id, MemoryOptions.ShowSession options) {
        MemoryOptions.ShowSession safe = options == null ? MemoryOptions.showSession() : options;
        String sessionId = id == null ? safe.id() : id;
        List<String> args = mutable("show", "session");
        if (sessionId != null && !sessionId.isEmpty()) {
            args.add(sessionId);
        } else {
            add(args, "--provider", safe.provider());
            add(args, "--provider-session", safe.providerSessionId());
        }
        add(args, "--mode", safe.mode());
        args.add("--format");
        args.add("json");
        return new ShowSessionResponse(executeEnvelope("showSession", args));
    }

    public ShowSessionResponse showSession(String id) {
        return showSession(id, MemoryOptions.showSession());
    }

    public LocateEventResponse locateEvent(String id) {
        if (id == null || id.isEmpty()) {
            throw new CtxMemoryException.Validation("event id is required");
        }
        return new LocateEventResponse(executeEnvelope("locateEvent", list("locate", "event", id, "--format", "json")));
    }

    public LocateSessionResponse locateSession(String id) {
        return locateSession(MemoryOptions.locateSession().id(id));
    }

    public LocateSessionResponse locateSession(MemoryOptions.LocateSession options) {
        MemoryOptions.LocateSession safe = options == null ? MemoryOptions.locateSession() : options;
        List<String> args = mutable("locate", "session");
        if (safe.id() != null && !safe.id().isEmpty()) {
            args.add(safe.id());
        } else {
            add(args, "--provider", safe.provider());
            add(args, "--provider-session", safe.providerSessionId());
        }
        args.add("--format");
        args.add("json");
        return new LocateSessionResponse(executeEnvelope("locateSession", args));
    }

    public VersionInfo version() {
        return new VersionInfo(transport.name(), transport.ctxVersion());
    }

    public Map<String, Object> versioning() {
        return version().asMap();
    }

    protected MemoryEnvelope execute(String operation, List<String> args) {
        return new MemoryEnvelope(executeEnvelope(operation, args));
    }

    protected Map<String, Object> executeEnvelope(String operation, List<String> args) {
        String stdout = transport.execute(new MemoryOperation(operation, args));
        Map<String, Object> raw;
        try {
            raw = Json.parseObject(stdout);
        } catch (RuntimeException error) {
            Map<String, Object> details = new LinkedHashMap<>();
            details.put("operation", operation);
            details.put("stdout", stdout);
            throw new CtxMemoryException.Protocol("ctx command returned invalid JSON", details, error);
        }
        return MemoryEnvelope.normalize(operation, backend(), raw);
    }

    protected Backend backend() {
        if (transport.name().startsWith("hosted")) {
            return new Backend("hosted", null, null);
        }
        String dataRoot = null;
        if (transport instanceof LocalCliAdapter) {
            dataRoot = ((LocalCliAdapter) transport).config().dataRoot();
        }
        return new Backend("local", dataRoot, null);
    }

    private static List<String> importArgs(MemoryOptions.ImportMemory options) {
        MemoryOptions.ImportMemory safe = options == null ? MemoryOptions.importMemory() : options;
        List<String> args = mutable("import", "--json");
        if (safe.progress() != null) {
            args.add("--progress");
            args.add(safe.progress());
        } else {
            args.add("--progress");
            args.add("none");
        }
        if (safe.all()) args.add("--all");
        add(args, "--provider", safe.provider());
        add(args, "--path", safe.path());
        if (safe.resume()) args.add("--resume");
        return args;
    }

    private static void add(List<String> args, String flag, String value) {
        if (value != null && !value.isEmpty()) {
            args.add(flag);
            args.add(value);
        }
    }

    private static void addInt(List<String> args, String flag, Integer value) {
        if (value != null) {
            args.add(flag);
            args.add(String.valueOf(value));
        }
    }

    private static List<String> list(String... values) {
        List<String> out = mutable(values);
        return Collections.unmodifiableList(out);
    }

    private static List<String> mutable(String... values) {
        List<String> out = new ArrayList<>();
        Collections.addAll(out, values);
        return out;
    }
}
