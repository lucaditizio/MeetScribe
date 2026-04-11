import Foundation

@Observable
public final class DeviceSettingsPresenter: DeviceSettingsModuleInput, DeviceSettingsViewInput {
    public var state = DeviceSettingsState()
    private weak var view: DeviceSettingsViewInput?
    private let interactor: DeviceSettingsInteractorInput
    private let router: DeviceSettingsRouterInput
    
    public init(
        view: DeviceSettingsViewInput?,
        interactor: DeviceSettingsInteractorInput,
        router: DeviceSettingsRouterInput
    ) {
        self.view = view
        self.interactor = interactor
        self.router = router
    }
    
    public func displayDevices(_ devices: [DeviceSettingsBluetoothDevice]) {
        state.discoveredDevices = devices
        view?.displayDevices(devices)
    }
    
    public func displayConnectionState(_ state: DeviceSettingsConnectionState) {
        self.state.connectionState = state
        view?.displayConnectionState(state)
    }
    
    public func displayError(_ error: Error) {
        view?.displayError(error)
    }
    
    public func didTriggerViewReady() {
        interactor.startScan()
    }
    
    public func didTapScan() {
        interactor.startScan()
    }
    
    public func didTapDevice(_ device: DeviceSettingsBluetoothDevice) {
        interactor.connectToDevice(device)
    }
    
    public func didTapDisconnect() {
        interactor.disconnect()
    }
}
