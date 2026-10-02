import AppKit

/// Avoid handing screenshot text or QR URLs to a network-capable browser.
enum LocalWorkspace {
    static func permits(_ url: URL) -> Bool {
        if url.isFileURL {
            let host = url.host?.lowercased() ?? ""
            return host.isEmpty || host == "localhost"
        }
        return url.scheme?.lowercased() == "x-apple.systempreferences"
    }

    @discardableResult
    static func open(_ url: URL) -> Bool {
        guard permits(url) else {
            let alert = NSAlert()
            alert.messageText = "External links are disabled"
            alert.informativeText = "This build only opens local files and macOS settings."
            alert.runModal()
            return false
        }
        return NSWorkspace.shared.open(url)
    }
}
