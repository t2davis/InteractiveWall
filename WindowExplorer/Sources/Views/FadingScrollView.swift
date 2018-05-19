//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


private enum ScrollPosition {
    case top
    case bottom
    case middle
}


class FadingScrollView: NSScrollView {

    private var currentPosition = ScrollPosition.top

    private struct Constants {
        static let fadePercentage = 0.035
    }


    // MARK: API

    func updateGradient() {
<<<<<<< HEAD
        guard canScroll else {
            return
        }

        if hasReachedBottom {
            updateGradientProperty(for: .bottom)
        } else if hasReachedTop {
            updateGradientProperty(for: .top)
        } else {
            updateGradientProperty(for: .middle)
=======
        if canScroll {
            if hasReachedBottom {
                updateGradientProperty(position: .bottom)
            } else if hasReachedTop {
                updateGradientProperty(position: .top)
            } else {
                updateGradientProperty(position: .middle)
            }
>>>>>>> Working for search view controller, need to adjust height to expected values and check for related
        }
    }


    // MARK: Overrides

    override func layout() {
        super.layout()
        updateGradient()
    }


    // MARK: Helpers

    private func updateGradientProperty(for position: ScrollPosition ) {
        if currentPosition == position {
            return
        }

        currentPosition = position
        let transparent = NSColor.clear.cgColor
        let opaque = style.darkBackground.cgColor
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = NSRect(x: bounds.origin.x, y: 0, width: bounds.size.width, height: bounds.size.height)

        switch position {
        case .top:
            gradientLayer.colors = [opaque, transparent]
            gradientLayer.locations = [NSNumber(value: 1.0 - Constants.fadePercentage), 1.0]
        case .bottom:
            gradientLayer.colors = [transparent, opaque]
            gradientLayer.locations = [0.0, NSNumber(value: Constants.fadePercentage)]
        case .middle:
            gradientLayer.colors = [transparent, opaque, opaque, transparent]
            gradientLayer.locations = [0.0, NSNumber(value: Constants.fadePercentage), NSNumber(value: 1.0 - Constants.fadePercentage), 1.0]
        }

        layer?.mask = gradientLayer
    }
}
