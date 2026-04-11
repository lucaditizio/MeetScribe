import SwiftUI

/// Passive VIPER View: reads state from Presenter, renders UI only
public struct MindMapView: View {
    // MARK: - Properties
    
    /// Strong reference to Presenter (output)
    public var output: MindMapViewOutput
    
    /// State from Presenter (read-only, updated via Presenter)
    @State private var state: MindMapState
    
    // MARK: - Init
    
    public init(output: MindMapViewOutput) {
        self.output = output
        self._state = State(initialValue: MindMapState())
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // Background
            Theme.obsidian
                .ignoresSafeArea()
            
            VStack {
                if state.isLoading {
                    loadingView
                } else if state.nodes.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.sectionSpacing) {
                            ForEach(state.nodes.sorted { $0.order < $1.order }, id: \.id) { node in
                                MindMapNodeView(node: node, depth: 0)
                            }
                        }
                        .padding(Spacing.cardPadding)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            output.didTriggerViewReady()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.scribeRed))
                .scaleEffect(1.5)
            
            Text("Loading mind map...")
                .font(Typography.subheadline)
                .foregroundColor(Theme.accentGray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.cardPadding) {
            Image(systemName: "network")
                .font(.system(size: 60))
                .foregroundColor(Theme.accentGray)
            
            Text("No mind map available")
                .font(Typography.headline)
                .foregroundColor(Theme.accentGray)
            
            if let error = state.error {
                Text(error.localizedDescription)
                    .font(Typography.footnote)
                    .foregroundColor(Theme.scribeRed)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.cardPadding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - MindMap Node View (Recursive)

/// Recursive view for rendering a single mind map node and its children
private struct MindMapNodeView: View {
    let node: MindMapNode
    let depth: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.contentPadding) {
            // Node card
            nodeCard
            
            // Children (recursive)
            if let children = node.children, !children.isEmpty {
                childrenContainer(children: children.sorted { $0.order < $1.order })
            }
        }
    }
    
    // MARK: - Node Card
    
    private var nodeCard: some View {
        HStack(spacing: Spacing.contentPadding) {
            // Branch connector for non-root nodes
            if depth > 0 {
                Rectangle()
                    .fill(Theme.scribeRed)
                    .frame(width: 3)
            }
            
            // Node text
            Text(node.text)
                .font(nodeFont)
                .foregroundColor(nodeTextColor)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(Spacing.contentPadding)
        .background(Theme.cardBackgroundDark)
        .cornerRadius(Theme.cornerRadius)
    }
    
    // MARK: - Children Container
    
    private func childrenContainer(children: [MindMapNode]) -> some View {
        HStack(alignment: .top, spacing: Spacing.sectionSpacing) {
            // Vertical branch line for depth >= 1
            if depth >= 1 {
                Rectangle()
                    .fill(Theme.scribeRed.opacity(0.5))
                    .frame(width: 2)
                    .padding(.leading, Spacing.contentPadding)
            } else {
                Spacer()
                    .frame(width: 0)
            }
            
            // Children nodes
            VStack(alignment: .leading, spacing: Spacing.contentPadding) {
                ForEach(children, id: \.id) { child in
                    MindMapNodeView(node: child, depth: depth + 1)
                }
            }
        }
    }
    
    // MARK: - Styling Helpers
    
    private var nodeFont: Font {
        switch depth {
        case 0:
            return Typography.title2
        case 1:
            return Typography.headline
        default:
            return Typography.body
        }
    }
    
    private var nodeTextColor: Color {
        depth >= 2 ? Theme.accentGray : .white
    }
}