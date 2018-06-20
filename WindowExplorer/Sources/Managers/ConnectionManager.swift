//  Copyright © 2018 JABT. All rights reserved.

import Foundation


typealias AppState = (pair: Int?, group: Int?, type: ApplicationType)


/// Class used to determine which application's are paired with one another.
final class ConnectionManager {

    static let instance = ConnectionManager()

    /// The state for each app indexed by it's appID
    private var stateForApp: [AppState]

    /// A timer used to reset the entire installation when no activity has been detected
    private weak var resetTimer: Foundation.Timer?

    private struct Constants {
        static let resetTimeoutPeriod: TimeInterval = 180
    }

    private struct Keys {
        static let id = "id"
        static let map = "map"
        static let group = "group"
        static let gesture = "gestureType"
        static let animated = "amimated"
    }


    // MARK: Init

    /// Use Singleton
    private init() {
        let numberOfApps = Configuration.appsPerScreen * Configuration.numberOfScreens
        let initialState = AppState(pair: nil, group: nil, type: .mapExplorer)
        self.stateForApp = Array(repeating: initialState, count: numberOfApps)
    }


    // MARK: API

    func pairForApp(id: Int) -> Int? {
        return stateForApp.at(index: id)?.pair
    }

    func groupForApp(id: Int) -> Int? {
        return stateForApp.at(index: id)?.group
    }

    func typeForApp(id: Int) -> ApplicationType? {
        return stateForApp.at(index: id)?.type
    }

    func registerForNotifications() {
        for notification in ApplicationNotification.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
        for notification in MapNotification.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
    }


    // MARK: Notifications

    @objc
    private func handleNotification(_ notification: NSNotification) {
        guard let info = notification.userInfo, let id = info[Keys.id] as? Int else {
            return
        }

        let group = info[Keys.group] as? Int

        switch notification.name {
        case ApplicationNotification.launchMapExplorer.name:
            setAppType(.mapExplorer, from: id, group: group)
        case ApplicationNotification.launchTimeline.name:
            setAppType(.timeline, from: id, group: group)
        case ApplicationNotification.launchNodeNetwork.name:
            setAppType(.nodeNetwork, from: id, group: group)
        case MapNotification.position.name:
            if let group = group, let gesture = info[Keys.gesture] as? String, let state = GestureState(rawValue: gesture) {
                setAppState(from: id, group: group, for: .mapExplorer, momentum: state == .momentum)
            }
        case MapNotification.unpair.name:
            unpair(from: id)
        case MapNotification.ungroup.name:
            beginResetTimer()
            if let group = group {
                ungroup(from: group, with: .mapExplorer)
            }
        default:
            return
        }
    }


    // MARK: Helpers

    private func setAppType(_ type: ApplicationType, from id: Int, group: Int?) {
        for (app, state) in stateForApp.enumerated() {
            // Check for current group
            if let appGroup = state.group, appGroup == group {
                // Check for current pair
                if let appPair = state.pair {
                    // Check if incoming id is closer than current pair
                    if abs(app - id) < abs(app - appPair) {
                        stateForApp[app] = AppState(pair: nil, group: id, type: type)
                    }
                } else {
                    stateForApp[app] = AppState(pair: nil, group: id, type: type)
                }
            } else if state.group == nil, state.type == type {
                stateForApp[app] = AppState(pair: nil, group: id, type: type)
            }
        }
        updateBorders()
    }

    /// Set all app states accordingly when a app sends its position
    private func setAppState(from id: Int, group: Int, for type: ApplicationType, momentum: Bool) {
        for (app, state) in stateForApp.enumerated() {
            // Only receive updates for apps of the same type
            if type != state.type {
                continue
            }

            // Check for current group
            if let appGroup = state.group, appGroup == group {
                // Once paired with own screen, don't group to other screens
                if screen(of: appGroup) == screen(of: app) && screen(of: app) != screen(of: id) {
                    continue
                }
                // Only listen to the closest screen once paired
                if abs(screen(of: app) - screen(of: id)) >= abs(screen(of: app) - screen(of: appGroup)), screen(of: id) != screen(of: group) {
                    continue
                }
                // Check for current pair
                if let appPair = state.pair {
                    // Check if incoming id is closer than current pair
                    if abs(app - id) < abs(app - appPair) {
                        stateForApp[app] = AppState(pair: id, group: id, type: state.type)
                    }
                } else if !momentum {
                    stateForApp[app] = AppState(pair: id, group: id, type: state.type)
                }
            } else if state.group == nil {
                stateForApp[app] = AppState(pair: id, group: id, type: state.type)
            }
        }
        updateBorders()
    }

    /// If paired to the given id, will unpair else ignore
    private func unpair(from id: Int) {
        for (app, state) in stateForApp.enumerated() {
            if let currentPair = state.pair, currentPair == id {
                stateForApp[app] = AppState(pair: nil, group: state.group, type: state.type)
            }
        }
    }

    /// Ungroup all apps from group with given id
    private func ungroup(from id: Int, with type: ApplicationType) {
        // Clear groups with given id
        for (app, state) in stateForApp.enumerated() {
            if let currentGroup = state.group, currentGroup == id {
                stateForApp[app] = AppState(pair: nil, group: nil, type: state.type)
            }
        }
        // Find the closest group for all ungrouped apps of the same type
        for (app, state) in stateForApp.enumerated() {
            if state.group == nil {
                let group = findGroupForApp(id: app, of: type)
                stateForApp[app] = AppState(pair: nil, group: group, type: state.type)
            }
        }
    }

    /// Find the closest group to a given app
    private func findGroupForApp(id: Int, of type: ApplicationType) -> Int? {
        let sortedAppStates = stateForApp.enumerated().sorted {
            if screen(of: $0.0) == screen(of: $1.0) {
                return abs(id - $0.0) < abs(id - $1.0)
            }
            return abs(screen(of: id) - screen(of: $0.0)) < abs(screen(of: id) - screen(of: $1.0))
        }

        let externalApps = sortedAppStates.dropFirst()
        let filteredApps = externalApps.filter { $0.1.type == type }
        return filteredApps.compactMap({ $0.1.group }).first
    }

    /// Returns the screen id of the given app id
    private func screen(of id: Int) -> Int {
        return (id / Configuration.appsPerScreen) + 1
    }

    /// Shows / Hides borders between applications as necessary given the state of each application
    private func updateBorders() {
        // TODO: Check each state and show / hide each border if necessary
    }

    private func beginResetTimer() {
        resetTimer?.invalidate()
        resetTimer = Timer.scheduledTimer(withTimeInterval: Constants.resetTimeoutPeriod, repeats: false) { [weak self] _ in
            self?.resetTimerFired()
        }
    }

    private func resetTimerFired() {
        let info: JSON = [Keys.id: 0]
        DistributedNotificationCenter.default().postNotificationName(MapNotification.reset.name, object: nil, userInfo: info, deliverImmediately: true)
    }
}