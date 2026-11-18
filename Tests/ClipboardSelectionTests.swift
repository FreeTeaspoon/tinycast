import Foundation

@main
@MainActor
struct ClipboardSelectionTests {
    static var failures = 0
    static let rows = (0..<6).map { _ in UUID() }

    static func main() {
        var selection = ClipboardSelection()
        expect(selection.selectedIDs(focusedID: rows[0]) == [rows[0]], "focus is the initial selection")
        selection.select(rows[3], in: rows, focusedID: rows[0])
        selection.select(rows[1], in: rows, focusedID: rows[3], toggling: true)
        selection.select(rows[5], in: rows, focusedID: rows[1], toggling: true)
        expect(selection.ids == [rows[3], rows[1], rows[5]], "command click preserves selection order")
        selection.select(rows[1], in: rows, focusedID: rows[5], toggling: true)
        expect(selection.ids == [rows[3], rows[5]], "command click removes an existing selection")
        selection.select(rows[1], in: rows, focusedID: rows[1], toggling: true)
        expect(selection.ids == [rows[3], rows[5], rows[1]], "reselecting appends to paste order")
        selection.select(rows[1], in: rows, focusedID: rows[1])
        expect(selection.ids == [rows[1]], "plain click replaces the group")
        selection.select(rows[1], in: rows, focusedID: rows[1], toggling: true)
        expect(selection.selectedIDs(focusedID: rows[1]).isEmpty, "deselecting the last row stays empty")

        selection = ClipboardSelection()
        selection.select(rows[3], in: rows, focusedID: rows[1], extending: true)
        expect(selection.ids == Array(rows[1...3]), "shift click includes the anchor and endpoint")
        selection.select(rows[2], in: rows, focusedID: rows[3], extending: true)
        expect(selection.ids == Array(rows[1...2]), "shrinking a range keeps its original anchor")
        selection.select(rows[0], in: rows, focusedID: rows[2], extending: true)
        expect(selection.ids == Array(rows[0...1]), "a reverse range follows visible row order")
        selection.select(rows[4], in: rows, focusedID: rows[0], toggling: true)
        selection.select(rows[5], in: rows, focusedID: rows[4], toggling: true, extending: true)
        expect(selection.ids == [rows[0], rows[1], rows[4], rows[5]], "command shift adds a range once")

        selection.select(rows[2], in: [rows[2], rows[4]], focusedID: rows[5], toggling: true)
        expect(selection.ids == [rows[4], rows[2]], "a changed result set drops unavailable selections")
        let before = selection
        selection.select(UUID(), in: rows, focusedID: rows[2])
        expect(selection == before, "an unknown row cannot change selection")
        selection.select(rows[5], in: [rows[2], rows[5]], focusedID: rows[2], extending: true)
        expect(selection.ids == [rows[2], rows[5]], "ranges use visible rows only")
        selection.select(rows[1], in: rows, focusedID: rows[5])
        selection.select(rows[4], in: Array(rows[2...5]), focusedID: rows[2], extending: true)
        selection.select(rows[5], in: Array(rows[2...5]), focusedID: rows[4], extending: true)
        expect(selection.ids == Array(rows[2...5]), "a deleted range anchor is replaced by the focused row")

        print("Clipboard selection: \(failures) failures")
        if failures > 0 { exit(1) }
    }

    static func expect(_ condition: Bool, _ message: String) {
        if !condition {
            failures += 1
            print("FAIL: \(message)")
        }
    }
}
