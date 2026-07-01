import Foundation

public let MEMORY_V1_VERSION = "memory-v1"
public let CTX_MEMORY_SWIFT_SDK_VERSION = "0.0.0"
public let MEMORY_V1_SCHEMA_VERSION = 1

public enum MemoryOperation: String, Codable, Sendable {
    case status
    case initialize = "init"
    case sources
    case importMemory = "import"
    case sync
    case search
    case showEvent
    case showSession
    case locateEvent
    case locateSession
    case error
}

public enum MemoryBackendKind: Equatable, Sendable, Codable, CustomStringConvertible {
    case local
    case hosted
    case other(String)

    public init(rawValue: String) {
        switch rawValue {
        case "local":
            self = .local
        case "hosted":
            self = .hosted
        default:
            self = .other(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .local:
            return "local"
        case .hosted:
            return "hosted"
        case let .other(value):
            return value
        }
    }

    public var description: String {
        rawValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct MemoryBackend: Codable, Equatable, Sendable {
    public var kind: MemoryBackendKind
    public var dataRoot: String?
    public var baseURL: String?

    public init(kind: MemoryBackendKind, dataRoot: String? = nil, baseURL: String? = nil) {
        self.kind = kind
        self.dataRoot = dataRoot
        self.baseURL = baseURL
    }

    public init(kind: String, dataRoot: String? = nil, baseURL: String? = nil) {
        self.init(kind: MemoryBackendKind(rawValue: kind), dataRoot: dataRoot, baseURL: baseURL)
    }

    enum CodingKeys: String, CodingKey {
        case kind
        case dataRoot
        case baseURL = "baseUrl"
    }
}

public struct MemoryEnvelope: Codable, Equatable, Sendable {
    public var contractVersion: String
    public var schemaVersion: Int
    public var operation: MemoryOperation
    public var backend: MemoryBackend?
    public var status: MemoryStatus?
    public var sources: [ProviderSource]?
    public var importResult: MemoryImportResult?
    public var search: MemorySearchResult?
    public var event: MemoryEventResult?
    public var session: MemorySessionResult?
    public var location: MemoryLocationResult?
    public var error: MemoryContractError?

    public init(
        contractVersion: String = MEMORY_V1_VERSION,
        schemaVersion: Int = MEMORY_V1_SCHEMA_VERSION,
        operation: MemoryOperation,
        backend: MemoryBackend? = nil,
        status: MemoryStatus? = nil,
        sources: [ProviderSource]? = nil,
        importResult: MemoryImportResult? = nil,
        search: MemorySearchResult? = nil,
        event: MemoryEventResult? = nil,
        session: MemorySessionResult? = nil,
        location: MemoryLocationResult? = nil,
        error: MemoryContractError? = nil
    ) {
        self.contractVersion = contractVersion
        self.schemaVersion = schemaVersion
        self.operation = operation
        self.backend = backend
        self.status = status
        self.sources = sources
        self.importResult = importResult
        self.search = search
        self.event = event
        self.session = session
        self.location = location
        self.error = error
    }

    enum CodingKeys: String, CodingKey {
        case contractVersion
        case schemaVersion
        case operation
        case backend
        case status
        case sources
        case importResult = "import"
        case search
        case event
        case session
        case location
        case error
    }
}

public struct StatusResponse: Equatable, Sendable {
    public var envelope: MemoryEnvelope
    public var status: MemoryStatus

    public init(envelope: MemoryEnvelope) throws {
        guard let status = envelope.status else {
            throw missingPayload("status", operation: envelope.operation)
        }
        self.envelope = envelope
        self.status = status
    }
}

public struct InitResponse: Equatable, Sendable {
    public var envelope: MemoryEnvelope
    public var status: MemoryStatus

    public init(envelope: MemoryEnvelope) throws {
        guard let status = envelope.status else {
            throw missingPayload("status", operation: envelope.operation)
        }
        self.envelope = envelope
        self.status = status
    }
}

public struct SourcesResponse: Equatable, Sendable {
    public var envelope: MemoryEnvelope
    public var sources: [ProviderSource]

    public init(envelope: MemoryEnvelope) throws {
        guard let sources = envelope.sources else {
            throw missingPayload("sources", operation: envelope.operation)
        }
        self.envelope = envelope
        self.sources = sources
    }
}

public struct ImportResponse: Equatable, Sendable {
    public var envelope: MemoryEnvelope
    public var importResult: MemoryImportResult

    public init(envelope: MemoryEnvelope) throws {
        guard let importResult = envelope.importResult else {
            throw missingPayload("import", operation: envelope.operation)
        }
        self.envelope = envelope
        self.importResult = importResult
    }
}

public struct SearchResponse: Equatable, Sendable {
    public var envelope: MemoryEnvelope
    public var search: MemorySearchResult

    public init(envelope: MemoryEnvelope) throws {
        guard let search = envelope.search else {
            throw missingPayload("search", operation: envelope.operation)
        }
        self.envelope = envelope
        self.search = search
    }
}

public struct ShowEventResponse: Equatable, Sendable {
    public var envelope: MemoryEnvelope
    public var event: MemoryEventResult

    public init(envelope: MemoryEnvelope) throws {
        guard let event = envelope.event else {
            throw missingPayload("event", operation: envelope.operation)
        }
        self.envelope = envelope
        self.event = event
    }
}

public struct ShowSessionResponse: Equatable, Sendable {
    public var envelope: MemoryEnvelope
    public var session: MemorySessionResult

    public init(envelope: MemoryEnvelope) throws {
        guard let session = envelope.session else {
            throw missingPayload("session", operation: envelope.operation)
        }
        self.envelope = envelope
        self.session = session
    }
}

public struct LocateEventResponse: Equatable, Sendable {
    public var envelope: MemoryEnvelope
    public var location: MemoryLocationResult

    public init(envelope: MemoryEnvelope) throws {
        guard let location = envelope.location else {
            throw missingPayload("location", operation: envelope.operation)
        }
        self.envelope = envelope
        self.location = location
    }
}

public struct LocateSessionResponse: Equatable, Sendable {
    public var envelope: MemoryEnvelope
    public var location: MemoryLocationResult

    public init(envelope: MemoryEnvelope) throws {
        guard let location = envelope.location else {
            throw missingPayload("location", operation: envelope.operation)
        }
        self.envelope = envelope
        self.location = location
    }
}

private func missingPayload(_ payload: String, operation: MemoryOperation) -> CtxMemorySDKError {
    CtxMemorySDKError(
        code: .decodeError,
        message: "memory-v1 \(operation.rawValue) response did not contain \(payload) payload"
    )
}

public struct MemoryStatus: Codable, Equatable, Sendable {
    public var initialized: Bool
    public var localOnly: Bool
    public var dataRoot: String?
    public var indexedItems: Int?
    public var indexedSources: Int?
    public var catalogedSessions: Int?
    public var indexedCatalogSessions: Int?
    public var pendingCatalogSessions: Int?
    public var failedCatalogSessions: Int?
    public var staleCatalogSessions: Int?
    public var freshness: MemoryFreshness?

    public init(
        initialized: Bool,
        localOnly: Bool,
        dataRoot: String? = nil,
        indexedItems: Int? = nil,
        indexedSources: Int? = nil,
        catalogedSessions: Int? = nil,
        indexedCatalogSessions: Int? = nil,
        pendingCatalogSessions: Int? = nil,
        failedCatalogSessions: Int? = nil,
        staleCatalogSessions: Int? = nil,
        freshness: MemoryFreshness? = nil
    ) {
        self.initialized = initialized
        self.localOnly = localOnly
        self.dataRoot = dataRoot
        self.indexedItems = indexedItems
        self.indexedSources = indexedSources
        self.catalogedSessions = catalogedSessions
        self.indexedCatalogSessions = indexedCatalogSessions
        self.pendingCatalogSessions = pendingCatalogSessions
        self.failedCatalogSessions = failedCatalogSessions
        self.staleCatalogSessions = staleCatalogSessions
        self.freshness = freshness
    }
}

public struct ProviderSource: Codable, Equatable, Sendable {
    public var provider: String
    public var path: String
    public var exists: Bool?
    public var sourceFormat: String?
    public var status: String
    public var importSupport: String?
    public var nativeImport: Bool?
    public var importable: Bool
    public var rawRetention: String?
    public var unsupportedReason: String?

    public init(
        provider: String,
        path: String,
        exists: Bool? = nil,
        sourceFormat: String? = nil,
        status: String,
        importSupport: String? = nil,
        nativeImport: Bool? = nil,
        importable: Bool,
        rawRetention: String? = nil,
        unsupportedReason: String? = nil
    ) {
        self.provider = provider
        self.path = path
        self.exists = exists
        self.sourceFormat = sourceFormat
        self.status = status
        self.importSupport = importSupport
        self.nativeImport = nativeImport
        self.importable = importable
        self.rawRetention = rawRetention
        self.unsupportedReason = unsupportedReason
    }
}

public struct MemoryImportResult: Codable, Equatable, Sendable {
    public var resume: Bool
    public var resumeMode: String?
    public var totals: MemoryTotals
    public var sources: [JSONValue]

    public init(
        resume: Bool,
        resumeMode: String? = nil,
        totals: MemoryTotals = MemoryTotals(),
        sources: [JSONValue] = []
    ) {
        self.resume = resume
        self.resumeMode = resumeMode
        self.totals = totals
        self.sources = sources
    }

    enum CodingKeys: String, CodingKey {
        case resume
        case resumeMode
        case totals
        case sources
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resume = try container.decode(Bool.self, forKey: .resume)
        resumeMode = try container.decodeIfPresent(String.self, forKey: .resumeMode)
        totals = try container.decodeIfPresent(MemoryTotals.self, forKey: .totals) ?? MemoryTotals()
        sources = try container.decodeIfPresent([JSONValue].self, forKey: .sources) ?? []
    }
}

public struct MemorySearchResult: Codable, Equatable, Sendable {
    public var query: String?
    public var filters: JSONValue?
    public var freshness: MemoryFreshness?
    public var generatedAt: String?
    public var results: [MemorySearchHit]
    public var pagination: MemoryPagination?
    public var truncation: MemoryTruncation?

    public init(
        query: String? = nil,
        filters: JSONValue? = nil,
        freshness: MemoryFreshness? = nil,
        generatedAt: String? = nil,
        results: [MemorySearchHit] = [],
        pagination: MemoryPagination? = nil,
        truncation: MemoryTruncation? = nil
    ) {
        self.query = query
        self.filters = filters
        self.freshness = freshness
        self.generatedAt = generatedAt
        self.results = results
        self.pagination = pagination
        self.truncation = truncation
    }

    enum CodingKeys: String, CodingKey {
        case query
        case filters
        case freshness
        case generatedAt
        case results
        case pagination
        case truncation
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        query = try container.decodeIfPresent(String.self, forKey: .query)
        filters = try container.decodeIfPresent(JSONValue.self, forKey: .filters)
        freshness = try container.decodeIfPresent(MemoryFreshness.self, forKey: .freshness)
        generatedAt = try container.decodeIfPresent(String.self, forKey: .generatedAt)
        results = try container.decodeIfPresent([MemorySearchHit].self, forKey: .results) ?? []
        pagination = try container.decodeIfPresent(MemoryPagination.self, forKey: .pagination)
        truncation = try container.decodeIfPresent(MemoryTruncation.self, forKey: .truncation)
    }
}

public struct MemorySearchHit: Codable, Equatable, Sendable {
    public var ctxEventId: String?
    public var ctxSessionId: String?
    public var providerSessionId: String?
    public var eventSeq: Int?
    public var title: String?
    public var snippet: String?
    public var rank: Double?
    public var resultScope: String
    public var provider: String?
    public var timestamp: String?
    public var cwd: String?
    public var sourcePath: String?
    public var sourceExists: Bool?
    public var cursor: String?
    public var whyMatched: [String]
    public var citations: [MemoryCitation]
    public var suggestedNextCommands: [String]
    public var visibility: String?

    public init(
        ctxEventId: String? = nil,
        ctxSessionId: String? = nil,
        providerSessionId: String? = nil,
        eventSeq: Int? = nil,
        title: String? = nil,
        snippet: String? = nil,
        rank: Double? = nil,
        resultScope: String,
        provider: String? = nil,
        timestamp: String? = nil,
        cwd: String? = nil,
        sourcePath: String? = nil,
        sourceExists: Bool? = nil,
        cursor: String? = nil,
        whyMatched: [String] = [],
        citations: [MemoryCitation] = [],
        suggestedNextCommands: [String] = [],
        visibility: String? = nil
    ) {
        self.ctxEventId = ctxEventId
        self.ctxSessionId = ctxSessionId
        self.providerSessionId = providerSessionId
        self.eventSeq = eventSeq
        self.title = title
        self.snippet = snippet
        self.rank = rank
        self.resultScope = resultScope
        self.provider = provider
        self.timestamp = timestamp
        self.cwd = cwd
        self.sourcePath = sourcePath
        self.sourceExists = sourceExists
        self.cursor = cursor
        self.whyMatched = whyMatched
        self.citations = citations
        self.suggestedNextCommands = suggestedNextCommands
        self.visibility = visibility
    }

    enum CodingKeys: String, CodingKey {
        case ctxEventId
        case ctxSessionId
        case providerSessionId
        case eventSeq
        case title
        case snippet
        case rank
        case resultScope
        case provider
        case timestamp
        case cwd
        case sourcePath
        case sourceExists
        case cursor
        case whyMatched
        case citations
        case suggestedNextCommands
        case visibility
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ctxEventId = try container.decodeIfPresent(String.self, forKey: .ctxEventId)
        ctxSessionId = try container.decodeIfPresent(String.self, forKey: .ctxSessionId)
        providerSessionId = try container.decodeIfPresent(String.self, forKey: .providerSessionId)
        eventSeq = try container.decodeIfPresent(Int.self, forKey: .eventSeq)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        snippet = try container.decodeIfPresent(String.self, forKey: .snippet)
        rank = try container.decodeIfPresent(Double.self, forKey: .rank)
        resultScope = try container.decodeIfPresent(String.self, forKey: .resultScope) ?? "unknown"
        provider = try container.decodeIfPresent(String.self, forKey: .provider)
        timestamp = try container.decodeIfPresent(String.self, forKey: .timestamp)
        cwd = try container.decodeIfPresent(String.self, forKey: .cwd)
        sourcePath = try container.decodeIfPresent(String.self, forKey: .sourcePath)
        sourceExists = try container.decodeIfPresent(Bool.self, forKey: .sourceExists)
        cursor = try container.decodeIfPresent(String.self, forKey: .cursor)
        whyMatched = try container.decodeIfPresent([String].self, forKey: .whyMatched) ?? []
        citations = try container.decodeIfPresent([MemoryCitation].self, forKey: .citations) ?? []
        suggestedNextCommands = try container.decodeIfPresent([String].self, forKey: .suggestedNextCommands) ?? []
        visibility = try container.decodeIfPresent(String.self, forKey: .visibility)
    }
}

public struct MemoryEventResult: Codable, Equatable, Sendable {
    public var event: MemoryEventRecord?
    public var events: [MemoryEventRecord]
    public var source: MemorySourceLocation?

    public init(event: MemoryEventRecord? = nil, events: [MemoryEventRecord] = [], source: MemorySourceLocation? = nil) {
        self.event = event
        self.events = events
        self.source = source
    }

    enum CodingKeys: String, CodingKey {
        case event
        case events
        case source
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        event = try container.decodeIfPresent(MemoryEventRecord.self, forKey: .event)
        events = try container.decodeIfPresent([MemoryEventRecord].self, forKey: .events) ?? []
        source = try container.decodeIfPresent(MemorySourceLocation.self, forKey: .source)
    }
}

public struct MemorySessionResult: Codable, Equatable, Sendable {
    public var session: MemorySessionSummary?
    public var events: [MemoryEventRecord]
    public var source: MemorySourceLocation?
    public var mode: String?
    public var format: String?

    public init(
        session: MemorySessionSummary? = nil,
        events: [MemoryEventRecord] = [],
        source: MemorySourceLocation? = nil,
        mode: String? = nil,
        format: String? = nil
    ) {
        self.session = session
        self.events = events
        self.source = source
        self.mode = mode
        self.format = format
    }

    enum CodingKeys: String, CodingKey {
        case session
        case events
        case source
        case mode
        case format
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        session = try container.decodeIfPresent(MemorySessionSummary.self, forKey: .session)
        events = try container.decodeIfPresent([MemoryEventRecord].self, forKey: .events) ?? []
        source = try container.decodeIfPresent(MemorySourceLocation.self, forKey: .source)
        mode = try container.decodeIfPresent(String.self, forKey: .mode)
        format = try container.decodeIfPresent(String.self, forKey: .format)
    }
}

public struct MemoryLocationResult: Codable, Equatable, Sendable {
    public var ctxSessionId: String
    public var ctxEventId: String?
    public var provider: String
    public var providerSessionId: String?
    public var source: MemorySourceLocation
    public var resume: MemoryResumeLocation?

    public init(
        ctxSessionId: String,
        ctxEventId: String? = nil,
        provider: String,
        providerSessionId: String? = nil,
        source: MemorySourceLocation,
        resume: MemoryResumeLocation? = nil
    ) {
        self.ctxSessionId = ctxSessionId
        self.ctxEventId = ctxEventId
        self.provider = provider
        self.providerSessionId = providerSessionId
        self.source = source
        self.resume = resume
    }
}

public struct MemoryEventRecord: Codable, Equatable, Sendable {
    public var ctxEventId: String?
    public var ctxSessionId: String?
    public var sequence: Int?
    public var eventType: String?
    public var role: String?
    public var occurredAt: String?
    public var source: String?
    public var cursor: String?
    public var text: String?
    public var preview: String?
    public var redactionState: String?
    public var citations: [MemoryCitation]?

    public init(
        ctxEventId: String? = nil,
        ctxSessionId: String? = nil,
        sequence: Int? = nil,
        eventType: String? = nil,
        role: String? = nil,
        occurredAt: String? = nil,
        source: String? = nil,
        cursor: String? = nil,
        text: String? = nil,
        preview: String? = nil,
        redactionState: String? = nil,
        citations: [MemoryCitation]? = nil
    ) {
        self.ctxEventId = ctxEventId
        self.ctxSessionId = ctxSessionId
        self.sequence = sequence
        self.eventType = eventType
        self.role = role
        self.occurredAt = occurredAt
        self.source = source
        self.cursor = cursor
        self.text = text
        self.preview = preview
        self.redactionState = redactionState
        self.citations = citations
    }
}

public struct MemorySessionSummary: Codable, Equatable, Sendable {
    public var ctxSessionId: String?
    public var provider: String?
    public var providerSessionId: String?
    public var title: String?

    public init(ctxSessionId: String? = nil, provider: String? = nil, providerSessionId: String? = nil, title: String? = nil) {
        self.ctxSessionId = ctxSessionId
        self.provider = provider
        self.providerSessionId = providerSessionId
        self.title = title
    }
}

public struct MemorySourceLocation: Codable, Equatable, Sendable {
    public var path: String?
    public var cursor: String?
    public var exists: Bool?
    public var sourceId: String?
    public var sourceFormat: String?

    public init(path: String? = nil, cursor: String? = nil, exists: Bool? = nil, sourceId: String? = nil, sourceFormat: String? = nil) {
        self.path = path
        self.cursor = cursor
        self.exists = exists
        self.sourceId = sourceId
        self.sourceFormat = sourceFormat
    }
}

public struct MemoryResumeLocation: Codable, Equatable, Sendable {
    public var cursor: String?

    public init(cursor: String? = nil) {
        self.cursor = cursor
    }
}

public struct MemoryFreshness: Codable, Equatable, Sendable {
    public var mode: String?
    public var status: String?
    public var sourceCount: Int?
    public var totals: MemoryTotals?
    public var error: String?

    public init(mode: String? = nil, status: String? = nil, sourceCount: Int? = nil, totals: MemoryTotals? = nil, error: String? = nil) {
        self.mode = mode
        self.status = status
        self.sourceCount = sourceCount
        self.totals = totals
        self.error = error
    }
}

public struct MemoryCitation: Codable, Equatable, Sendable {
    public var itemId: String?
    public var itemType: String?
    public var ctxEventId: String?
    public var ctxSessionId: String?
    public var label: String?
    public var time: String?
    public var provider: String?
    public var sessionId: String?
    public var eventSeq: Int?
    public var sourcePath: String?
    public var sourceExists: Bool?
    public var cursor: String?

    public init(
        itemId: String? = nil,
        itemType: String? = nil,
        ctxEventId: String? = nil,
        ctxSessionId: String? = nil,
        label: String? = nil,
        time: String? = nil,
        provider: String? = nil,
        sessionId: String? = nil,
        eventSeq: Int? = nil,
        sourcePath: String? = nil,
        sourceExists: Bool? = nil,
        cursor: String? = nil
    ) {
        self.itemId = itemId
        self.itemType = itemType
        self.ctxEventId = ctxEventId
        self.ctxSessionId = ctxSessionId
        self.label = label
        self.time = time
        self.provider = provider
        self.sessionId = sessionId
        self.eventSeq = eventSeq
        self.sourcePath = sourcePath
        self.sourceExists = sourceExists
        self.cursor = cursor
    }
}

public struct MemoryTotals: Codable, Equatable, Sendable {
    public var sourceFiles: Int?
    public var sourceBytes: Int?
    public var importedSources: Int?
    public var failedSources: Int?
    public var importedSessions: Int?
    public var importedEvents: Int?
    public var importedEdges: Int?
    public var skipped: Int?
    public var failed: Int?

    public init(
        sourceFiles: Int? = nil,
        sourceBytes: Int? = nil,
        importedSources: Int? = nil,
        failedSources: Int? = nil,
        importedSessions: Int? = nil,
        importedEvents: Int? = nil,
        importedEdges: Int? = nil,
        skipped: Int? = nil,
        failed: Int? = nil
    ) {
        self.sourceFiles = sourceFiles
        self.sourceBytes = sourceBytes
        self.importedSources = importedSources
        self.failedSources = failedSources
        self.importedSessions = importedSessions
        self.importedEvents = importedEvents
        self.importedEdges = importedEdges
        self.skipped = skipped
        self.failed = failed
    }
}

public struct MemoryPagination: Codable, Equatable, Sendable {
    public var limit: Int?

    public init(limit: Int? = nil) {
        self.limit = limit
    }
}

public struct MemoryTruncation: Codable, Equatable, Sendable {
    public var truncated: Bool?

    public init(truncated: Bool? = nil) {
        self.truncated = truncated
    }
}

public enum MemoryErrorCode: String, Sendable {
    case invalidRequest = "invalid_request"
    case notFound = "not_found"
    case notInitialized = "not_initialized"
    case backendUnavailable = "backend_unavailable"
    case timeout
    case cancelled
    case notSupported = "not_supported"
    case adapterError = "adapter_error"
    case decodeError = "decode_error"
    case unknown
}

extension MemoryErrorCode: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = MemoryErrorCode(rawValue: try container.decode(String.self)) ?? .unknown
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct MemoryContractError: Codable, Equatable, Sendable {
    public var code: MemoryErrorCode
    public var message: String
    public var retryable: Bool
    public var details: JSONValue?
    public var cause: String?

    public init(
        code: MemoryErrorCode,
        message: String,
        retryable: Bool = false,
        details: JSONValue? = nil,
        cause: String? = nil
    ) {
        self.code = code
        self.message = message
        self.retryable = retryable
        self.details = details
        self.cause = cause
    }
}

public struct VersionInfo: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var apiVersion: String
    public var sdkVersion: String
    public var adapter: String
    public var ctxVersion: String?
    public var hosted: Bool?

    public init(
        schemaVersion: Int = MEMORY_V1_SCHEMA_VERSION,
        apiVersion: String = MEMORY_V1_VERSION,
        sdkVersion: String = CTX_MEMORY_SWIFT_SDK_VERSION,
        adapter: String,
        ctxVersion: String? = nil,
        hosted: Bool? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.apiVersion = apiVersion
        self.sdkVersion = sdkVersion
        self.adapter = adapter
        self.ctxVersion = ctxVersion
        self.hosted = hosted
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case apiVersion = "api_version"
        case sdkVersion = "sdk_version"
        case adapter
        case ctxVersion = "ctx_version"
        case hosted
    }
}

public struct InitOptions: Sendable {
    public var catalogOnly: Bool
    public var progress: String?

    public init(catalogOnly: Bool = false, progress: String? = "none") {
        self.catalogOnly = catalogOnly
        self.progress = progress
    }
}

public struct ImportOptions: Sendable {
    public var all: Bool
    public var provider: String?
    public var path: String?
    public var resume: Bool
    public var progress: String?

    public init(
        all: Bool = false,
        provider: String? = nil,
        path: String? = nil,
        resume: Bool = false,
        progress: String? = "none"
    ) {
        self.all = all
        self.provider = provider
        self.path = path
        self.resume = resume
        self.progress = progress
    }
}

public struct SearchOptions: Sendable {
    public var terms: [String]
    public var limit: Int?
    public var provider: String?
    public var workspace: String?
    public var since: String?
    public var primaryOnly: Bool
    public var includeSubagents: Bool
    public var eventType: String?
    public var file: String?
    public var session: String?
    public var events: Bool
    public var refresh: String?
    public var includeCurrentSession: Bool

    public init(
        terms: [String] = [],
        limit: Int? = nil,
        provider: String? = nil,
        workspace: String? = nil,
        since: String? = nil,
        primaryOnly: Bool = false,
        includeSubagents: Bool = false,
        eventType: String? = nil,
        file: String? = nil,
        session: String? = nil,
        events: Bool = false,
        refresh: String? = nil,
        includeCurrentSession: Bool = false
    ) {
        self.terms = terms
        self.limit = limit
        self.provider = provider
        self.workspace = workspace
        self.since = since
        self.primaryOnly = primaryOnly
        self.includeSubagents = includeSubagents
        self.eventType = eventType
        self.file = file
        self.session = session
        self.events = events
        self.refresh = refresh
        self.includeCurrentSession = includeCurrentSession
    }
}

public struct ShowEventOptions: Sendable {
    public var before: Int?
    public var after: Int?
    public var window: Int?

    public init(before: Int? = nil, after: Int? = nil, window: Int? = nil) {
        self.before = before
        self.after = after
        self.window = window
    }
}

public struct ShowSessionOptions: Sendable {
    public var id: String?
    public var provider: String?
    public var providerSession: String?
    public var mode: String?

    public init(id: String? = nil, provider: String? = nil, providerSession: String? = nil, mode: String? = nil) {
        self.id = id
        self.provider = provider
        self.providerSession = providerSession
        self.mode = mode
    }
}

public struct LocateSessionOptions: Sendable {
    public var id: String?
    public var provider: String?
    public var providerSession: String?

    public init(id: String? = nil, provider: String? = nil, providerSession: String? = nil) {
        self.id = id
        self.provider = provider
        self.providerSession = providerSession
    }
}

public struct HostedConfig: Sendable {
    public var baseURL: URL?
    public var apiKey: String?

    public init(baseURL: URL? = nil, apiKey: String? = nil) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
}
