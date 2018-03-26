//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit

protocol Record {
    var type: RecordType { get }
    var id: Int { get }
    var coordinate: CLLocationCoordinate2D { get }
}

enum RecordType: String {
    case school
    case event
}
