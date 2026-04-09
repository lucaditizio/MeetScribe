import SwiftUI
import SwiftData

@main
struct ScribeApp: App {
    var body: some Scene {
        WindowGroup {
            AppAssembly.shared.makeRecordingListModule(output: nil)
        }
        .modelContainer(SwiftDataModelContainer.shared)
    }
}