import SwiftUI

public struct RecordButtonView: View {
    let isRecording: Bool
    let onTap: () -> Void
    
    public init(isRecording: Bool, onTap: @escaping () -> Void) {
        self.isRecording = isRecording
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(Theme.scribeRed.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .scaleEffect(isRecording ? 1.5 : 1.0)
                    .opacity(isRecording ? 0 : 0.8)
                    .animation(
                        isRecording ? .easeInOut(duration: 1.5).repeatForever(autoreverses: false) : .default,
                        value: isRecording
                    )

                Circle()
                    .fill(isRecording ? Theme.scribeRed.opacity(0.8) : Theme.scribeRed)
                    .frame(width: 70, height: 70)
                    .shadow(color: Theme.scribeRed.opacity(0.5), radius: 10, x: 0, y: 5)

                if isRecording {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }
}