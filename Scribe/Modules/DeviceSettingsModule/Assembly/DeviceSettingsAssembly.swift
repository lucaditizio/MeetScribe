import Foundation

/// Assembly for DeviceSettingsModule.
/// Creates a SwiftUI-native VIPER stack by accepting real BLE services
/// injected from AppAssembly/ServiceRegistry.
public final class DeviceSettingsAssembly {

    public static func createModule(
        scanner: BluetoothDeviceScannerProtocol,
        connectionManager: DeviceConnectionManagerProtocol
    ) -> DeviceSettingsPresenter {
        let interactor = DeviceSettingsInteractor(
            scanner: scanner,
            connectionManager: connectionManager
        )
        let router = DeviceSettingsRouter(viewController: nil)
        let presenter = DeviceSettingsPresenter(
            view: nil,
            interactor: interactor,
            router: router
        )
        interactor.output = presenter

        return presenter
    }
}
