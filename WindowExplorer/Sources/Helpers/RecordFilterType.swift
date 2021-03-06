//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum RecordFilterType {
    case image
    case video
    case school
    case artifact
    case event
    case organization
    case theme
    case individual
    case collection
    case all

    var title: String? {
        if let recordType = recordType {
            return recordType.title
        }

        switch self {
        case .image:
            return "IMAGES"
        case .video:
            return "VIDEOS"
        default:
            return nil
        }
    }

    var color: NSColor {
        if let recordType = recordType {
            return recordType.color
        }

        return .white
    }

    var placeholder: NSImage? {
        if let recordType = recordType {
            return recordType.placeholder
        }

        switch self {
        case .image:
            return NSImage(named: "image-icon")
        case .video:
            return NSImage(named: "video-icon")
        default:
            return nil
        }
    }

    var recordType: RecordType? {
        switch self {
        case .image, .video, .all:
            return nil
        case .school:
            return .school
        case .event:
            return .event
        case .organization:
            return .organization
        case .artifact:
            return .artifact
        case .theme:
            return .theme
        case .individual:
            return .individual
        case .collection:
            return .collection
        }
    }

    var layout: RelatedItemViewLayout {
        switch self {
        case .image:
            return RelatedItemViewLayout.images
        case .video:
            return RelatedItemViewLayout.videos
        default:
            return RelatedItemViewLayout.list
        }
    }

    static var recordFilterValues: [RecordFilterType] {
        return [.image, .video, .collection, .school, .event, .organization, .artifact, .individual, .theme]
    }
}
