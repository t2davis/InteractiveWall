//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class BorderControl: NSView {
    let borderColor = style.borderColor.cgColor
    var isVisible: Bool = true {
        didSet {
            refresh()
        }
    }


    // MARK: Init

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }


    // MARK: Setup

    private func setupLayers() {
        wantsLayer = true
        layer?.backgroundColor = borderColor

        isHidden = !isVisible
    }


    // MARK: Helpers

    private func refresh() {
        isHidden = !isVisible
    }
}
