//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class MenuButton: NSView {
    static let leftMenuButton = "MenuButtonLeft"
    static let rightMenuButton = "MenuButtonRight"

    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var buttonView: NSView!
    @IBOutlet weak var titleField: NSTextField!
    @IBOutlet weak var lockIcon: NSImageView!

    private var side = MenuSide.left
    private(set) var type: MenuButtonType!
    private(set) var selected = false
    private(set) var locked = false

    override var intrinsicContentSize: NSSize {
        return contentView.frame.size
    }

    private struct Constants {
        static let imageTransitionDuration = 0.5
    }


    // MARK: Init

    convenience init(frame: CGRect, side: MenuSide) {
        self.init(frame: frame)
        self.side = side
        let nib = side == .left ? MenuButton.leftMenuButton : MenuButton.rightMenuButton
        setup(nib: nib)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("Must use convenience init to create buttons on each side.")
    }


    // MARK: Setup

    private func setup(nib: NSNib.Name) {
        Bundle.main.loadNibNamed(nib, owner: self, topLevelObjects: nil)
        addSubview(contentView)
        contentView.frame = frame
        contentView.autoresizingMask = [.width, .height]
        buttonView.wantsLayer = true
    }


    // MARK: API

    func set(type: MenuButtonType) {
        if type == self.type {
            return
        }

        self.type = type
        buttonView.layer?.contents = type.image(selected: false, side: side)
        updateTitle()
    }

    func set(selected: Bool) {
        if selected == self.selected {
            return
        }

        self.selected = selected
        buttonView.layer?.contents = type.image(selected: selected, side: side)
        updateTitle()
    }

    func set(locked: Bool) {
        if locked == self.locked {
            return
        }

        self.locked = locked
        updateTitle()

        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = Constants.imageTransitionDuration
            self?.lockIcon.animator().isHidden = !locked
        })
    }


    // MARK: Helpers

    private func updateTitle() {
        let title = type.title(selected: selected, locked: locked)
        var attributes = style.windowTitleAttributes
        attributes[.foregroundColor] = selected ? style.menuTintColor : style.defaultBorderColor
        titleField.attributedStringValue = NSAttributedString(string: title, attributes: attributes)
    }
}
