//  Copyright © 2018 JABT. All rights reserved.

import Foundation

class Theme {

    let id: Int
    let title: String
    let type = RecordType.theme
    let description: String?
    var relatedSchools = [School]()
    var relatedOrganizations = [Organization]()
    var relatedArtifacts = [Artifact]()
    var relatedEvents = [Event]()
    lazy var priority = PriorityOrder.priority(for: self)

    private struct Keys {
        static let id = "id"
        static let title = "title"
        static let description = "description"
        static let schools = "schools"
        static let organizations = "organizations"
        static let artifacts = "artifacts"
        static let events = "events"
    }


    // MARK: Init

    init?(json: JSON) {
        guard let id = json[Keys.id] as? Int, let title = json[Keys.title] as? String else {
            return nil
        }

        self.id = id
        self.title = title
        self.description = json[Keys.description] as? String

        if let schoolsJSON = json[Keys.schools] as? [JSON] {
            let schools = schoolsJSON.compactMap { School(json: $0) }
            self.relatedSchools = schools
        }
        if let organizationsJSON = json[Keys.organizations] as? [JSON] {
            let organizations = organizationsJSON.compactMap { Organization(json: $0) }
            self.relatedOrganizations = organizations
        }
        if let artifactsJSON = json[Keys.artifacts] as? [JSON] {
            let artifacts = artifactsJSON.compactMap { Artifact(json: $0) }
            self.relatedArtifacts = artifacts
        }
        if let eventsJSON = json[Keys.events] as? [JSON] {
            let events = eventsJSON.compactMap { Event(json: $0) }
            self.relatedEvents = events
        }
    }
}
