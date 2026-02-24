import Foundation

public struct TrimConfig: Sendable {
    public var aggressiveness: Aggressiveness
    public var preserveBlankLines: Bool
    public var removeBoxDrawing: Bool
    public var expectedLineLength: Int

    public init(
        aggressiveness: Aggressiveness,
        preserveBlankLines: Bool,
        removeBoxDrawing: Bool,
        expectedLineLength: Int = 80)
    {
        self.aggressiveness = aggressiveness
        self.preserveBlankLines = preserveBlankLines
        self.removeBoxDrawing = removeBoxDrawing
        self.expectedLineLength = expectedLineLength
    }
}
