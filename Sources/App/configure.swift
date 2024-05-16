import NIOSSL
import Fluent
import FluentSQLiteDriver
import Vapor
import JWT

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(DatabaseConfigurationFactory.sqlite(.file("db.sqlite")), as: .sqlite)

    app.migrations.add(CreateUsers())
    app.migrations.add(CreateMeals())
    app.migrations.add(CreateGlucometerBloodSugarTests())
    app.migrations.add(CreateStartTimes())
    app.migrations.add(CreateAppointments())
    try await app.autoMigrate()
    
    app.jwt.signers.use(.hs256(key: "secret"))

    // register routes
    try routes(app)
}
