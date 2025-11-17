import AppKit
import Foundation

@MainActor
final class ClipboardMonitor: ObservableObject {
    private let settings: AppSettings
    private let pasteboard = NSPasteboard.general
    private let trimmyMarker = NSPasteboard.PasteboardType("com.steipete.trimmy")
    private var timer: DispatchSourceTimer?
    private var lastSeenChangeCount: Int
    private var detector: CommandDetector { CommandDetector(settings: self.settings) }
    private let pollInterval: DispatchTimeInterval = .milliseconds(150)
    private let pollLeeway: DispatchTimeInterval = .milliseconds(50)
    private let graceDelay: DispatchTimeInterval = .milliseconds(80)

    @Published var lastSummary: String = ""

    init(settings: AppSettings) {
        self.settings = settings
        self.lastSeenChangeCount = self.pasteboard.changeCount
    }

    func start() {
        self.stop()
        let t = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        t.schedule(deadline: .now(), repeating: self.pollInterval, leeway: self.pollLeeway)
        t.setEventHandler { [weak self] in
            self?.tick()
        }
        t.resume()
        self.timer = t
    }

    func stop() {
        self.timer?.cancel()
        self.timer = nil
    }

    @discardableResult
    func trimClipboardIfNeeded(force: Bool = false) -> Bool {
        let changeCount = self.pasteboard.changeCount
        self.lastSeenChangeCount = changeCount

        guard let text = self.readTextFromPasteboard() else { return false }
        guard self.settings.autoTrimEnabled || force else { return false }

        let transformed: String
        if force {
            transformed = self.detector.transformIfCommand(text) ?? text
            if transformed == text, !text.contains("\\\n"), !text.contains("\n") { return false }
        } else {
            guard let candidate = detector.transformIfCommand(text) else { return false }
            transformed = candidate
        }

        self.writeTrimmed(transformed)
        self.lastSeenChangeCount = self.pasteboard.changeCount
        self.updateSummary(with: transformed)
        return true
    }

    private func tick() {
        let current = self.pasteboard.changeCount
        guard current != self.lastSeenChangeCount else { return }

        let observed = current
        // Grace delay lets promised pasteboard data settle before we read/transform.
        DispatchQueue.main.asyncAfter(deadline: .now() + self.graceDelay) { [weak self] in
            guard let self, observed == self.pasteboard.changeCount else { return }
            _ = self.trimClipboardIfNeeded()
            self.lastSeenChangeCount = self.pasteboard.changeCount
        }
    }

    private func readTextFromPasteboard() -> String? {
        if self.pasteboard.types?.contains(self.trimmyMarker) == true { return nil }
        return self.pasteboard.string(forType: .string)
    }

    private func writeTrimmed(_ text: String) {
        self.pasteboard.declareTypes([.string, self.trimmyMarker], owner: nil)
        self.pasteboard.setString(text, forType: .string)
        self.pasteboard.setData(Data(), forType: self.trimmyMarker)
    }

    private func updateSummary(with text: String) {
        self.lastSummary = text.replacingOccurrences(of: "\n", with: " ")
    }
}
