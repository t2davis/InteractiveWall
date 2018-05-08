//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


private struct ApplicationInfo {
    let action: ControlAction
    let applications: [NSRunningApplication]
}


class MasterViewController: NSViewController {
    static var instance: MasterViewController?

    @IBOutlet weak var leftScreen: NSView!
    @IBOutlet weak var middleScreen: NSView!
    @IBOutlet weak var rightScreen: NSView!
    @IBOutlet weak var leftScreenCheckbox: NSButton!
    @IBOutlet weak var middleScreenCheckbox: NSButton!
    @IBOutlet weak var rightScreenCheckbox: NSButton!
    @IBOutlet weak var actionSelectionButton: NSPopUpButton!

    private var infoForScreen = [Int: ApplicationInfo]()

    private var screens: [NSView] {
        return [leftScreen, middleScreen, rightScreen]
    }

    private var checkboxes: [NSButton] {
        return [leftScreenCheckbox, middleScreenCheckbox, rightScreenCheckbox]
    }

    private struct Constants {
        static let storyboard = NSStoryboard.Name(rawValue: "Master")
        static let windowTitle = "Control Center"
        static let screenBorderWidth: CGFloat = 12
        static let imageTransitionDuration = 2.0
        static let screenBackgroundColor = CGColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)
    }


    // MARK: Init

    /// Used to lazy load static singleton instance
    static func instantiate() {
        guard MasterViewController.instance == nil else {
            return
        }

        let storyboard = NSStoryboard(name: Constants.storyboard, bundle: .main)
        let controller = storyboard.instantiateInitialController() as! MasterViewController
        let screen = NSScreen.main!
        let window = NSWindow()
        let origin = CGPoint(x: screen.frame.midX - controller.view.frame.width/2, y: screen.frame.midY - controller.view.frame.height/2)
        window.contentViewController = controller
        window.title = Constants.windowTitle
        window.setFrame(CGRect(origin: origin, size: controller.view.frame.size), display: true)
        window.makeKeyAndOrderFront(self)
        MasterViewController.instance = controller
    }

    deinit {
        close()
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScreens()
        setupCheckboxes()
        setupActionButton()
        registerForNotifications()
    }


    // MARK: API

    /// Terminates all currently running applications
    func close() {
        screens.enumerated().forEach { screen, _ in
            terminate(screen: screen)
        }
    }


    // MARK: Setup

    private func setupScreens() {
        screens.enumerated().forEach { screen, screenView in
            screenView.layer?.backgroundColor = Constants.screenBackgroundColor
            screenView.layer?.borderWidth = Constants.screenBorderWidth
            screenView.layer?.borderColor = CGColor.black
            let action = connected(screen: screen) ? ControlAction.closeApplication : ControlAction.disconnected
            apply(action, toScreen: screen)
        }
    }

    private func setupCheckboxes() {
        checkboxes.enumerated().forEach { index, checkbox in
            let screenIsConnected = connected(screen: index)
            checkbox.isEnabled = screenIsConnected
            checkbox.state = screenIsConnected ? .on : .off
        }
    }

    private func setupActionButton() {
        actionSelectionButton.removeAllItems()
        ControlAction.allActions.forEach { action in
            actionSelectionButton.addItem(withTitle: action.title)
        }
    }

    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(screensDidChange(_:)), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }


    // MARK: IB-Actions
    
    @IBAction func applyButtonClicked(_ sender: NSButton) {
        guard let selectedAction = actionSelectionButton.selectedItem, let action = ControlAction(title: selectedAction.title) else {
            return
        }

        checkboxes.enumerated().forEach { index, checkbox in
            if checkbox.state == .on {
                apply(action, toScreen: index)
            }
        }
    }


    // MARK: Helpers

    private func apply(_ action: ControlAction, toScreen screen: Int) {
        // Ignore action if it's current
        if let currentInfo = infoForScreen[screen], currentInfo.action == action {
            return
        }

        // Clear currently running processes
        terminate(screen: screen)

        // Load new processes
        switch action {
        case .launchMapExplorer:
            launchMaps(screen: screen)
        case .launchTimeline, .closeApplication, .disconnected:
            infoForScreen[screen] = ApplicationInfo(action: action, applications: [])
        }

        transition(screen: screen, to: action)
    }

    /// Terminate the processes associated with the given screen
    private func terminate(screen: Int) {
        guard let info = infoForScreen[screen] else {
            return
        }

        info.applications.forEach { application in
            application.terminate()
        }
    }

    /// Launch MapExplorer on the given screen
    private func launchMaps(screen: Int) {
        var applications = [NSRunningApplication]()

        for map in 0 ..< Configuration.mapsPerScreen {
            if let application = open(.mapExplorer, screenID: screen + 1, appID: map) {
                applications.append(application)
            }
        }

        infoForScreen[screen] = ApplicationInfo(action: .launchMapExplorer, applications: applications)
    }

    /// Open a known application type with the required parameters
    @discardableResult
    private func open(_ application: ApplicationType, screenID: Int, appID: Int) -> NSRunningApplication? {
        let args = [String(screenID), String(appID)]

        do {
            let url = URL(fileURLWithPath: application.path)
            let config = [NSWorkspace.LaunchConfigurationKey.arguments: args]
            let application = try NSWorkspace.shared.launchApplication(at: url, options: .newInstance, configuration: config)
            return application
        } catch {
            print("Failed to open application at path: \(application.path).")
            return nil
        }
    }

    private func transition(screen: Int, to action: ControlAction) {
        if let screenView = screens.at(index: screen), let image = action.image {
            screenView.transition(to: image, duration: Constants.imageTransitionDuration)
        }
    }

    /// Returns true of the given screen is currently connected
    private func connected(screen: Int) -> Bool {
        return NSScreen.screens.count > screen + 1
    }

    @objc
    private func screensDidChange(_ notification: NSNotification) {
        infoForScreen.forEach { screen, info in
            if connected(screen: screen) && info.action == .disconnected {
                apply(.closeApplication, toScreen: screen)
            } else if !connected(screen: screen) {
                apply(.disconnected, toScreen: screen)
            }
        }

        // Update the state of the checkboxes
        setupCheckboxes()
    }
}
