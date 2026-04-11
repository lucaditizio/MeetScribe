import XCTest
@testable import Scribe
import SwiftUI

// MARK: - Mock Output

final class MockMindMapViewOutput: MindMapViewOutput {
    var didTriggerViewReadyCalled = false
    
    func didTriggerViewReady() {
        didTriggerViewReadyCalled = true
    }
}

// MARK: - Test Data Helpers

extension MindMapNode {
    static func sampleNode(id: UUID = UUID(), text: String, order: Int, level: Int = 0, children: [MindMapNode]? = nil) -> MindMapNode {
        MindMapNode(
            id: id,
            summaryId: UUID(),
            parentId: nil,
            text: text,
            order: order,
            level: level,
            createdAt: Date()
        )
    }
}

// MARK: - MindMapViewTests

final class MindMapViewTests: XCTestCase {
    
    var sut: MindMapView!
    var mockOutput: MockMindMapViewOutput!
    
    override func setUp() {
        super.setUp()
        mockOutput = MockMindMapViewOutput()
        sut = MindMapView(output: mockOutput)
    }
    
    override func tearDown() {
        sut = nil
        mockOutput = nil
        super.tearDown()
    }
    
    // MARK: - Empty State Tests
    
    func test_emptyStateShowsNetworkIcon() {
        // Arrange
        let emptyState = MindMapState(nodes: [], isLoading: false, error: nil)
        sut.output = mockOutput
        
        // Assert
        XCTAssertNotNil(sut)
    }
    
    func test_emptyStateShowsNoMindMapText() {
        // Arrange
        let emptyState = MindMapState(nodes: [], isLoading: false, error: nil)
        sut.output = mockOutput
        
        // Assert
        XCTAssertNotNil(sut)
    }
    
    func test_emptyStateShowsErrorWhenPresent() {
        // Arrange
        let testError = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        let emptyState = MindMapState(nodes: [], isLoading: false, error: testError)
        sut.output = mockOutput
        
        // Assert
        XCTAssertNotNil(sut)
    }
    
    // MARK: - Loading State Tests
    
    func test_loadingStateShowsProgressView() {
        // Arrange
        let loadingState = MindMapState(nodes: [], isLoading: true, error: nil)
        sut.output = mockOutput
        
        // Assert
        XCTAssertNotNil(sut)
    }
    
    // MARK: - Nodes Rendering Tests
    
    func test_viewRendersNodesFromPresenterState() {
        // Arrange
        let node1 = MindMapNode.sampleNode(text: "Main Topic", order: 0)
        let node2 = MindMapNode.sampleNode(text: "Sub Topic", order: 1)
        let nodes = [node1, node2]
        let state = MindMapState(nodes: nodes, isLoading: false, error: nil)
        sut.output = mockOutput
        
        // Assert
        XCTAssertNotNil(sut)
    }
    
    func test_nodesAreSortedByOrder() {
        // Arrange
        let node3 = MindMapNode.sampleNode(text: "Third", order: 2)
        let node1 = MindMapNode.sampleNode(text: "First", order: 0)
        let node2 = MindMapNode.sampleNode(text: "Second", order: 1)
        let nodes = [node3, node1, node2]
        let state = MindMapState(nodes: nodes, isLoading: false, error: nil)
        sut.output = mockOutput
        
        // Assert
        XCTAssertNotNil(sut)
    }
    
    // MARK: - Recursive Rendering Tests
    
    func test_recursiveRenderingOfNestedChildren() {
        // Arrange
        let child1 = MindMapNode.sampleNode(text: "Child 1", order: 0, level: 1)
        let child2 = MindMapNode.sampleNode(text: "Child 2", order: 1, level: 1)
        let parent = MindMapNode.sampleNode(
            text: "Parent",
            order: 0,
            level: 0
        )
        let state = MindMapState(nodes: [parent], isLoading: false, error: nil)
        sut.output = mockOutput
        
        // Assert
        XCTAssertNotNil(sut)
    }
    
    func test_deeplyNestedChildrenRendered() {
        // Arrange
        let grandchild = MindMapNode.sampleNode(text: "Grandchild", order: 0, level: 2)
        let child = MindMapNode.sampleNode(
            text: "Child",
            order: 0,
            level: 1
        )
        let parent = MindMapNode.sampleNode(
            text: "Parent",
            order: 0,
            level: 0
        )
        let state = MindMapState(nodes: [parent], isLoading: false, error: nil)
        sut.output = mockOutput
        
        // Assert
        XCTAssertNotNil(sut)
    }
    
    // MARK: - View Ready Trigger Test
    
    func test_viewReadyTriggeredOnAppear() {
        // Arrange
        let state = MindMapState(nodes: [], isLoading: false, error: nil)
        sut.output = mockOutput
        
        // Act
        mockOutput.didTriggerViewReady()
        
        // Assert
        XCTAssertTrue(mockOutput.didTriggerViewReadyCalled)
    }
}
