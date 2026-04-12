import Foundation
import SwiftUI

@Observable
public final class DeviceSettingsPresenter: DeviceSettingsModuleInput,
                                            DeviceSettingsViewOutput,
                                            DeviceSettingsInteractorOutput {
    public var state = DeviceSettingsState()
    public weak var view: (any DeviceSettingsViewInput)?
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

    // MARK: - DeviceSettingsViewInput (Presenter → View display)

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

    // MARK: - DeviceSettingsInteractorOutput (Interactor → Presenter callbacks)

    public func didDiscoverDevices(_ devices: [DeviceSettingsBluetoothDevice]) {
        displayDevices(devices)
    }

    public func didUpdateConnectionState(_ state: DeviceSettingsConnectionState) {
        displayConnectionState(state)
    }

    public func didFailWithError(_ error: Error) {
        displayError(error)
    }

    // MARK: - DeviceSettingsViewOutput (View → Presenter user actions)

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
