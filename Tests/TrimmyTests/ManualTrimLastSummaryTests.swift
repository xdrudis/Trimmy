import AppKit
import Testing
@testable import Trimmy

@MainActor
@Suite
struct ManualTrimLastSummaryTests {
    @Test
    func manualTrimUpdatesLastEvenWhenNotCommand() {
        let settings = AppSettings()
        settings.autoTrimEnabled = false
        let monitor = ClipboardMonitor(settings: settings)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("just text", forType: .string)
        let didTrim = monitor.trimClipboardIfNeeded(force: true)
        #expect(didTrim)
        #expect(monitor.lastSummary.contains("just text"))
    }
}
