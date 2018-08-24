//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit
import MONode
import PromiseKit
import AppKit


final class TimelineDataSource: NSObject, NSCollectionViewDataSource {

    var selectedIndexes = Set<Int>()
    var highlightedIndexes = Set<Int>()
    private(set) var events = [TimelineEvent]()
    private(set) var eventsForYear = [Int: [TimelineEvent]]()
    private(set) var eventsForMonth = [Int: [Month: [TimelineEvent]]]()
    private(set) var firstYear: Int!
    private(set) var lastYear: Int!
    private(set) var years = [Int]()
    private let type = TimelineType.decade

    private struct Constants {
        static let screenWidth = 1920
        static let defaultFirstYear = 1850
        static let defaultLastYear = 2030
    }


    // MARK: API

    func setup(with records: [Record]) {
        let sortedRecords = records.sorted(by: { $0.type.timelineSortOrder < $1.type.timelineSortOrder })

        events = sortedRecords.compactMap { record in
            if let dates = record.dates {
                return TimelineEvent(id: record.id, type: record.type, title: record.title, dates: dates)
            } else {
                return nil
            }
        }

        let minYear = events.min(by: { $0.dates.startDate.year < $1.dates.startDate.year })?.dates.startDate.year ?? Constants.defaultFirstYear
        let maxYear = events.max(by: { $0.dates.startDate.year < $1.dates.startDate.year })?.dates.startDate.year ?? Constants.defaultLastYear
        firstYear = (minYear / 10) * 10
        lastYear = (maxYear / 10) * 10 + 10
        years = Array(firstYear...lastYear)

        for event in events {
            if event.dates.startDate.year < firstYear + type.infiniteBuffer {
                let infiniteBufferEvent = TimelineEvent(id: event.id, type: event.type, title: event.title, dates: event.dates)
                infiniteBufferEvent.dates.startDate.year += years.count
                infiniteBufferEvent.dates.endDate.year += years.count
                events.append(infiniteBufferEvent)
            }
        }

        // Add to year dictionary
        for event in events {
            if eventsForYear[event.dates.startDate.year] != nil {
                eventsForYear[event.dates.startDate.year]!.append(event)
            } else {
                eventsForYear[event.dates.startDate.year] = [event]
            }
        }
    }


    // MARK: NSCollectionViewDataSource

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return events.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let timelineFlag = collectionView.makeItem(withIdentifier: TimelineFlagView.identifier, for: indexPath) as? TimelineFlagView else {
            return NSCollectionViewItem()
        }

        let event = events[indexPath.item]
        timelineFlag.event = event
        timelineFlag.dateTextField.attributedStringValue = NSAttributedString(string: dateTitle(for: timelineFlag.event.dates), attributes: style.timelineDateAttributes)
        timelineFlag.set(highlighted: selectedIndexes.contains(indexPath.item), animated: false)
        return timelineFlag
    }

    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        switch kind {
        case TimelineHeaderView.supplementaryKind:
            if let headerView = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: TimelineHeaderView.identifier, for: indexPath) as? TimelineHeaderView {
                let month = Month.allValues[indexPath.item % Month.allValues.count]
                let year = firstYear + (indexPath.item % years.count)
                let title = type == .month ? month.abbreviation : year.description
                headerView.textLabel.stringValue = title
                return headerView
            }
        case TimelineBorderView.supplementaryKind:
            if let borderView = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: TimelineBorderView.identifier, for: indexPath) as? TimelineBorderView {
                return borderView
            }
        case TimelineTailView.supplementaryKind:
            if let tailView = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: TimelineTailView.identifier, for: indexPath) as? TimelineTailView, let layout = collectionView.collectionViewLayout as? TimelineDecadeFlagLayout {
                let year = indexPath.item
                let layers = layout.layersForYear[year] ?? []
                tailView.set(layers)
                return tailView
            }
        default:
            return NSView()
        }

        return NSView()
    }


    // MARK: Helpers

    private func dateTitle(for dates: TimelineRange) -> String {
        if dates.startDate.year > lastYear {
            return "\(dateTitle(for: dates.startDate)) - \(dateTitle(for: dates.endDate))"
        } else {
            return dates.description
        }
    }

    private func dateTitle(for date: TimelineDate) -> String {
        let year = yearInRange(for: date.year)

        if date.defaultMonthUsed {
            return "\(year)"
        } else if date.defaultDayUsed {
            let m = Month(rawValue: date.month) ?? .january
            return "\(m.abbreviatedTitle), \(year)"
        }

        let m = Month(rawValue: date.month) ?? .january
        let d = max(Int(date.day * 31) + 1, 1)
        return "\(m.abbreviatedTitle) \(d), \(year)"
    }

    private func yearInRange(for year: Int) -> Int {
        if year > lastYear {
            return (year - firstYear) % years.count + firstYear
        } else {
            return year
        }
    }
}
