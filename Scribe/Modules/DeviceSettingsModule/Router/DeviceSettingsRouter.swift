import Foundation
import SwiftUI

public final class DeviceSettingsRouter: DeviceSettingsRouterInput {
    private weak var viewController: UIViewController?
    
    public init(viewController: UIViewController?) {
        self.viewController = viewController
    }
    
    public func closeCurrentModule() {
        viewController?.dismiss(animated: true)
    }
}
