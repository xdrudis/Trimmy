import Testing
import TrimmyCore
@testable import Trimmy

@MainActor
@Suite
struct AggressivenessPreviewExamplesTests {
    @Test
    func lowExampleFlattensToSingleLine() {
        let sample = AggressivenessExample.example(for: Aggressiveness.low).sample
        let flattened = AggressivenessPreviewEngine.previewAfter(
            for: sample,
            level: .low,
            preserveBlankLines: false,
            removeBoxDrawing: true)
        #expect(flattened == "ls -la | grep '^d' > dirs.txt")
    }

    @Test
    func normalExampleMatchesExpectation() {
        let sample = AggressivenessExample.example(for: Aggressiveness.normal).sample
        let flattened = AggressivenessPreviewEngine.previewAfter(
            for: sample,
            level: .normal,
            preserveBlankLines: false,
            removeBoxDrawing: true)
        #expect(flattened == "kubectl get pods -n kube-system | jq '.items[].metadata.name'")
    }

    @Test
    func highExampleCollapsesLooseCommands() {
        let sample = AggressivenessExample.example(for: Aggressiveness.high).sample
        let flattened = AggressivenessPreviewEngine.previewAfter(
            for: sample,
            level: .high,
            preserveBlankLines: false,
            removeBoxDrawing: true)
        #expect(flattened == "echo \"hello\" print status")
    }

    @Test
    func previewCollapsesPathLineBreaks() {
        let sample = """
        ssh steipete@192.168.64.2 'chmod 600 ~/.ssh/github_rsa && chmod 644 ~/.ssh/
        github_rsa.pub'
        """
        let flattened = AggressivenessPreviewEngine.previewAfter(
            for: sample,
            level: .normal,
            preserveBlankLines: false,
            removeBoxDrawing: true)
        #expect(flattened ==
            "ssh steipete@192.168.64.2 'chmod 600 ~/.ssh/github_rsa && chmod 644 ~/.ssh/github_rsa.pub'")
    }
}
