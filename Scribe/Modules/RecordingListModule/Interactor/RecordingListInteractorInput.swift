import Foundation
import Combine

/// Protocol: Presenter → Interactor (business logic)
public protocol RecordingListInteractorInput: AnyObject {
    var isRecordingPublisher: AnyPublisher<Bool, Never> { get }
    func obtainRecordings()
    func deleteRecording(id: String)
    func startRecording()
    func stopRecording()
}
