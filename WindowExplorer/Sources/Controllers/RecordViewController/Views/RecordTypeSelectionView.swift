//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit


class RecordTypeSelectionView: NSView {

    var selectionCallback: ((RecordType?) -> Void)?

    @IBOutlet weak var stackview: NSStackView!
    private var selectedView: NSView? {
        didSet {
            unselect(oldValue)
        }
    }

    private struct Constants {
        static let imageTransitionDuration = 0.5
    }


    // MARK: Init

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        wantsLayer = true
        layer?.backgroundColor = CGColor.clear
    }


    // MARK: API

    func initialize(with record: RecordDisplayable, manager: GestureManager) {
        // Only display views if the record has related items of that type
        let relatedTypesForRecord = record.recordGroups.filter { !$0.records.isEmpty }.map { $0.type }

        relatedTypesForRecord.forEach { type in
            let view = NSView()
            view.wantsLayer = true
            view.layer?.contents = type.placeholder.tinted(with: style.unselectedRecordIcon)
            stackview.addView(view, in: .center)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.heightAnchor.constraint(equalTo: stackview.heightAnchor).isActive = true
            view.widthAnchor.constraint(equalTo: view.heightAnchor).isActive = true
            addGesture(to: view, in: manager, for: type)
        }
    }


    // MARK: Helpers

    private func addGesture(to view: NSView, in manager: GestureManager, for type: RecordType) {
        let tapGesture = TapGestureRecognizer()
        manager.add(tapGesture, to: view)

        tapGesture.gestureUpdated = { [weak self] tap in
            if let strongSelf = self, tap.state == .ended {
                // If already selected, deselect
                guard strongSelf.selectedView != view else {
                    strongSelf.selectedView = nil
                    strongSelf.selectionCallback?(nil)
                    return
                }

                // Select the view
                view.transition(to: type.placeholder.tinted(with: type.color), duration: Constants.imageTransitionDuration)
                strongSelf.selectedView = view
                strongSelf.selectionCallback?(type)
            }
        }
    }

    private func unselect(_ view: NSView?) {
        guard let view = view, let image = view.layer?.contents as? NSImage else {
            return
        }

        view.transition(to: image.tinted(with: style.unselectedRecordIcon), duration: Constants.imageTransitionDuration)
    }
}