import OSLog

enum AppLogger {
    static let repository = Logger(subsystem: Constants.bundleIdentifier, category: "repository")
    static let access = Logger(subsystem: Constants.bundleIdentifier, category: "access")
    static let git = Logger(subsystem: Constants.bundleIdentifier, category: "git")
    static let commit = Logger(subsystem: Constants.bundleIdentifier, category: "commit")
    static let foundationModel = Logger(subsystem: Constants.bundleIdentifier, category: "foundationModel")
    static let monitoring = Logger(subsystem: Constants.bundleIdentifier, category: "monitoring")
    static let settings = Logger(subsystem: Constants.bundleIdentifier, category: "settings")
}
