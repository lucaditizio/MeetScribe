import Foundation
import SwiftData
public protocol MindMapInteractorOutput: AnyObject {
    func didObtainMindMap(nodes: [MindMapNode])
    func didFailWithError(_ error: Error)
}
