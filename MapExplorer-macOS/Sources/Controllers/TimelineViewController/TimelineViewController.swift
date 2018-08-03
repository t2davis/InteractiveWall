//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import MapKit
import MONode
import PromiseKit
import AppKit


enum TimelineType {
    case month
    case year
    case decade
    case century

    var sectionWidth: Int {
        switch self {
        case .month:
            return 1920
        case .year:
            return 1920
        case .decade:
            return 192
        case .century:
            return 32
        }
    }

    var itemWidth: Int {
        switch self {
        case .month:
            return 240
        case .year:
            return 240
        case .decade:
            return 192
        case .century:
            return 32
        }
    }
}


class TimelineViewController: NSViewController, GestureResponder, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    static let storyboard = NSStoryboard.Name(rawValue: "Timeline")

    @IBOutlet weak var timelineBackgroundView: NSView!
    @IBOutlet weak var timelineCollectionView: FlippedCollectionView!
    @IBOutlet weak var timelineScrollView: NSScrollView!
    @IBOutlet weak var monthCollectionView: NSCollectionView!
    @IBOutlet weak var monthScrollView: NSScrollView!
    @IBOutlet weak var yearCollectionView: NSCollectionView!
    @IBOutlet weak var yearScrollView: NSScrollView!
    @IBOutlet weak var decadeCollectionView: NSCollectionView!
    @IBOutlet weak var decadeScrollView: NSScrollView!
    @IBOutlet weak var timelineIndicatorView: NSView!

    var gestureManager: GestureManager!
    var currentDate = Constants.initialDate
    var timelineType: TimelineType = .decade
    private var timelineHandler: TimelineHandler?
    private let source = TimelineDataSource()
    private var decades = [Int]()
    private var years = [Int]()
    private var selectedDecade: Int?
    private var selectedYear: Int?
    private var selectedMonth: Month?
    private var selectedViewForType = [TimelineType: TimelineControlItemView]()

    private struct Constants {
        static let timelineCellWidth: CGFloat = 20
        static let timelineSelectedCellWidth: CGFloat = 150
        static let animationDuration = 0.5
        static let controlItemWidth: CGFloat = 70
        static let timelineControlWidth: CGFloat = 490
        static let visibleControlItems = 7
        static let timelineControlItemWidth: CGFloat = 70
        static let timelineIndicatorBorderRadius: CGFloat = 8
        static let timelineIndicatorBorderWidth: CGFloat = 2
        static let initialDate = TimelineDate(day: CGFloat(0.5), month: Month.january.rawValue, year: 1880)
        static let fadePercentage = 0.1
    }

    private struct Keys {
        static let appID = "map"
        static let id = "id"
        static let group = "group"
        static let index = "index"
        static let state = "state"
        static let selection = "selection"
        static let position = "position"
    }


    // MARK: Init

    static func instance() -> TimelineViewController {
        let storyboard = NSStoryboard(name: TimelineViewController.storyboard, bundle: nil)
        return storyboard.instantiateInitialController() as! TimelineViewController
    }


    // MARK: API

    func fade(out: Bool) {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            timelineBackgroundView.animator().alphaValue = out ? 0 : 1
        })
    }

    func setDate(_ date: TimelineDate) {
        currentDate.year = adjust(year: date.year)
        currentDate.month = adjust(month: date.month)
        currentDate.day = adjust(day: date.day)
        scrollCollectionViews()
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)
        gestureManager.displayTouchIndicators = false
        TouchManager.instance.register(gestureManager, for: .timeline)

        setupBackground()
        setupTimeline()
        setupControls()
        setupGestures()
        setupNotifications()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        setupControlGradients()
        setupTimelineDate()
        timelineCollectionView.collectionViewLayout?.invalidateLayout()
    }


    // MARK: Setup

    private func setupBackground() {
        timelineBackgroundView.alphaValue = 0
        timelineBackgroundView.wantsLayer = true
        timelineBackgroundView.layer?.backgroundColor = style.timelineBackgroundColor.cgColor
    }

    private func setupTimeline() {
        timelineHandler = TimelineHandler(timelineViewController: self)
        ConnectionManager.instance.timelineHandler = timelineHandler
        ConnectionManager.instance.timelineViewController = self
        timelineCollectionView.register(TimelineItemView.self, forItemWithIdentifier: TimelineItemView.identifier)
        timelineCollectionView.register(TimelineBorder.self, forItemWithIdentifier: TimelineBorder.identifier)
        timelineCollectionView.register(NSNib(nibNamed: TimelineHeaderView.nibName, bundle: .main), forSupplementaryViewOfKind: TimelineHeaderView.supplementaryKind, withIdentifier: TimelineHeaderView.identifier)
        timelineCollectionView.dataSource = source
        timelineScrollView.horizontalScroller?.alphaValue = 0
        createRecords()
    }

    private func setupTimelineDate() {
        switch timelineCollectionView.collectionViewLayout {
        case is TimelineMonthLayout:
            setDate(TimelineDate(day: Constants.initialDate.day, month: Constants.initialDate.month + appID, year: Constants.initialDate.year))
        case is TimelineYearLayout:
            setDate(TimelineDate(day: Constants.initialDate.day, month: Constants.initialDate.month, year: Constants.initialDate.year + appID))
        case is TimelineDecadeLayout, is TimelineDecadeStackedLayout:
            setDate(TimelineDate(day: Constants.initialDate.day, month: Constants.initialDate.month, year: Constants.initialDate.year + (appID * 10)))
        case is TimelineCenturyLayout:
            setDate(Constants.initialDate)
        default:
            return
        }
    }

    private func setupControls() {
        let roundedFirstYear = decadeFor(year: source.firstYear)
        let roundedLastYear = decadeFor(year: source.lastYear) - 10
        let roundedYears = Array(roundedFirstYear...roundedLastYear)
        decades = roundedYears.filter { $0 % 10 == 0 }
        years = Array(source.firstYear...source.lastYear)
        setupControls(in: monthCollectionView, scrollView: monthScrollView)
        setupControls(in: yearCollectionView, scrollView: yearScrollView)
        setupControls(in: decadeCollectionView, scrollView: decadeScrollView)
        timelineIndicatorView.wantsLayer = true
        timelineIndicatorView.layer?.cornerRadius = Constants.timelineIndicatorBorderRadius
        timelineIndicatorView.layer?.borderWidth = Constants.timelineIndicatorBorderWidth
        timelineIndicatorView.layer?.borderColor = style.selectedColor.cgColor
    }

    private func setupControlGradients() {
        setupHorizontalGradient(in: monthScrollView)
        setupHorizontalGradient(in: yearScrollView)
        setupHorizontalGradient(in: decadeScrollView)
    }

    private func setupGestures() {
        let timelinePanGesture = PanGestureRecognizer()
        gestureManager.add(timelinePanGesture, to: timelineCollectionView)
        timelinePanGesture.gestureUpdated = { [weak self] gesture in
            self?.didPanOnTimeline(gesture)
        }

        let timelineTapGesture = TapGestureRecognizer()
        gestureManager.add(timelineTapGesture, to: timelineCollectionView)
        timelineTapGesture.gestureUpdated = { [weak self] gesture in
            self?.didTapOnTimeline(gesture)
        }

        addGestures(to: monthCollectionView)
        addGestures(to: yearCollectionView)
        addGestures(to: decadeCollectionView)
    }

    private func addGestures(to collectionView: NSCollectionView) {
        let tapGesture = TapGestureRecognizer()
        gestureManager.add(tapGesture, to: collectionView)
        tapGesture.gestureUpdated = { [weak self] gesture in
            self?.didTapOnControl(gesture)
        }

        let panGesture = PanGestureRecognizer()
        gestureManager.add(panGesture, to: collectionView)
        panGesture.gestureUpdated = { [weak self] gesture in
            self?.didPanOnControl(gesture)
        }
    }

    private func setupNotifications() {
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: SettingsNotification.transition.name, object: nil)
        for notification in TimelineNotification.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
    }


    // MARK: Gesture Handling

    private func didPanOnTimeline(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let collectionView = gestureManager.view(for: gesture) as? NSCollectionView else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            updateDate(from: collectionView, with: pan.delta)
            timelineHandler?.send(date: currentDate, for: pan.state)
        case .ended:
            timelineHandler?.endActivity()
        case .possible, .failed:
            timelineHandler?.endUpdates()
        default:
            return
        }
    }

    private func didTapOnTimeline(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended,
            let location = tap.position,
            let indexPath = timelineCollectionView.indexPathForItem(at: location + timelineCollectionView.visibleRect.origin),
            let timelineItem = timelineCollectionView.item(at: indexPath) as? TimelineItemView else {
                return
        }

        let state = source.selectedIndexes.contains(indexPath.item)
        postSelectNotification(for: indexPath.item, state: !state)
        let translatedXPosition = timelineItem.view.frame.origin.x - timelineCollectionView.visibleRect.origin.x
        let transformedXPosition = max(0, translatedXPosition)
        let transformedYPosition = timelineItem.view.frame.transformed(from: timelineScrollView.frame).transformed(from: timelineBackgroundView.frame).origin.y
        postRecordNotification(for: timelineItem.event.type, with: timelineItem.event.id, at: CGPoint(x: transformedXPosition, y: transformedYPosition))
    }

    private func didTapOnControl(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended,
            let collectionView = gestureManager.view(for: gesture) as? NSCollectionView,
            canSelectItem(in: collectionView),
            let location = tap.position,
            let indexPath = collectionView.indexPathForItem(at: location + collectionView.visibleRect.origin),
            let itemView = collectionView.item(at: indexPath) as? TimelineControlItemView,
            let title = itemView.title else {
                return
        }

        switch collectionView {
        case monthCollectionView:
            if let month = Month(abbreviation: title) {
                select(month: month, view: itemView)
            }
        case yearCollectionView:
            if let year = Int(title) {
                select(year: year, view: itemView)
            }
        case decadeCollectionView:
            if let decade = Int(title) {
                select(decade: decade, view: itemView)
            }
        default:
            return
        }
    }

    private func didPanOnControl(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let collectionView = gestureManager.view(for: gesture) as? NSCollectionView else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            updateDate(from: collectionView, with: pan.delta)
            timelineHandler?.send(date: currentDate)
        case .ended:
            timelineHandler?.endActivity()
        case .possible, .failed:
            timelineHandler?.endUpdates()
        default:
            return
        }
    }

    private func updateDate(from collectionView: NSCollectionView, with offset: CGVector) {
        let days = -(offset.dx / Constants.timelineControlItemWidth)

        switch collectionView {
        case monthCollectionView:
            add(days: days)
        case yearCollectionView:
            add(days: days * 12)
        case decadeCollectionView:
            add(days: days * 120)
        case timelineCollectionView:
            addTimelineDays(with: offset)
        default:
            return
        }
    }

    private func addTimelineDays(with offset: CGVector) {
        let days = -(offset.dx / CGFloat(timelineType.sectionWidth))

        switch timelineCollectionView.collectionViewLayout {
        case is TimelineMonthLayout:
            add(days: days)
        case is TimelineYearLayout, is TimelineDecadeLayout, is TimelineCenturyLayout, is TimelineDecadeStackedLayout:
            add(days: days * 12)
        default:
            return
        }
    }

    private func adjust(day: CGFloat) -> CGFloat {
        let months = Int(day)

        if day < 0 {
            currentDate.month = adjust(month: months + currentDate.month - 1)
            return 1 - (abs(day) + CGFloat(months))
        } else if day > 1 {
            currentDate.month = adjust(month: months + currentDate.month)
            return day - CGFloat(months)
        }

        return day
    }

    private func adjust(month: Int) -> Int {
        let years = month / 12
        let remainder = month % 12

        if month < 0 {
            currentDate.year = adjust(year: currentDate.year + years - 1)
            return 12 + remainder
        } else if month > 11 {
            currentDate.year = adjust(year: currentDate.year + years + 1)
            return remainder
        }

        return month
    }

    private func adjust(year: Int) -> Int {
        if year < source.firstYear {
            return source.lastYear + (year - source.firstYear + 1)
        } else if year > source.lastYear {
            return source.firstYear + (year - source.lastYear - 1)
        }

        return year
    }

    private func add(days: CGFloat) {
        var newDay = currentDate.day + days
        let months = Int(newDay)

        if newDay < 0 {
            add(months: months - 1)
            newDay = 1 - (abs(newDay) + CGFloat(months))
            currentDate.day = newDay
        } else if newDay > 1 {
            add(months: months)
            newDay -= CGFloat(months)
            currentDate.day = newDay
        } else {
            currentDate.day = newDay
        }
    }

    private func add(months: Int) {
        if months.isZero { return }
        var newMonth = currentDate.month + months
        let years = newMonth / 12
        let remainder = newMonth % 12

        if newMonth < 0 {
            add(years: years - 1)
            newMonth = 12 + remainder
            currentDate.month = newMonth
        } else if newMonth > 11 {
            add(years: years)
            newMonth = remainder
            currentDate.month = newMonth
        } else {
            currentDate.month = newMonth
        }
    }

    private func add(years: Int) {
        if years.isZero { return }
        let diff = years % self.years.count
        var newYear = currentDate.year + diff

        if newYear < source.firstYear {
            newYear = source.lastYear - (source.firstYear - newYear) + 1
            currentDate.year = newYear
        } else if newYear > source.lastYear {
            newYear = source.firstYear + (newYear - source.lastYear) - 1
            currentDate.year = newYear
        } else {
            currentDate.year = newYear
        }
    }


    // MARK: Notification Handling

    @objc
    private func handleNotification(_ notification: NSNotification) {
        guard let info = notification.userInfo else {
            return
        }

        switch notification.name {
        case TimelineNotification.selection.name:
            if let selection = info[Keys.selection] as? [Int] {
                setTimelineSelection(Set(selection))
            }
        case TimelineNotification.select.name:
            if let index = info[Keys.index] as? Int, let state = info[Keys.state] as? Bool {
                setTimelineItem(index, selected: state)
            }
        default:
            return
        }
    }


    // MARK: NSCollectionViewDelegate & NSCollectionViewDataSource

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case monthCollectionView:
            return Month.allValues.count + Constants.visibleControlItems
        case yearCollectionView:
            return years.count + Constants.visibleControlItems + 1
        case decadeCollectionView:
            return decades.count + Constants.visibleControlItems + 1
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        switch collectionView {
        case monthCollectionView:
            if let controlItemView = collectionView.makeItem(withIdentifier: TimelineControlItemView.identifier, for: indexPath) as? TimelineControlItemView {
                let month = Month.allValues.at(index: indexPath.item % Month.allValues.count)
                controlItemView.title = month?.abbreviation
                if let selectedMonth = selectedMonth {
                    controlItemView.set(highlighted: selectedMonth == month)
                }
                return controlItemView
            }
        case yearCollectionView:
            if indexPath.item == years.count, let border = collectionView.makeItem(withIdentifier: TimelineBorder.identifier, for: indexPath) as? TimelineBorder {
                let x = CGFloat(years.count) * Constants.controlItemWidth
                let frame = CGRect(x: x, y: collectionView.frame.height / 4, width: style.borderWidth, height: collectionView.frame.height / 2)
                border.set(frame: frame)
                return border
            } else if let controlItemView = collectionView.makeItem(withIdentifier: TimelineControlItemView.identifier, for: indexPath) as? TimelineControlItemView {
                let itemIndex = indexPath.item >= years.count ? indexPath.item - 1 : indexPath.item
                let year = years.at(index: itemIndex % years.count)
                controlItemView.title = year?.description
                if let selectedYear = selectedYear {
                    controlItemView.set(highlighted: selectedYear == year)
                }
                return controlItemView
            }
        case decadeCollectionView:
            if indexPath.item == decades.count, let border = collectionView.makeItem(withIdentifier: TimelineBorder.identifier, for: indexPath) as? TimelineBorder {
                let x = CGFloat(decades.count) * Constants.controlItemWidth
                let frame = CGRect(x: x, y: collectionView.frame.height / 4, width: style.borderWidth, height: collectionView.frame.height / 2)
                border.set(frame: frame)
                return border
            } else if let controlItemView = collectionView.makeItem(withIdentifier: TimelineControlItemView.identifier, for: indexPath) as? TimelineControlItemView {
                let itemIndex = indexPath.item >= decades.count ? indexPath.item - 1 : indexPath.item
                let decade = decades.at(index: itemIndex % decades.count)
                controlItemView.title = decade?.description
                if let selectedDecade = selectedDecade {
                    controlItemView.set(highlighted: selectedDecade == decade)
                }
                return controlItemView
            }
        default:
            break
        }

        return NSCollectionViewItem()
    }

    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        switch collectionView {
        case monthCollectionView:
            let height = collectionView.superview!.frame.size.height
            return CGSize(width: Constants.controlItemWidth, height: height)
        case yearCollectionView:
            if indexPath.item == years.count {
                return CGSize(width: style.borderWidth, height: collectionView.frame.height)
            } else {
                let height = collectionView.superview!.frame.size.height
                return CGSize(width: Constants.controlItemWidth, height: height)
            }
        case decadeCollectionView:
            if indexPath.item == decades.count {
                return CGSize(width: style.borderWidth, height: collectionView.frame.height)
            } else {
                let height = collectionView.superview!.frame.size.height
                return CGSize(width: Constants.controlItemWidth, height: height)
            }
        default:
            break
        }

        return NSSize.zero
    }


    // MARK: Control Selection

    private func setupControls(in collectionView: NSCollectionView, scrollView: NSScrollView) {
        collectionView.register(TimelineControlItemView.self, forItemWithIdentifier: TimelineControlItemView.identifier)
        collectionView.register(TimelineBorder.self, forItemWithIdentifier: TimelineBorder.identifier)
        scrollView.horizontalScroller?.alphaValue = 0
    }

    private func setupHorizontalGradient(in view: NSView) {
        view.wantsLayer = true
        let transparent = NSColor.clear.cgColor
        let opaque = style.darkBackgroundOpaque.cgColor
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [transparent, opaque, opaque, transparent]
        gradientLayer.locations = [0.0, NSNumber(value: Constants.fadePercentage), NSNumber(value: 1.0 - Constants.fadePercentage), 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        view.layer?.mask = gradientLayer
    }

    private func canSelectItem(in collectionView: NSCollectionView) -> Bool {
        switch collectionView {
        case monthCollectionView:
            return selectedDecade != nil && selectedYear != nil
        case yearCollectionView:
            return selectedDecade != nil
        default:
            return true
        }
    }

    private func select(month: Month, view: TimelineControlItemView) {
        if month == selectedMonth {
            removeSelection(for: .month)
            transition(to: .year)
            return
        }

        selectedMonth = month
        transition(to: .month)
        selectedViewForType[.month]?.set(highlighted: false)
        selectedViewForType[.month] = view
        view.set(highlighted: true)
        // scroll the timeline
    }

    private func select(year: Int, view: TimelineControlItemView) {
        if year == selectedYear {
            removeSelection(for: .year)
            transition(to: .decade)
            return
        }

        removeSelection(for: .month)
        selectedYear = year
        transition(to: .year)
        selectedViewForType[.year]?.set(highlighted: false)
        selectedViewForType[.year] = view
        view.set(highlighted: true)
        // scroll the timeline
    }

    private func select(decade: Int, view: TimelineControlItemView) {
        if decade == selectedDecade {
            removeSelection(for: .decade)
            transition(to: .century)
            return
        }

        removeSelection(for: .year)
        selectedDecade = decade
        transition(to: .decade)
        selectedViewForType[.decade]?.set(highlighted: false)
        selectedViewForType[.decade] = view
        view.set(highlighted: true)
        // scroll the timeline
    }

    private func removeSelection(for type: TimelineType) {
        // Unhighlight items for type
        let visibleItems = collectionView(for: type)?.visibleItems() ?? []
        for item in visibleItems {
            if let controlItem = item as? TimelineControlItemView {
                controlItem.set(highlighted: false)
            }
        }

        switch type {
        case .month:
            selectedMonth = nil
        case .year:
            removeSelection(for: .month)
            selectedYear = nil
        case .decade:
            removeSelection(for: .year)
            selectedDecade = nil
        case .century:
            removeSelection(for: .decade)
        }
    }

    private func transition(to type: TimelineType) {
        // update the layout and data source for the timeline
//        switch type {
//        case .month:
//            monthCollectionView.reloadData()
//        case .year:
//            monthCollectionView.reloadData()
//            yearCollectionView.reloadData()
//        case .decade:
//            monthCollectionView.reloadData()
//            yearCollectionView.reloadData()
//            decadeCollectionView.reloadData()
//        case .century:
//            monthCollectionView.reloadData()
//            yearCollectionView.reloadData()
//            decadeCollectionView.reloadData()
//        }
    }


    // MARK: Timeline Selection

    private func postSelectNotification(for index: Int, state: Bool) {
        var info: JSON = [Keys.id: appID, Keys.index: index, Keys.state: state]
        if let group = ConnectionManager.instance.groupForApp(id: appID, type: .timeline) {
            info[Keys.group] = group
        }
        DistributedNotificationCenter.default().postNotificationName(TimelineNotification.select.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    private func setTimelineSelection(_ selection: Set<Int>) {
        // Unselect current indexes that are not in the new selection
        source.selectedIndexes.filter({ !selection.contains($0) }).forEach { index in
            setTimelineItem(index, selected: false)
        }
        // Select indexes that are not currently selected
        selection.filter({ !source.selectedIndexes.contains($0) }).forEach { index in
            setTimelineItem(index, selected: true)
        }
    }

    private func setTimelineItem(_ index: Int, selected: Bool) {
        if selected {
            source.selectedIndexes.append(index)
        } else {
            source.selectedIndexes = source.selectedIndexes.filter({ $0 != index })
        }

        // Update item view for index
        let indexPath = IndexPath(item: index, section: 0)
        if let timelineItem = timelineCollectionView.item(at: indexPath) as? TimelineItemView, let attributes = timelineCollectionView.collectionViewLayout?.layoutAttributesForItem(at: indexPath) {
            timelineItem.animate(to: attributes.size, with: CGFloat(attributes.zIndex), containedIn: timelineCollectionView.frame, layout: timelineCollectionView.collectionViewLayout)
        }
    }


    // MARK: Helpers

    private func scrollCollectionViews() {
        let centerInset = Constants.controlItemWidth * 3

        let dayOffset = (currentDate.day - 0.5) * Constants.controlItemWidth
        let monthMaxX = CGFloat(Month.allValues.count) * Constants.controlItemWidth
        let monthX = CGFloat(currentDate.month) * Constants.controlItemWidth
        var monthRect = monthCollectionView.visibleRect
        monthRect.origin.x = monthX - centerInset + dayOffset
        if monthRect.origin.x < 0 {
            monthRect.origin.x = monthMaxX + monthRect.origin.x
        }
        monthCollectionView.scrollToVisible(monthRect)

        let monthOffset = (CGFloat(currentDate.month) / 12) * Constants.controlItemWidth
        let yearMaxX = CGFloat(years.count) * Constants.controlItemWidth
        let yearIndex = years.index(of: currentDate.year) != nil ? years.index(of: currentDate.year) : currentDate.year < source.firstYear ? -1 : years.count - 1
        let yearX = CGFloat(yearIndex!) * Constants.controlItemWidth
        var yearRect = yearCollectionView.visibleRect
        yearRect.origin.x = yearX - centerInset + monthOffset
        if yearRect.origin.x < 0 {
            yearRect.origin.x = yearMaxX + yearRect.origin.x
        }
        yearCollectionView.scrollToVisible(yearRect)

        let yearOffset = (CGFloat(currentDate.year.array.last!) / 10) * Constants.controlItemWidth
        let decade = decadeFor(year: currentDate.year)
        let decadeMaxX = CGFloat(decades.count) * Constants.controlItemWidth
        let decadeIndexBoundary = decade < decades.first! ? 0 : decades.count
        let decadeIndex = decades.index(of: decade) != nil ? decades.index(of: decade) : decadeIndexBoundary
        let decadeX = CGFloat(decadeIndex!) * Constants.controlItemWidth
        var decadeRect = decadeCollectionView.visibleRect
        decadeRect.origin.x = decadeX - centerInset + yearOffset
        if decadeRect.origin.x < 0 {
            decadeRect.origin.x = decadeMaxX + decadeRect.origin.x
        }
        decadeCollectionView.scrollToVisible(decadeRect)

        scrollTimeline()
    }

    private func scrollTimeline() {
        var timelineMaxX = CGFloat(years.count) * CGFloat(timelineType.sectionWidth)
        let timelineYearIndex = years.index(of: currentDate.year) != nil ? years.index(of: currentDate.year) : currentDate.year < source.firstYear ? -1 : years.count - 1
        var timelineRect = timelineCollectionView.visibleRect
        let previousRect = timelineRect

        switch timelineCollectionView.collectionViewLayout {
        case is TimelineMonthLayout:
            timelineMaxX = CGFloat(years.count) * CGFloat(timelineType.sectionWidth) * 12
            let timelineMonthOffset = ((CGFloat(currentDate.month) + currentDate.day - 0.5)) * CGFloat(timelineType.sectionWidth)
            let timelineYearX = CGFloat(timelineYearIndex!) * CGFloat(timelineType.sectionWidth) * 12
            timelineRect.origin.x = timelineYearX - timelineRect.width / 2 + timelineMonthOffset
            if timelineRect.origin.x < 0 {
                timelineRect.origin.x = timelineMaxX + timelineRect.origin.x
            }
            timelineCollectionView.scrollToVisible(timelineRect)
        case is TimelineYearLayout, is TimelineCenturyLayout, is TimelineDecadeLayout, is TimelineDecadeStackedLayout:
            let timelineMonthOffset = ((CGFloat(currentDate.month) + currentDate.day - 0.5) / 12) * CGFloat(timelineType.sectionWidth)
            let timelineYearX = CGFloat(timelineYearIndex!) * CGFloat(timelineType.sectionWidth)
            timelineRect.origin.x = timelineYearX - timelineRect.width / 2 + timelineMonthOffset
            if timelineRect.origin.x < 0 {
                timelineRect.origin.x = timelineMaxX + timelineRect.origin.x
            }
            timelineCollectionView.scrollToVisible(timelineRect)
        default:
            return
        }

        if abs(previousRect.origin.x - timelineRect.origin.x) > timelineMaxX / 2 {
            timelineCollectionView.reloadItems(at: timelineCollectionView.indexPathsForVisibleItems())
        }
    }

    private func decadeFor(year: Int) -> Int {
        return year / 10 * 10
    }

    private func collectionView(for type: TimelineType) -> NSCollectionView? {
        switch type {
        case .month:
            return monthCollectionView
        case .year:
            return yearCollectionView
        case .decade:
            return decadeCollectionView
        case .century:
            return nil
        }
    }

    private func postRecordNotification(for type: RecordType, with id: Int, at position: CGPoint) {
        guard let window = view.window else {
            return
        }

        let location = window.frame.origin + position
        let info: JSON = [Keys.appID: appID, Keys.id: id, Keys.position: location.toJSON()]
        DistributedNotificationCenter.default().postNotificationName(RecordNotification.with(type).name, object: nil, userInfo: info, deliverImmediately: true)
    }

    private func createRecords() {
        // Schools
        let schoolChain = firstly {
            try CachingNetwork.getSchools()
        }.catch { error in
            print(error)
        }

        // Events
        let eventChain = firstly {
            try CachingNetwork.getEvents()
        }.catch { error in
            print(error)
        }

        when(fulfilled: schoolChain, eventChain).then { [weak self] results in
            self?.parseNetworkResults(results)
        }
    }

    private func parseNetworkResults(_ results: (schools: [School], events: [Event])) {
        var records = [Record]()
        records.append(contentsOf: results.schools)
        records.append(contentsOf: results.events)
        source.records = records
        timelineCollectionView.reloadData()
    }
}
