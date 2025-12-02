import Testing
@testable import Trimmy

@Suite
struct BoxDrawingCleanupTests {
    @Test
    func removesBoxDrawingAfterPipe() {
        let input = "curl -I https://example.com | │ head -n 5"
        let cleaned = CommandDetector.stripBoxDrawingCharacters(in: input)
        #expect(cleaned == "curl -I https://example.com | head -n 5")
    }
}
