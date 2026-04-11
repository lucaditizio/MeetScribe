import SwiftUI

/// Passive VIPER View: reads state from Presenter, forwards user actions to Presenter
public struct SummaryTabView: View {
    // MARK: - Properties
    
    /// Strong reference to Presenter (output)
    public var output: SummaryViewOutput
    
    /// State from Presenter (read-only, updated via Presenter)
    @State internal var state: SummaryState
    
    // MARK: - Init
    
    public init(output: SummaryViewOutput) {
        self.output = output
        self._state = State(initialValue: SummaryState())
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // Background
            Theme.obsidian
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if state.topicSections.isEmpty && state.actionItems.isEmpty {
                    emptyStateView
                } else {
                    summaryContentView
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            output.didTriggerViewReady()
        }
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var summaryContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sectionSpacing) {
                // Topic Sections
                if !state.topicSections.isEmpty {
                    topicSectionsView
                }
                
                // Action Items
                if !state.actionItems.isEmpty {
                    actionItemsView
                }
            }
            .padding(Spacing.cardPadding)
        }
    }
    
    // MARK: - Topic Sections
    
    private var topicSectionsView: some View {
        VStack(alignment: .leading, spacing: Spacing.contentPadding) {
            ForEach(state.topicSections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    // Section title - headline bold
                    Text(section.title)
                        .font(Typography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // Section content - body
                    Text(section.content)
                        .font(Typography.body)
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                }
                .padding(Spacing.contentPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .scribeCardStyle()
            }
        }
    }
    
    // MARK: - Action Items
    
    private var actionItemsView: some View {
        VStack(alignment: .leading, spacing: Spacing.contentPadding) {
            // Action Items heading
            Text("Action Items")
                .font(Typography.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.horizontal, Spacing.contentPadding)
            
            VStack(alignment: .leading, spacing: Spacing.contentPadding) {
                ForEach(state.actionItems, id: \.self) { item in
                    HStack(alignment: .top, spacing: 12) {
                        // Checkbox indicator
                        Image(systemName: "circle")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.scribeRed)
                        
                        Text(item)
                            .font(Typography.body)
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                    }
                    .padding(Spacing.contentPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.cardBackgroundDark)
                    .cornerRadius(Theme.cornerRadius)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Theme.accentGray)
            
            Text("No summary available")
                .font(Typography.headline)
                .foregroundColor(Theme.accentGray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}