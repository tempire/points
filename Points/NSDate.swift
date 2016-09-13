//
//  NSDate.swift
//  Points
//
//  Created by Glen Hinkle on 7/3/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

open class ISO8601: NSDate { }
open class EpochTimeMilliseconds: NSDate { }

enum DateFormat {
    case wsdcEventMonth
    case iso8601
    case kobol
    case custom(String, TimeZone)
}

enum TimeZone: String {
    case GMT
    case Current
    
    var nsTimeZone: Foundation.TimeZone? {
        return Foundation.TimeZone(identifier: "\(self)")
    }
}

public func ==(lhs: Date, rhs: Date) -> Bool {
    return lhs.compare(rhs) == ComparisonResult.orderedSame
}


public func <(lhs: Date, rhs: Date) -> Bool {
    return lhs.compare(rhs) == ComparisonResult.orderedAscending
}

//extension Date: Comparable { }

extension Date {
    
    // MARK: Intervals In Seconds
    static func minuteInSeconds() -> Double { return 60 }
    static func hourInSeconds() -> Double { return 3600 }
    static func dayInSeconds() -> Double { return 86400 }
    static func weekInSeconds() -> Double { return 604800 }
    static func yearInSeconds() -> Double { return 31556926 }
    
    // MARK: Components
    fileprivate static func componentFlags() -> NSCalendar.Unit {
        return [.year, .month, .day, .weekOfYear, .hour, .minute, .second, .weekday, .weekdayOrdinal, .weekOfYear]
    }
    
    fileprivate static func components(fromDate: Date) -> DateComponents! {
        return (Calendar.current as NSCalendar).components(Date.componentFlags(), from: fromDate)
    }
    
    fileprivate func components() -> DateComponents  {
        return Date.components(fromDate: self)!
    }
    
    // MARK: Date From String
    
    init?(_ string: String?, format:DateFormat) {
        guard let string: NSString = string as NSString? else {
            return nil
        }
        
        guard string.replacingOccurrences(of: " ", with: "").characters.count != 0 else {
            return nil
        }
        
        switch format {
            
        case .wsdcEventMonth:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            if let date = formatter.date(from: string as String) {
                self.init(timeInterval: 0, since: date)
            }
            else {
                return nil
            }
            
            
        case .iso8601:
            var s = string
            if string.hasSuffix(" 00:00") {
                s = s.substring(to: s.length-6) + "GMT"
            } else if string.hasSuffix("Z") {
                s = s.substring(to: s.length-1) + "GMT"
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
            if let date = formatter.date(from: string as String) {
                self.init(timeInterval:0, since:date)
            } else {
                return nil
            }
            
        case .kobol:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            formatter.timeZone = TimeZone.GMT.nsTimeZone
            if let date = formatter.date(from: string as String) {
                self.init(timeInterval:0, since:date)
            } else {
                return nil
            }
            
        case .custom(let dateFormat, let timeZone):
            
            let formatter = DateFormatter()
            formatter.dateFormat = dateFormat
            formatter.timeZone = timeZone.nsTimeZone
            if let date = formatter.date(from: string as String) {
                self.init(timeInterval:0, since:date)
            } else {
                return nil
            }
        }
    }
    
    
    // MARK: Comparing Dates
    
    func isEqualToDateIgnoringTime(_ date: Date) -> Bool
    {
        let comp1 = Date.components(fromDate: self)
        let comp2 = Date.components(fromDate: date)
        return ((comp1!.year == comp2!.year) && (comp1!.month == comp2!.month) && (comp1!.day == comp2!.day))
    }
    
    func isToday() -> Bool
    {
        return self.isEqualToDateIgnoringTime(Date())
    }
    
    func isTomorrow() -> Bool
    {
        return self.isEqualToDateIgnoringTime(Date().dateByAddingDays(1))
    }
    
    func isYesterday() -> Bool
    {
        return self.isEqualToDateIgnoringTime(Date().dateBySubtractingDays(1))
    }
    
    func isSameWeekAsDate(_ date: Date) -> Bool
    {
        let comp1 = Date.components(fromDate: self)
        let comp2 = Date.components(fromDate: date)
        // Must be same week. 12/31 and 1/1 will both be week "1" if they are in the same week
        if comp1?.weekOfYear != comp2?.weekOfYear {
            return false
        }
        // Must have a time interval under 1 week
        return abs(self.timeIntervalSince(date)) < Date.weekInSeconds()
    }
    
    func isThisWeek() -> Bool
    {
        return self.isSameWeekAsDate(Date())
    }
    
    func isNextWeek() -> Bool
    {
        let interval: TimeInterval = Date().timeIntervalSinceReferenceDate + Date.weekInSeconds()
        let date = Date(timeIntervalSinceReferenceDate: interval)
        return self.isSameYearAsDate(date)
    }
    
    func isLastWeek() -> Bool
    {
        let interval: TimeInterval = Date().timeIntervalSinceReferenceDate - Date.weekInSeconds()
        let date = Date(timeIntervalSinceReferenceDate: interval)
        return self.isSameYearAsDate(date)
    }
    
    func isSameYearAsDate(_ date: Date) -> Bool
    {
        let comp1 = Date.components(fromDate: self)
        let comp2 = Date.components(fromDate: date)
        return (comp1!.year == comp2!.year)
    }
    
    func isThisYear() -> Bool
    {
        return self.isSameYearAsDate(Date())
    }
    
    func isNextYear() -> Bool
    {
        let comp1 = Date.components(fromDate: self)
        let comp2 = Date.components(fromDate: Date())
        return (comp1!.year! == comp2!.year! + 1)
    }
    
    func isLastYear() -> Bool
    {
        let comp1 = Date.components(fromDate: self)
        let comp2 = Date.components(fromDate: Date())
        return (comp1!.year! == comp2!.year! - 1)
    }
    
    func isEarlierThanDate(_ date: Date) -> Bool
    {
        return !(self > date)
    }
    
    func isLaterThanDate(_ date: Date) -> Bool
    {
        return self > date
    }
    
    
    // MARK: Adjusting Dates
    
    func dateByAddingDays(_ days: Int) -> Date
    {
        let interval: TimeInterval = self.timeIntervalSinceReferenceDate + Date.dayInSeconds() * Double(days)
        return Date(timeIntervalSinceReferenceDate: interval)
    }
    
    func dateBySubtractingDays(_ days: Int) -> Date
    {
        let interval: TimeInterval = self.timeIntervalSinceReferenceDate - Date.dayInSeconds() * Double(days)
        return Date(timeIntervalSinceReferenceDate: interval)
    }
    
    func dateByAddingHours(_ hours: Int) -> Date
    {
        let interval: TimeInterval = self.timeIntervalSinceReferenceDate + Date.hourInSeconds() * Double(hours)
        return Date(timeIntervalSinceReferenceDate: interval)
    }
    
    func dateBySubtractingHours(_ hours: Int) -> Date
    {
        let interval: TimeInterval = self.timeIntervalSinceReferenceDate - Date.hourInSeconds() * Double(hours)
        return Date(timeIntervalSinceReferenceDate: interval)
    }
    
    func dateByAddingMinutes(_ minutes: Int) -> Date
    {
        let interval: TimeInterval = self.timeIntervalSinceReferenceDate + Date.minuteInSeconds() * Double(minutes)
        return Date(timeIntervalSinceReferenceDate: interval)
    }
    
    func dateBySubtractingMinutes(_ minutes: Int) -> Date
    {
        let interval: TimeInterval = self.timeIntervalSinceReferenceDate - Date.minuteInSeconds() * Double(minutes)
        return Date(timeIntervalSinceReferenceDate: interval)
    }
    
    func dateAtStartOfDay() -> Date
    {
        var components = self.components()
        components.hour = 0
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)!
    }
    
    func dateAtEndOfDay() -> Date
    {
        var components = self.components()
        components.hour = 23
        components.minute = 59
        components.second = 59
        return Calendar.current.date(from: components)!
    }
    
    func dateAtStartOfWeek() -> Date
    {
        let flags :NSCalendar.Unit = [.year, .month, .weekOfYear, .weekday]
        var components = (Calendar.current as NSCalendar).components(flags, from: self)
        components.weekday = 1 // Sunday
        components.hour = 0
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)!
    }
    
    func dateAtEndOfWeek() -> Date
    {
        let flags :NSCalendar.Unit = [.year, .month, .weekOfYear, .weekday]
        var components = (Calendar.current as NSCalendar).components(flags, from: self)
        components.weekday = 7 // Sunday
        components.hour = 0
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)!
    }
    
    
    // MARK: Retrieving Intervals
    
    func minutesAfterDate(_ date: Date) -> Int
    {
        let interval = self.timeIntervalSince(date)
        return Int(interval / Date.minuteInSeconds())
    }
    
    func minutesBeforeDate(_ date: Date) -> Int
    {
        let interval = date.timeIntervalSince(self)
        return Int(interval / Date.minuteInSeconds())
    }
    
    func hoursAfterDate(_ date: Date) -> Int
    {
        let interval = self.timeIntervalSince(date)
        return Int(interval / Date.hourInSeconds())
    }
    
    func hoursBeforeDate(_ date: Date) -> Int
    {
        let interval = date.timeIntervalSince(self)
        return Int(interval / Date.hourInSeconds())
    }
    
    func daysAfterDate(_ date: Date) -> Int
    {
        let interval = self.timeIntervalSince(date)
        return Int(interval / Date.dayInSeconds())
    }
    
    func daysBeforeDate(_ date: Date) -> Int
    {
        let interval = date.timeIntervalSince(self)
        return Int(interval / Date.dayInSeconds())
    }
    
    
    // MARK: Decomposing Dates
    
    func year () -> Int { return self.components().year!  }
    func month () -> Int { return self.components().month! }
    func week () -> Int { return self.components().weekOfYear! }
    func day () -> Int { return self.components().day! }
    func hour () -> Int { return self.components().hour! }
    func minute () -> Int { return self.components().minute! }
    func seconds () -> Int { return self.components().second! }
    func weekday () -> Int { return self.components().weekday! }
    func nthWeekday () -> Int { return self.components().weekdayOrdinal! } //// e.g. 2nd Tuesday of the month is 2
    func monthDays () -> Int { return (Calendar.current as NSCalendar).range(of: .day, in: .month, for: self).length }
    
    func firstDayOfWeek () -> Int {
        let distanceToStartOfWeek = Date.dayInSeconds() * Double(self.components().weekday! - 1)
        let interval: TimeInterval = self.timeIntervalSinceReferenceDate - distanceToStartOfWeek
        return Date(timeIntervalSinceReferenceDate: interval).day()
    }
    func lastDayOfWeek () -> Int {
        let distanceToStartOfWeek = Date.dayInSeconds() * Double(self.components().weekday! - 1)
        let distanceToEndOfWeek = Date.dayInSeconds() * Double(7)
        let interval: TimeInterval = self.timeIntervalSinceReferenceDate - distanceToStartOfWeek + distanceToEndOfWeek
        return Date(timeIntervalSinceReferenceDate: interval).day()
    }
    func isWeekday() -> Bool {
        return !self.isWeekend()
    }
    func isWeekend() -> Bool {
        let range = (Calendar.current as NSCalendar).maximumRange(of: .weekday)
        return (self.weekday() == range.location || self.weekday() == range.length)
    }
    
    
    // MARK: To String
    
    var toString: String {
        return self.toString(dateStyle: .short, timeStyle: .medium, doesRelativeDateFormatting: true)
    }
    
    func toString(format: DateFormat) -> String
    {
        var dateFormat: String
        var timeZone: Foundation.TimeZone?
        switch format {
            
        case .wsdcEventMonth:
            dateFormat = "MMMM YYYY"
            
        case .iso8601:
            dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            
        case .kobol:
            dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            
        case .custom(let string, let timezone):
            dateFormat = string
            timeZone = timezone.nsTimeZone
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.timeZone = timeZone
        return formatter.string(from: self)
    }
    
    func toString(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style, doesRelativeDateFormatting: Bool = false) -> String
    {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.doesRelativeDateFormatting = doesRelativeDateFormatting
        return formatter.string(from: self)
    }
    
    func relativeTimeToString() -> String
    {
        let time = self.timeIntervalSince1970
        let now = Date().timeIntervalSince1970
        
        let seconds = now - time
        let minutes = round(seconds/60)
        let hours = round(minutes/60)
        let days = round(hours/24)
        
        if seconds < 10 {
            return NSLocalizedString("just now", comment: "relative time")
        } else if seconds < 60 {
            return NSLocalizedString("\(Int(seconds)) seconds ago", comment: "relative time")
        }
        
        if minutes < 60 {
            if minutes == 1 {
                return NSLocalizedString("1 minute ago", comment: "relative time")
            } else {
                return NSLocalizedString("\(Int(minutes)) minutes ago", comment: "relative time")
            }
        }
        
        if hours < 24 {
            if hours == 1 {
                return NSLocalizedString("1 hour ago", comment: "relative time")
            } else {
                return NSLocalizedString("\(Int(hours)) hours ago", comment: "relative time")
            }
        }
        
        if days < 7 {
            if days == 1 {
                return NSLocalizedString("1 day ago", comment: "relative time")
            } else {
                return NSLocalizedString("\(Int(days)) days ago", comment: "relative time")
            }
        }
        
        return toString
    }
    
    
    func weekdayToString() -> String {
        let formatter = DateFormatter()
        return formatter.weekdaySymbols[self.weekday()-1]
    }
    
    func shortWeekdayToString() -> String {
        let formatter = DateFormatter()
        return formatter.shortWeekdaySymbols[self.weekday()-1]
    }
    
    func veryShortWeekdayToString() -> String {
        let formatter = DateFormatter()
        return formatter.veryShortWeekdaySymbols[self.weekday()-1]
    }
    
    func monthToString() -> String {
        let formatter = DateFormatter()
        return formatter.monthSymbols[self.month()-1]
    }
    
    func shortMonthToString() -> String {
        let formatter = DateFormatter()
        return formatter.shortMonthSymbols[self.month()-1]
    }
    
    func veryShortMonthToString() -> String {
        let formatter = DateFormatter()
        return formatter.veryShortMonthSymbols[self.month()-1]
    }
}
