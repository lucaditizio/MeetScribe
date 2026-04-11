import Foundation
import SwiftData

public struct MindMapState {
    public var nodes: [MindMapNode]
    public var isLoading: Bool
    public var error: Error?
    
    public init(nodes: [MindMapNode] = [], isLoading: Bool = false, error: Error? = nil) {
        self.nodes = nodes
        self.isLoading = isLoading
        self.error = error
    }
}
