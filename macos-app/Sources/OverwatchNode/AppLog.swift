import os

/// Unified-logging categories, viewable live with:
///   log stream --predicate 'subsystem == "com.navaneeth.overwatchnode"' --level debug
/// (print() goes nowhere useful once launched via `open .app`, detached
/// from any terminal — os.log is what Console.app / `log stream` can see.)
enum AppLog {
    static let network = Logger(subsystem: "com.navaneeth.overwatchnode", category: "network")
    static let bonjour = Logger(subsystem: "com.navaneeth.overwatchnode", category: "bonjour")
    static let lifecycle = Logger(subsystem: "com.navaneeth.overwatchnode", category: "lifecycle")
}
