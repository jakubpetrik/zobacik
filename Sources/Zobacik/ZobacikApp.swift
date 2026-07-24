import AppKit

enum TextTransform {
    static func removeDiacritics(from text: String) -> String {
        text
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "sk_SK"))
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

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let pasteboard = NSPasteboard.general
    private var previousText: String?
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

    private func apply(_ transform: (String) -> String) {
        guard let source = pasteboard.string(forType: .string) else {
            NSSound.beep()
            return
        }

        let result = transform(source)
        guard result != source else {
            NSSound.beep()
            return
        }

        previousText = source
        undoItem.isEnabled = true
        writeToPasteboard(result)
        showSuccess()
    }

    private func writeToPasteboard(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func showSuccess() {
        statusItem.button?.title = "✓"
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            statusItem.button?.title = ">"
        }
    }

    @objc private func removeDiacritics() {
        apply(TextTransform.removeDiacritics)
    }

    @objc private func quoteLines() {
        apply(TextTransform.quote)
    }

    @objc private func unquoteLines() {
        apply(TextTransform.unquote)
    }

    @objc private func undo() {
        guard let previousText else { return }
        writeToPasteboard(previousText)
        self.previousText = nil
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
