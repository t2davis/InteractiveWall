//  Copyright © 2018 JABT. All rights reserved.

import Foundation

enum WindowNotification: String {
    case school
    case event

    var name: Notification.Name {
        return Notification.Name(rawValue: rawValue)
    }

    static func with(_ record: Record) -> WindowNotification {
        switch record.type {
        case .school:
            return .school
        case .event:
            return .event
        }
    }
}
