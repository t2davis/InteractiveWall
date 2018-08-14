//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class TimelineFlagView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "TimelineFlagView")

    @IBOutlet weak var flagView: NSView!
    @IBOutlet weak var flagPoleView: NSView!
    @IBOutlet weak var flagBottomView: NSView!
    @IBOutlet weak var flagTailView: NSView!
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var dateTextField: NSTextField!
    @IBOutlet weak var flagHeightConstraint: NSLayoutConstraint!

    var event: TimelineEvent! {
        didSet {
            load(event)
        }
    }

    private struct Constants {
        static let flagWidth: CGFloat = 180
        static let interItemMargin: CGFloat = 10
        static let dateFieldHeight: CGFloat = 20
    }


    // MARK: Init

    override func awakeFromNib() {
        super.awakeFromNib()
        view.wantsLayer = true
        flagView.wantsLayer = true
        flagPoleView.wantsLayer = true
        flagBottomView.wantsLayer = true
        flagTailView.wantsLayer = true
        flagView.layer?.backgroundColor = style.darkBackground.cgColor
    }


    // MARK: Helpers

    private func load(_ event: TimelineEvent) {
        flagPoleView.layer?.backgroundColor = event.type.color.cgColor
        flagBottomView.layer?.backgroundColor = event.type.color.cgColor
        flagTailView.layer?.backgroundColor = event.type.color.cgColor
        flagHeightConstraint.constant = TimelineFlagView.flagHeight(for: event)
        titleTextField.attributedStringValue = NSAttributedString(string: event.title, attributes: style.timelineTitleAttributes)
        dateTextField.attributedStringValue = NSAttributedString(string: event.dates.description, attributes: style.timelineDateAttributes)
    }

    static func flagHeight(for event: TimelineEvent) -> CGFloat {
        let textFieldWidth = Constants.flagWidth - Constants.interItemMargin * 2
        let title = NSAttributedString(string: event.title, attributes: style.timelineTitleAttributes)
        let titleHeight = title.height(containerWidth: textFieldWidth)
        let dateHeight = Constants.dateFieldHeight
        let margins = Constants.interItemMargin * 3

        return titleHeight + dateHeight + margins
    }
}