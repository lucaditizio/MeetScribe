import SwiftUI

@available(iOS 18.0, *)
public struct AgentGeneratingView: View {
    @Bindable var presenter: AgentGeneratingPresenter
    
    @State private var animateMesh = false
    @State private var circleScale: CGFloat = 1.0
    @State private var circleOpacity: Double = 0.6
    
    private let scribeRed = Color(red: 0.9, green: 0.2, blue: 0.2)
    private let obsidian = Color(red: 0.1, green: 0.1, blue: 0.11)
    private let indigo = Color(red: 0.3, green: 0.2, blue: 0.6)
    
    @Environment(\.dismiss) private var dismiss
    
    
    public init(presenter: AgentGeneratingPresenter) {
        self.presenter = presenter
    }
    
    public var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                pulsatingCircles
                stageLabel
                progressSection
            }
        }
        .onAppear {
            startAnimations()
            presenter.didTriggerViewReady()
        }
        .onChange(of: presenter.state.progress) { _, newValue in
            if newValue >= 1.0 && presenter.state.error == nil && presenter.state.isProcessing {
                dismiss()
            }
        }
        .alert(
            "Pipeline Error",
            isPresented: Binding(
                get: { presenter.state.error != nil },
                set: { if !$0 { presenter.state.error = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            if let error = presenter.state.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    private var backgroundGradient: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                .init(0, 0), .init(0.5, 0), .init(1, 0),
                .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
                .init(0, 1), .init(0.5, 1), .init(1, 1)
            ],
            colors: [
                obsidian, scribeRed, indigo,
                scribeRed, obsidian, indigo,
                indigo, scribeRed, obsidian
            ],
            background: obsidian
        )
    }
    
    private var pulsatingCircles: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(circleOpacity))
                .frame(width: 140, height: 140)
                .scaleEffect(circleScale)
            
            Circle()
                .fill(Color.white.opacity(circleOpacity * 0.7))
                .frame(width: 100, height: 100)
                .scaleEffect(circleScale * 0.85)
            
            Circle()
                .fill(Color.white.opacity(circleOpacity * 0.5))
                .frame(width: 80, height: 80)
                .scaleEffect(circleScale * 0.7)
            
            Image(systemName: "waveform.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundStyle(Color.white.opacity(0.8))
        }
    }
    
    private var stageLabel: some View {
        Text(presenter.state.currentStage.rawValue)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(Color.white.opacity(0.7))
    }
    
    private var progressSection: some View {
        VStack(spacing: 16) {
            progressText
            progressBar
        }
    }
    
    @ViewBuilder
    private var progressText: some View {
        let percentage = Int(presenter.state.progress * 100)
        Text("\(percentage)%")
            .font(.title3)
            .fontWeight(.medium)
            .foregroundStyle(Color.white)
            .contentTransition(.numericText())
    }
    
    private var progressBar: some View {
        Capsule()
            .fill(Color.white.opacity(0.3))
            .frame(width: 250, height: 6)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(Color.white)
                    .frame(width: 250 * presenter.state.progress, height: 6)
            }
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            animateMesh = true
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            circleScale = 1.1
            circleOpacity = 0.4
        }
    }
}

