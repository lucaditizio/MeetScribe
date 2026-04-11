import Foundation
import UIKit

public final class DeviceSettingsAssembly {
    public static func createModule() -> (view: UIViewController, module: DeviceSettingsModuleInput) {
        let interactor = DeviceSettingsInteractor()
        let router = DeviceSettingsRouter(viewController: nil)
        let presenter = DeviceSettingsPresenter(
            view: nil,
            interactor: interactor,
            router: router
        )
        
        interactor.output = presenter as? DeviceSettingsInteractorOutput
        
        return (presenter as! UIViewController, presenter)
    }
}
