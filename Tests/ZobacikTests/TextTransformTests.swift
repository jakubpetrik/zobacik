import Foundation
import Testing
@testable import Zobacik

@Suite("Text transformations")
struct TextTransformTests {
    @Test("Removes Central European diacritics")
    func removeDiacritics() {
        let source = "Příliš žluťoučký kůň úpěl ďábelské ódy. Zażółć gęślą jaźń."

        #expect(
            TextTransform.removeDiacritics(from: source)
                == "Prilis zlutoucky kun upel dabelske ody. Zazolc gesla jazn."
        )
    }

    @Test("Quotes every line and preserves a final newline")
    func quoteLines() {
        #expect(TextTransform.quote("one\n\ntwo\n") == "> one\n>\n> two\n")
    }

    @Test("Unquotes one level, trims its indentation, and leaves other lines alone")
    func unquoteLines() {
        #expect(
            TextTransform.unquote(">   one\n>> nested\n  plain\n")
                == "one\n> nested\n  plain\n"
        )
    }

    @Test("Parses multiline text returned by the Slovak corpus")
    func addDiacriticsResponse() throws {
        let html = """
        <div class="recinside">
        Ahoj,<br />ako sa máš?<br /><br />Mám ťa rád &amp; ďakujem.
        </div>
        """

        #expect(
            try DiacriticsRestorer.restoredText(from: html)
                == "Ahoj,\nako sa máš?\n\nMám ťa rád & ďakujem."
        )
    }

    @Test("Empty text stays empty")
    func emptyText() {
        #expect(TextTransform.quote("").isEmpty)
        #expect(TextTransform.unquote("").isEmpty)
    }
}
