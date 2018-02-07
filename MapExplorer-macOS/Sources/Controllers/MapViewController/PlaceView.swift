//  Copyright © 2018 slant. All rights reserved.

import MapKit
import AppKit

class PlaceView: MKAnnotationView {
    static let identifier = "PlaceView"

    var didTapCallout: ((Place)->())?

    override var annotation: MKAnnotation? {
        willSet {
            if let place = newValue as? Place {
                clusteringIdentifier = "place"
                canShowCallout = true
                displayPriority = .defaultHigh
                image = NSImage(named: place.discipline.rawValue)
                rightCalloutAccessoryView = NSButton(title: "Show", target: self, action: #selector(calloutButtonSelected))
            }
        }
    }

    @objc
    private func calloutButtonSelected() {
        if let place = annotation as? Place {
            didTapCallout?(place)
        }
    }
}
