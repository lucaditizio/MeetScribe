import Foundation
import Combine
import SwiftUI

// MARK: - Base VIPER Protocols

/// Base protocol for all module inputs
public protocol ModuleInput: AnyObject {}

/// Base protocol for all module outputs
public protocol ModuleOutput: AnyObject {
    associatedtype OutputType
}

/// Base protocol for all module Assemblies
public protocol AssemblyProtocol {
    associatedtype ViewType: SwiftUI.View
    func assemble(output: (any ModuleOutput)?) -> ViewType
}

// MARK: - RecordingListModule Protocols

public protocol RecordingListViewProtocol: AnyObject {
    var output: RecordingListInteractorProtocol? { get set }
    func displayRecordings(_ recordings: [RecordingViewModel])
    func showRecordingState(isRecording: Bool)
}

public protocol RecordingListInteractorProtocol: AnyObject {
    var output: RecordingListPresenterProtocol? { get set }
    func obtainRecordings()
    func startRecording(source: RecordingSource)
    func stopRecording()
    func deleteRecording(id: UUID)
}

public protocol RecordingListPresenterProtocol: AnyObject {
    var view: RecordingListViewProtocol? { get set }
    var interactor: RecordingListInteractorProtocol? { get set }
    var router: RecordingListRouterProtocol? { get set }
    
    func viewDidLoad()
    func didTapRecord(source: RecordingSource)
    func didTapStopRecording()
    func didSelectRecording(id: UUID)
    func didTapDeleteRecording(id: UUID)
    func didObtainRecordings(_ recordings: [Recording])
}

public protocol RecordingListRouterProtocol: AnyObject {
    var viewController: UIViewController? { get set }
    func openRecordingDetail(recordingId: UUID)
    func openDeviceSettings()
}

// MARK: - RecordingDetailModule Protocols

public protocol RecordingDetailViewProtocol: AnyObject {
    var output: RecordingDetailInteractorProtocol? { get set }
    func displayRecording(_ recording: RecordingDetailViewModel)
    func showTranscript(_ text: String)
    func showSummary(_ summary: SummaryViewModel)
    func showMindMap(_ nodes: [MindMapNodeViewModel])
}

public protocol RecordingDetailInteractorProtocol: AnyObject {
    var output: RecordingDetailPresenterProtocol? { get set }
    func obtainRecording(id: UUID)
    func deleteRecording()
    func generateSummary()
    func generateMindMap()
}

public protocol RecordingDetailPresenterProtocol: AnyObject {
    var view: RecordingDetailViewProtocol? { get set }
    var interactor: RecordingDetailInteractorProtocol? { get set }
    var router: RecordingDetailRouterProtocol? { get set }
    
    func viewDidLoad()
    func didTapDelete()
    func didTapGenerateSummary()
    func didTapGenerateMindMap()
    func didTapPlay()
    func didObtainRecording(_ recording: Recording)
}

public protocol RecordingDetailRouterProtocol: AnyObject {
    var viewController: UIViewController? { get set }
    func embedWaveformPlayback(recordingId: UUID)
    func embedTranscript(transcript: Transcript)
    func closeModule()
}

// MARK: - WaveformPlaybackModule Protocols

public protocol WaveformPlaybackViewProtocol: AnyObject {
    var output: WaveformPlaybackInteractorProtocol? { get set }
    func displayWaveform(_ samples: [AudioSample])
    func updatePlaybackProgress(_ progress: Double)
    func updatePlaybackState(_ state: PlaybackState)
}

public protocol WaveformPlaybackInteractorProtocol: AnyObject {
    var output: WaveformPlaybackPresenterProtocol? { get set }
    func loadAudio(url: URL)
    func play()
    func pause()
    func seek(to progress: Double)
}

public protocol WaveformPlaybackPresenterProtocol: AnyObject {
    var view: WaveformPlaybackViewProtocol? { get set }
    var interactor: WaveformPlaybackInteractorProtocol? { get set }
    
    func viewDidLoad()
    func didTapPlayPause()
    func didSeek(to progress: Double)
    func didUpdatePlaybackState(_ state: PlaybackState)
    func didUpdateProgress(_ currentTime: TimeInterval, duration: TimeInterval)
}

// MARK: - View Models

public struct RecordingViewModel: Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let date: String
    public let duration: String
    public let source: RecordingSource
    
    public init(id: UUID, title: String, date: String, duration: String, source: RecordingSource) {
        self.id = id
        self.title = title
        self.date = date
        self.duration = duration
        self.source = source
    }
}

public struct RecordingDetailViewModel: Sendable {
    public let id: UUID
    public let title: String
    public let date: String
    public let duration: String
    public let filePath: String
    
    public init(id: UUID, title: String, date: String, duration: String, filePath: String) {
        self.id = id
        self.title = title
        self.date = date
        self.duration = duration
        self.filePath = filePath
    }
}

public struct SummaryViewModel: Sendable {
    public let overview: String
    public let keyPoints: [String]
    public let actionItems: [String]
    
    public init(overview: String, keyPoints: [String], actionItems: [String]) {
        self.overview = overview
        self.keyPoints = keyPoints
        self.actionItems = actionItems
    }
}

public struct MindMapNodeViewModel: Identifiable, Sendable {
    public let id: UUID
    public let text: String
    public let level: Int
    public let children: [MindMapNodeViewModel]
    
    public init(id: UUID, text: String, level: Int, children: [MindMapNodeViewModel] = []) {
        self.id = id
        self.text = text
        self.level = level
        self.children = children
    }
}
