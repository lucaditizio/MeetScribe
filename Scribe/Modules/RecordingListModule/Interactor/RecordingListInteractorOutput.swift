import Foundation

/// Protocol: Interactor → Presenter (results)
public protocol RecordingListInteractorOutput: AnyObject {
    func didObtainRecordings(_ recordings: [Recording])
    func didFailWithError(_ error: Error)
}
