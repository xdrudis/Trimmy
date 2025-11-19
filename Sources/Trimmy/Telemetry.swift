import OSLog

enum Telemetry {
    static let accessibility = Logger(subsystem: "com.steipete.trimmy", category: "accessibility")
    static let hotkey = Logger(subsystem: "com.steipete.trimmy", category: "hotkey")
}
