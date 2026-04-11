import SwiftUI

public struct RecordingCardView: View {
    let recording: Recording
    let onTap: () -> Void
    let onDelete: () -> Void
    
    public init(recording: Recording, onTap: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.recording = recording
        self.onTap = onTap
        self.onDelete = onDelete
    }
    
    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recording.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(formattedDate(recording.date))
                            .font(.subheadline)
                            .foregroundColor(Theme.accentGray)
                    }
                    
                    Spacer()
                    
                    // Source badge
                    Text(recording.source.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.cardBackgroundDark)
                        .cornerRadius(8)
                        .foregroundColor(Theme.accentGray)
                }
                
                HStack {
                    Text(formattedDuration(recording.duration))
                        .font(.caption)
                        .foregroundColor(Theme.accentGray)
                    
                    Spacer()
                    
                    // Delete button
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(Theme.scribeRed)
                    }
                }
            }
            .padding(Spacing.cardPadding)
            .background(Theme.cardBackgroundDark)
            .cornerRadius(Theme.cornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}