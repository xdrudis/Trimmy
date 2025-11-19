import AppKit
import Testing
@testable import Trimmy

@MainActor
@Suite
struct ClipboardMonitorTests {
    @Test
    func clipboardTextIgnoresMarker() {
        let settings = AppSettings()
        settings.autoTrimEnabled = true
        let monitor = ClipboardMonitor(settings: settings)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("echo hi\nls -la", forType: .string)
        _ = monitor.trimClipboardIfNeeded(force: false)
        #expect(monitor.clipboardText() != nil)
    }

    @Test
    func manualTrimReadsOwnMarker() {
        let settings = AppSettings()
        settings.autoTrimEnabled = false
        let monitor = ClipboardMonitor(settings: settings)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("echo hi\nls -la", forType: .string)
        _ = monitor.trimClipboardIfNeeded(force: true)
        NSPasteboard.general.setString("echo hi\nls -la", forType: .string)
        let didTrimAgain = monitor.trimClipboardIfNeeded(force: true)
        #expect(didTrimAgain)
    }

    @Test
    func forceTrimReturnsRawWhenNotTransformed() {
        let settings = AppSettings()
        settings.autoTrimEnabled = false
        let monitor = ClipboardMonitor(settings: settings)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("single line", forType: .string)
        #expect(monitor.trimmedClipboardText(force: true) == "single line")
    }
}
