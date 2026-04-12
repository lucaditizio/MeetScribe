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
                    .fill(Theme.scribeRed)
                    .frame(
                        width: Spacing.recordButtonOuterSize,
                        height: Spacing.recordButtonOuterSize
                    )
                
                if isRecording {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                }
            }
        }
    }
}