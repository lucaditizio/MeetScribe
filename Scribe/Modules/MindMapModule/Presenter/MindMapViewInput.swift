import Foundation
import SwiftData
public protocol MindMapViewInput: AnyObject {
    func displayMindMap(nodes: [MindMapNode])
    func displayError(_ error: Error)
}
