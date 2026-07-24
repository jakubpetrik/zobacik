import AppKit
import CoreFoundation

enum TextTransform {
    private static let locale = Locale(identifier: "sk_SK")

    static func removeDiacritics(from text: String) -> String {
        text
            .folding(options: .diacriticInsensitive, locale: locale)
            .replacingOccurrences(of: "ł", with: "l")
            .replacingOccurrences(of: "Ł", with: "L")
    }

    static func quote(_ text: String) -> String {
        transformLines(in: text) { line in
            line.isEmpty ? ">" : "> \(line)"
        }
    }

    static func unquote(_ text: String) -> String {
        transformLines(in: text) { line in
            guard line.hasPrefix(">") else { return line }
            return String(line.dropFirst().drop(while: { $0 == " " || $0 == "\t" }))
        }
    }

    private static func transformLines(
        in text: String,
        _ transform: (String) -> String
    ) -> String {
        guard !text.isEmpty else { return text }

        var lines = text.components(separatedBy: "\n")
        let endsWithNewline = text.hasSuffix("\n")
        let lastIndex = lines.index(before: lines.endIndex)

        for index in lines.indices {
            if endsWithNewline && index == lastIndex { break }
            lines[index] = transform(lines[index])
        }

        return lines.joined(separator: "\n")
    }
}

enum DiacriticsRestorer {
    private static let endpoint = URL(string: "https://diakritik.juls.savba.sk/")!

    static func restore(_ text: String) async throws -> String {
        var form = URLComponents()
        form.queryItems = [
            URLQueryItem(name: "text", value: text),
            URLQueryItem(name: "method", value: "4gram")
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = form.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse,
              response.statusCode == 200,
              let html = String(data: data, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        return try restoredText(from: html)
    }

    static func restoredText(from html: String) throws -> String {
        guard let start = html.range(of: "<div class=\"recinside\">\n"),
              let end = html.range(of: "\n</div>", range: start.upperBound..<html.endIndex) else {
            throw URLError(.cannotParseResponse)
        }

        let fragment = html[start.upperBound..<end.lowerBound]
            .replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
        guard let decoded = CFXMLCreateStringByUnescapingEntities(nil, fragment as CFString, nil) else {
            throw URLError(.cannotParseResponse)
        }
        return decoded as String
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let pasteboard = NSPasteboard.general
    private let originalTextType = NSPasteboard.PasteboardType("com.jakubpetrik.Zobacik.originalText")
    private var previousText: String?
    private var previousOriginalText: String?
    private var addDiacriticsItem: NSMenuItem!
    private var undoItem: NSMenuItem!
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.title = ">"
        statusItem.button?.toolTip = "Zobáčik"
        statusItem.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(actionItem("Remove Diacritics", key: "d", action: #selector(removeDiacritics)))
        addDiacriticsItem = actionItem("Add Slovak Diacritics", key: "a", action: #selector(addDiacritics))
        menu.addItem(addDiacriticsItem)
        menu.addItem(.separator())
        menu.addItem(actionItem("Quote Lines", key: "q", action: #selector(quoteLines)))
        menu.addItem(actionItem("Unquote Lines", key: "u", action: #selector(unquoteLines)))
        menu.addItem(.separator())

        undoItem = actionItem("Undo Last Transformation", key: "z", action: #selector(undo))
        undoItem.keyEquivalentModifierMask = .command
        undoItem.isEnabled = false
        menu.addItem(undoItem)
        menu.addItem(.separator())

        let about = NSMenuItem(title: "About Zobáčik", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)
        menu.addItem(NSMenuItem(title: "Quit Zobáčik", action: #selector(NSApplication.terminate), keyEquivalent: "q"))
        return menu
    }

    private func actionItem(_ title: String, key: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.keyEquivalentModifierMask = [.command, .option]
        item.target = self
        return item
    }

    private func apply(
        _ transform: (String) -> String,
        rememberOriginal: Bool = false,
        preserveOriginal: Bool = false
    ) {
        guard let source = pasteboard.string(forType: .string) else {
            NSSound.beep()
            return
        }

        let storedOriginal = pasteboard.string(forType: originalTextType)
        let result = transform(source)

        guard result != source else {
            NSSound.beep()
            return
        }

        let originalText: String?
        if rememberOriginal {
            originalText = source
        } else if preserveOriginal,
                  let storedOriginal,
                  TextTransform.removeDiacritics(from: storedOriginal) == source {
            originalText = transform(storedOriginal)
        } else {
            originalText = nil
        }

        previousText = source
        previousOriginalText = storedOriginal
        undoItem.isEnabled = true
        writeToPasteboard(result, originalText: originalText)
        showSuccess()
    }

    private func writeToPasteboard(_ text: String, originalText: String? = nil) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        if let originalText {
            pasteboard.setString(originalText, forType: originalTextType)
        }
    }

    private func showSuccess() {
        statusItem.button?.title = "✓"
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            statusItem.button?.title = ">"
        }
    }

    @objc private func removeDiacritics() {
        apply(TextTransform.removeDiacritics, rememberOriginal: true)
    }

    @objc private func addDiacritics() {
        guard let source = pasteboard.string(forType: .string) else {
            NSSound.beep()
            return
        }

        let storedOriginal = pasteboard.string(forType: originalTextType)
        if let storedOriginal,
           TextTransform.removeDiacritics(from: storedOriginal) == source {
            apply { _ in storedOriginal }
            return
        }

        let pasteboardChangeCount = pasteboard.changeCount
        addDiacriticsItem.isEnabled = false
        statusItem.button?.title = "…"

        Task { @MainActor in
            defer { addDiacriticsItem.isEnabled = true }

            do {
                let result = try await DiacriticsRestorer.restore(source)
                guard pasteboard.changeCount == pasteboardChangeCount else {
                    statusItem.button?.title = ">"
                    return
                }
                guard result != source else {
                    NSSound.beep()
                    statusItem.button?.title = ">"
                    return
                }

                previousText = source
                previousOriginalText = storedOriginal
                undoItem.isEnabled = true
                writeToPasteboard(result)
                showSuccess()
            } catch {
                NSSound.beep()
                statusItem.button?.title = "!"
                try? await Task.sleep(for: .milliseconds(700))
                statusItem.button?.title = ">"
            }
        }
    }

    @objc private func quoteLines() {
        apply(TextTransform.quote, preserveOriginal: true)
    }

    @objc private func unquoteLines() {
        apply(TextTransform.unquote, preserveOriginal: true)
    }

    @objc private func undo() {
        guard let previousText else { return }
        writeToPasteboard(previousText, originalText: previousOriginalText)
        self.previousText = nil
        previousOriginalText = nil
        undoItem.isEnabled = false
        showSuccess()
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Zobáčik",
            .applicationVersion: "1.0.0",
            .credits: NSAttributedString(string: "A tiny clipboard text transformer for macOS.")
        ])
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
@MainActor
enum ZobacikApp {
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.run()
    }
}
