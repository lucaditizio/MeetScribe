import SwiftUI

/// SwiftUI-native VIPER View: binds to Presenter, forwards user actions to Presenter
public struct SummaryTabView: View {
    // MARK: - Properties
    
    /// Bindable Presenter (combines state + output)
    @Bindable var presenter: SummaryPresenter
    
    // MARK: - Init
    
    public init(presenter: SummaryPresenter) {
        self.presenter = presenter
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // Background
            Theme.obsidian
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if presenter.state.topicSections.isEmpty && presenter.state.actionItems.isEmpty {
                    emptyStateView
                } else {
                    summaryContentView
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            presenter.didTriggerViewReady()
        }
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var summaryContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sectionSpacing) {
                // Topic Sections
                if !presenter.state.topicSections.isEmpty {
                    topicSectionsView
                }
                
                // Action Items
                if !presenter.state.actionItems.isEmpty {
                    actionItemsView
                }
            }
            .padding(Spacing.cardPadding)
        }
    }
    
    // MARK: - Topic Sections
    
    private var topicSectionsView: some View {
        VStack(alignment: .leading, spacing: Spacing.contentPadding) {
            ForEach(presenter.state.topicSections) { section in
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
                ForEach(presenter.state.actionItems, id: \.self) { item in
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