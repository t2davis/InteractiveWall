//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

final class MenuManager {
    static let instance = MenuManager()

    // MenuViewControllers indexed by their associated appID
    private var menuForID = [Int: MenuViewController]()


    // MARK: Init

    /// Use singleton
    private init() {}


    // MARK: API

    func createMenus() {
        for screen in (1 ... Configuration.numberOfScreens) {
            let screenFrame = NSScreen.at(position: screen).frame

            for appIndex in (0 ..< Configuration.appsPerScreen) {
                let x = appIndex % 2 == 0 ? screenFrame.minX : screenFrame.maxX - style.menuWindowSize.width
                let y = screenFrame.midY - style.menuWindowSize.height / 2
                let borderXPosition = (screenFrame.size.width / 2) + screenFrame.origin.x - (style.borderSize.width / 2)

                if let menu = WindowManager.instance.display(.menu, at: CGPoint(x: x, y: y)) as? MenuViewController {
                    let appID = appIndex + ((screen - 1) * Configuration.appsPerScreen)
                    menu.set(appID: appID)
                    menuForID[appID] = menu
                }

                if appIndex % 2 == 1 {
                    let border = WindowManager.instance.display(.border, at: CGPoint(x: borderXPosition, y: screenFrame.minY)) as? BorderViewController
                    border?.isVisible(false)
                    border?.screenID = screen
                }
            }
        }
    }

    func menuForApp(id: Int) -> MenuViewController? {
        return menuForID[id]
    }
}
