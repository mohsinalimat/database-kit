import Async
import Service

/// Registers database kit services.
public final class DatabaseKitProvider: Provider {
    /// See Provider.repositoryName
    public static let repositoryName = "database-kit"

    /// Creates a new `DatabaseKitProvider`
    public init() {}

    /// See Provider.register
    public func register(_ services: inout Services) throws {
        services.register { container -> Databases in
            let config = try container.make(DatabaseConfig.self)
            var databases: [String: Any] = [:]
            for (id, lazyDatabase) in config.databases {
                let db = try lazyDatabase(container)
                if let supports = db as? LogSupporting, let logger = config.logging[id] {
                    logger.dbID = id
                    supports.enableLogging(using: logger)
                }
                databases[id] = db
            }
            return Databases(databases)
        }

        services.register { worker -> DatabaseConnectionPoolCache in
            let config = try worker.make(DatabaseConnectionPoolConfig.self)
            return try DatabaseConnectionPoolCache(
                databases: worker.make(),
                maxConnections: config.maxConnections,
                on: worker
            )
        }

        services.register { worker -> ActiveDatabaseConnectionCache in
            return ActiveDatabaseConnectionCache()
        }

        services.register(DatabaseConnectionPoolConfig.self)
    }

    /// See Provider.didBoot
    public func didBoot(_ worker: Container) throws -> Future<Void> {
        return .done(on: worker)
    }
}
