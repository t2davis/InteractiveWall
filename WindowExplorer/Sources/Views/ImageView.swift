//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


enum ImageScaling {
    case aspectFill
    case center
    case resize
    case aspectFit

    var contentsGravity: String {
        switch self {
        case .aspectFill:
            return kCAGravityResizeAspectFill
        case .center:
            return kCAGravityCenter
        case .resize:
            return kCAGravityResize
        case .aspectFit:
            return kCAGravityResizeAspect
        }
    }
}


class ImageView: NSView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.layer = CALayer()
        self.layer?.contentsGravity = kCAGravityResizeAspectFill
        self.wantsLayer = true
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.layer = CALayer()
        self.layer?.contentsGravity = kCAGravityResizeAspectFill
        self.wantsLayer = true
    }


    // MARK: API

    func set(_ image: NSImage?, scaling: ImageScaling = .aspectFill) {
        layer?.contentsGravity = scaling.contentsGravity
        layer?.contents = image
    }

    func transition(_ image: NSImage?, duration: TimeInterval, scaling: ImageScaling = .aspectFill, type: String = kCATransitionFade) {
        let transition = CATransition()
        transition.duration = duration
        transition.type = type
        layer?.add(transition, forKey: "contents")
        layer?.contentsGravity = scaling.contentsGravity

        if let contentScale = layer?.contentsScale, contentScale < 2.0 {
            layer?.contentsScale = 2.0
        }

        layer?.contents = image
    }
}
