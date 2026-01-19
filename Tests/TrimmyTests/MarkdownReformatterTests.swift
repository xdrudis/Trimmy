import Testing
@testable import Trimmy

@Suite
struct MarkdownReformatterTests {
    @Test
    func reflowsWrappedBulletsAndKeepsBlankLines() {
        let input = """
        - OpenAI Responses 400: "Item 'rs_...' of type 'reasoning' was provided
          without its required following item."
        - Trigger: history replay includes assistant turns with only
          thinking/reasoning (often from aborted runs). pi-ai replays
          thinkingSignature as a reasoning item even when the same turn has
          no message or function_call.

        Fix summary (pi-mono)

        - packages/ai/src/providers/openai-responses.ts: only replay
          reasoning if the assistant turn also has text or toolCall; prevents
          lone reasoning items.
        - Regression test added: packages/ai/test/openai-responses-reasoning-
          replay.test.ts.
        - Changelog entry under packages/ai/CHANGELOG.md.
        """

        let expected = [
            "- OpenAI Responses 400: \"Item 'rs_...' of type 'reasoning' was provided "
                + "without its required following item.\"",
            "- Trigger: history replay includes assistant turns with only thinking/reasoning "
                + "(often from aborted runs). "
                + "pi-ai replays thinkingSignature as a reasoning item even when the same turn has "
                + "no message or function_call.",
            "",
            "Fix summary (pi-mono)",
            "",
            "- packages/ai/src/providers/openai-responses.ts: only replay reasoning if the assistant "
                + "turn also has text or toolCall; prevents lone reasoning items.",
            "- Regression test added: packages/ai/test/openai-responses-reasoning-replay.test.ts.",
            "- Changelog entry under packages/ai/CHANGELOG.md.",
        ].joined(separator: "\n")

        let result = MarkdownReformatter.reformat(input)
        #expect(result == expected)
    }

    @Test
    func keepsFencedCodeBlocks() {
        let input = """
        - First item with code:
        ```
        let a = 1
        let b = 2
        ```
        - Second item
        """

        let expected = """
        - First item with code:
        ```
        let a = 1
        let b = 2
        ```
        - Second item
        """

        let result = MarkdownReformatter.reformat(input)
        #expect(result == expected)
    }

    @Test
    func reflowsParagraphsAndBulletGlyphLists() {
        let input = """
        The test process is still running, so I'll keep polling for updates
          until completion and then respond with the final status.

        • Hi Peter — the CI run 21126984283 is still in progress. The Android
          test succeeded, while Windows test, Bun test, Node test, macOS app,
          macOS checks, and iOS tests remain. If you'd like me to keep
          watching, just say "continue."
        """

        let expected = [
            "The test process is still running, so I'll keep polling for updates until completion "
                + "and then respond with the final status.",
            "",
            "• Hi Peter — the CI run 21126984283 is still in progress. The Android test succeeded, "
                + "while Windows test, Bun test, Node test, macOS app, macOS checks, and iOS tests remain. "
                + "If you'd like me to keep watching, just say \"continue.\"",
        ].joined(separator: "\n")

        let result = MarkdownReformatter.reformat(input)
        #expect(result == expected)
    }

    @Test
    func detectsMarkdownByHeadingsAndLists() {
        let input = """
        ## Title
        - One
        - Two
        """

        #expect(MarkdownReformatter.isLikelyMarkdown(input))
    }

    @Test
    func ignoresPlainWrappedText() {
        let input = """
        This is a wrapped paragraph
        with no markdown markers.
        """

        #expect(!MarkdownReformatter.isLikelyMarkdown(input))
    }
}
