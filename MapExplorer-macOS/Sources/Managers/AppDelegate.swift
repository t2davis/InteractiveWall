//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


struct Configuration {
    static let mapsPerScreen = 1
    static let numberOfScreens = 1
    static let touchScreenSize = CGSize(width: 21564, height: 12116)
}


var screenID = 0
var appID = 0


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let screenIndex = Int(CommandLine.arguments[1]) ?? 0
        let windowIndex = Int(CommandLine.arguments[2]) ?? 0
        screenID = screenIndex
        appID = windowIndex + (screenID - 1) * Configuration.mapsPerScreen

        let mapStoryboard = NSStoryboard(name: MapViewController.storyboard, bundle: nil)
        let mapController = mapStoryboard.instantiateInitialController() as! MapViewController
        let mapWindow: NSWindow
        let screen = NSScreen.screens[screenIndex]
        let screenWidth = screen.frame.width / CGFloat(Configuration.mapsPerScreen)
        let frame = NSRect(x: screen.frame.minX + screenWidth * CGFloat(windowIndex), y: screen.frame.minY, width: screenWidth, height: screen.frame.height)
        mapWindow = BorderlessWindow(frame: frame, controller: mapController)
        mapWindow.setFrame(frame, display: true)
        mapWindow.makeKeyAndOrderFront(self)

        /// Display the DemoViewController
//        let demoStoryboard = NSStoryboard(name: GestureDemoController.storyboard, bundle: nil)
//        let demoVC = demoStoryboard.instantiateInitialController() as! GestureDemoController
//        let demoWindow = NSWindow(contentViewController: demoVC)
//        demoWindow.title = "Demo Window"
//        demoWindow.makeKeyAndOrderFront(self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
