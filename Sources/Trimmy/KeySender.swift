import AppKit
@preconcurrency import ApplicationServices
import Carbon
import OSLog

/// Sends synthetic key events for a given string using US-ANSI key codes; handles modifiers pragmatically for VMs.
@MainActor
struct KeySender {
    private let source = CGEventSource(stateID: .hidSystemState)

    /// Request Accessibility/Input Monitoring if needed. Returns true when trusted.
    static func ensureAccessibility() -> Bool {
        let alreadyTrusted = AXIsProcessTrusted()
        if alreadyTrusted { return true }

        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: CFDictionary = [key: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Types the provided text into the focused app using key codes (US-ANSI).
    @discardableResult
    func type(text: String) -> Bool {
        guard let source else { return false }
        var typed = false

        var shiftLatched = false
        func ensureShift(_ down: Bool) {
            guard shiftLatched != down else { return }
            self.postShift(down: down, source: source)
            shiftLatched = down
            Self.pause(microseconds: Timings.settleAfterModifier)
        }

        for character in text {
            switch character {
            case "\n", "\r":
                ensureShift(false)
                self.sendKey(code: CGKeyCode(kVK_Return), shiftDown: shiftLatched, source: source)
                typed = true
            case "\t":
                ensureShift(false)
                self.sendKey(code: CGKeyCode(kVK_Tab), shiftDown: shiftLatched, source: source)
                typed = true
            case " ":
                ensureShift(false)
                self.sendKey(code: CGKeyCode(kVK_Space), shiftDown: shiftLatched, source: source)
                typed = true
            default:
                if let info = self.keyInfo(for: character) {
                    let wantsShift = info.flags.contains(.maskShift)
                    ensureShift(wantsShift)
                    self.sendKey(code: info.code, shiftDown: shiftLatched, source: source)
                    typed = true
                }
            }
            Self.pause(microseconds: Timings.betweenCharacters)
        }

        if shiftLatched {
            self.postShift(down: false, source: source)
            Self.pause(microseconds: Timings.settleAfterModifier)
        }

        return typed
    }

    /// Returns key code + flags for ASCII-ish characters.
    func keyInfo(for character: Character) -> (code: CGKeyCode, flags: CGEventFlags)? {
        if character == " " { return (CGKeyCode(kVK_Space), []) }
        if character == "\n" || character == "\r" { return (CGKeyCode(kVK_Return), []) }
        if character == "\t" { return (CGKeyCode(kVK_Tab), []) }

        if let shifted = KeySender.shiftedMap[character] {
            return shifted
        }

        let lower = Character(character.lowercased())
        if let base = KeySender.baseMap[lower] {
            let needsShift = character.isLetter && character.isUppercase
            let flags: CGEventFlags = needsShift ? .maskShift : []
            return (base, flags)
        }

        return nil
    }
}

extension KeySender {
    private enum Modifier {
        case leftShift, rightShift
        var keyCode: CGKeyCode {
            switch self {
            case .leftShift: return CGKeyCode(kVK_Shift)
            case .rightShift: return CGKeyCode(kVK_RightShift)
            }
        }
    }

    private struct Timings {
        static let settleAfterModifier: useconds_t = 30000  // 30 ms
        static let keyHold: useconds_t = 7000               // 7 ms
        static let betweenCharacters: useconds_t = 12000    // 12 ms
    }

    private var isVMConsoleFrontmost: Bool {
        guard let bid = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return false }
        return bid.hasPrefix("com.vmware.") || bid.hasPrefix("com.parallels.")
    }

    private var shiftSidesToUse: [Modifier] {
        self.isVMConsoleFrontmost ? [.leftShift, .rightShift] : [.leftShift]
    }

    private func effectiveFlags(shiftDown: Bool) -> CGEventFlags {
        var flags = CGEventSource.flagsState(.combinedSessionState)
        if shiftDown { flags.insert(.maskShift) } else { flags.remove(.maskShift) }
        return flags
    }

    private func sendKey(code: CGKeyCode, shiftDown: Bool, source: CGEventSource) {
        let flags = self.effectiveFlags(shiftDown: shiftDown)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: false)
        else { return }
        down.flags = flags
        up.flags = flags
        down.post(tap: .cghidEventTap)
        Self.pause(microseconds: Timings.keyHold)
        up.post(tap: .cghidEventTap)
    }

    private func postShift(down: Bool, source: CGEventSource) {
        let flags = self.effectiveFlags(shiftDown: down)
        for side in self.shiftSidesToUse {
            guard let ev = CGEvent(keyboardEventSource: source, virtualKey: side.keyCode, keyDown: down) else { continue }
            ev.flags = flags
            ev.post(tap: .cghidEventTap)
        }
    }

    private static func pause(microseconds: useconds_t) {
        usleep(microseconds)
    }

    /// Base (non-shifted) characters → key codes (US ANSI).
    fileprivate static let baseMap: [Character: CGKeyCode] = [
        "a": CGKeyCode(kVK_ANSI_A), "b": CGKeyCode(kVK_ANSI_B), "c": CGKeyCode(kVK_ANSI_C),
        "d": CGKeyCode(kVK_ANSI_D), "e": CGKeyCode(kVK_ANSI_E), "f": CGKeyCode(kVK_ANSI_F),
        "g": CGKeyCode(kVK_ANSI_G), "h": CGKeyCode(kVK_ANSI_H), "i": CGKeyCode(kVK_ANSI_I),
        "j": CGKeyCode(kVK_ANSI_J), "k": CGKeyCode(kVK_ANSI_K), "l": CGKeyCode(kVK_ANSI_L),
        "m": CGKeyCode(kVK_ANSI_M), "n": CGKeyCode(kVK_ANSI_N), "o": CGKeyCode(kVK_ANSI_O),
        "p": CGKeyCode(kVK_ANSI_P), "q": CGKeyCode(kVK_ANSI_Q), "r": CGKeyCode(kVK_ANSI_R),
        "s": CGKeyCode(kVK_ANSI_S), "t": CGKeyCode(kVK_ANSI_T), "u": CGKeyCode(kVK_ANSI_U),
        "v": CGKeyCode(kVK_ANSI_V), "w": CGKeyCode(kVK_ANSI_W), "x": CGKeyCode(kVK_ANSI_X),
        "y": CGKeyCode(kVK_ANSI_Y), "z": CGKeyCode(kVK_ANSI_Z),
        "0": CGKeyCode(kVK_ANSI_0), "1": CGKeyCode(kVK_ANSI_1), "2": CGKeyCode(kVK_ANSI_2),
        "3": CGKeyCode(kVK_ANSI_3), "4": CGKeyCode(kVK_ANSI_4), "5": CGKeyCode(kVK_ANSI_5),
        "6": CGKeyCode(kVK_ANSI_6), "7": CGKeyCode(kVK_ANSI_7), "8": CGKeyCode(kVK_ANSI_8),
        "9": CGKeyCode(kVK_ANSI_9),
        "-": CGKeyCode(kVK_ANSI_Minus), "=": CGKeyCode(kVK_ANSI_Equal),
        "[": CGKeyCode(kVK_ANSI_LeftBracket), "]": CGKeyCode(kVK_ANSI_RightBracket),
        "\\": CGKeyCode(kVK_ANSI_Backslash),
        ";": CGKeyCode(kVK_ANSI_Semicolon), "'": CGKeyCode(kVK_ANSI_Quote),
        ",": CGKeyCode(kVK_ANSI_Comma), ".": CGKeyCode(kVK_ANSI_Period), "/": CGKeyCode(kVK_ANSI_Slash),
        "`": CGKeyCode(kVK_ANSI_Grave),
    ]

    /// Shifted characters we need to map explicitly.
    fileprivate static let shiftedMap: [Character: (CGKeyCode, CGEventFlags)] = [
        "!": (CGKeyCode(kVK_ANSI_1), .maskShift),
        "@": (CGKeyCode(kVK_ANSI_2), .maskShift),
        "#": (CGKeyCode(kVK_ANSI_3), .maskShift),
        "$": (CGKeyCode(kVK_ANSI_4), .maskShift),
        "%": (CGKeyCode(kVK_ANSI_5), .maskShift),
        "^": (CGKeyCode(kVK_ANSI_6), .maskShift),
        "&": (CGKeyCode(kVK_ANSI_7), .maskShift),
        "*": (CGKeyCode(kVK_ANSI_8), .maskShift),
        "(": (CGKeyCode(kVK_ANSI_9), .maskShift),
        ")": (CGKeyCode(kVK_ANSI_0), .maskShift),
        "_": (CGKeyCode(kVK_ANSI_Minus), .maskShift),
        "+": (CGKeyCode(kVK_ANSI_Equal), .maskShift),
        "{": (CGKeyCode(kVK_ANSI_LeftBracket), .maskShift),
        "}": (CGKeyCode(kVK_ANSI_RightBracket), .maskShift),
        "|": (CGKeyCode(kVK_ANSI_Backslash), .maskShift),
        ":": (CGKeyCode(kVK_ANSI_Semicolon), .maskShift),
        "\"": (CGKeyCode(kVK_ANSI_Quote), .maskShift),
        "<": (CGKeyCode(kVK_ANSI_Comma), .maskShift),
        ">": (CGKeyCode(kVK_ANSI_Period), .maskShift),
        "?": (CGKeyCode(kVK_ANSI_Slash), .maskShift),
        "~": (CGKeyCode(kVK_ANSI_Grave), .maskShift),
    ]
}
