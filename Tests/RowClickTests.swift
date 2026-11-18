import AppKit
import SwiftUI

@main
@MainActor
struct RowClickTests {
    static var failures = 0

    static func main() {
        _ = NSApplication.shared
        check(modifiers: [.command, .shift])
        check(modifiers: [])
        print("Row clicks: \(failures) failures")
        if failures > 0 { exit(1) }
    }

    static func check(modifiers: NSEvent.ModifierFlags) {
        var selections: [NSEvent.ModifierFlags] = []
        var activations = 0
        let host = NSHostingView(
            rootView: Color.clear.frame(width: 100, height: 40)
                .onRowClick(
                    select: { selections.append($0) }, activate: { activations += 1 },
                    selectionModifiers: modifiers))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 40),
            styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        defer { window.close() }
        host.layoutSubtreeIfNeeded()
        guard let catcher = findCatcher(in: host) else {
            expect(false, "the native press catcher mounts")
            return
        }
        press(catcher, flags: [], count: 1)
        expect(selections.count == 1 && activations == 0, "a single click only selects")
        press(catcher, flags: [], count: 2)
        expect(activations == 1, "an unmodified double click activates")
        press(catcher, flags: .command, count: 2)
        expect(selections.last == .command, "command reaches selection unchanged")
        expect(activations == (modifiers.contains(.command) ? 1 : 2), "command selection cannot activate")
        press(catcher, flags: .shift, count: 2)
        expect(selections.last == .shift, "shift reaches selection unchanged")
        expect(activations == (modifiers.contains(.shift) ? 1 : 3), "shift selection cannot activate")
    }

    static func press(_ view: NSView, flags: NSEvent.ModifierFlags, count: Int) {
        guard let event = NSEvent.mouseEvent(
            with: .leftMouseDown, location: .zero, modifierFlags: flags, timestamp: 0,
            windowNumber: view.window?.windowNumber ?? 0, context: nil, eventNumber: 0,
            clickCount: count, pressure: 1)
        else {
            expect(false, "the fixture creates a mouse event")
            return
        }
        view.mouseDown(with: event)
    }

    static func findCatcher(in view: NSView) -> NSView? {
        if String(describing: type(of: view)) == "RowPressView" { return view }
        return view.subviews.lazy.compactMap { findCatcher(in: $0) }.first
    }

    static func expect(_ condition: Bool, _ message: String) {
        if !condition {
            failures += 1
            print("FAIL: \(message)")
        }
    }
}
