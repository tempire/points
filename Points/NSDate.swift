//
//  NSDate.swift
//  Points
//
//  Created by Glen Hinkle on 7/3/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

public class ISO8601: NSDate { }
public class EpochTimeMilliseconds: NSDate { }

enum DateFormat {
    case WSDCEventMonth
    case ISO8601
    case Kobol
    case Custom(String, TimeZone)
}

enum TimeZone: String {
    case GMT
    case Current
    
    var nsTimeZone: NSTimeZone? {
        return NSTimeZone(name: "\(self)")
    }
}

public func ==(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.compare(rhs) == NSComparisonResult.OrderedSame
}


public func <(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.compare(rhs) == NSComparisonResult.OrderedAscending
}

extension NSDate: Comparable { }

extension NSDate {
    
    // MARK: Intervals In Seconds
    class func minuteInSeconds() -> Double { return 60 }
    class func hourInSeconds() -> Double { return 3600 }
    class func dayInSeconds() -> Double { return 86400 }
    class func weekInSeconds() -> Double { return 604800 }
    class func yearInSeconds() -> Double { return 31556926 }
    
    // MARK: Components
    private class func componentFlags() -> NSCalendarUnit {
        return [.Year, .Month, .Day, .WeekOfYear, .Hour, .Minute, .Second, .Weekday, .WeekdayOrdinal, .WeekOfYear]
    }
    
    private class func components(fromDate fromDate: NSDate) -> NSDateComponents! {
        return NSCalendar.currentCalendar().components(NSDate.componentFlags(), fromDate: fromDate)
    }
    
    private func components() -> NSDateComponents  {
        return NSDate.components(fromDate: self)!
    }
    
    // MARK: Date From String
    
    convenience init?(_ string: String?, format:DateFormat)
    {
        guard let string: NSString = string else {
            return nil
        }
        
        guard string.stringByReplacingOccurrencesOfString(" ", withString: "").characters.count != 0 else {
            return nil
        }
        
        switch format {
            
        case .WSDCEventMonth:
            let formatter = NSDateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            if let date = formatter.dateFromString(string as String) {
                self.init(timeInterval: 0, sinceDate: date)
            }
            else {
                return nil
            }
            
            
        case .ISO8601:
            var s = string
            if string.hasSuffix(" 00:00") {
                s = s.substringToIndex(s.length-6) + "GMT"
            } else if string.hasSuffix("Z") {
                s = s.substringToIndex(s.length-1) + "GMT"
            }
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
            if let date = formatter.dateFromString(string as String) {
                self.init(timeInterval:0, sinceDate:date)
            } else {
                return nil
            }
            
        case .Kobol:
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            formatter.timeZone = TimeZone.GMT.nsTimeZone
            if let date = formatter.dateFromString(string as String) {
                self.init(timeInterval:0, sinceDate:date)
            } else {
                return nil
            }
            
        case .Custom(let dateFormat, let timeZone):
            
            let formatter = NSDateFormatter()
            formatter.dateFormat = dateFormat
            formatter.timeZone = timeZone.nsTimeZone
            if let date = formatter.dateFromString(string as String) {
                self.init(timeInterval:0, sinceDate:date)
            } else {
                return nil
            }
        }
    }
    
    
    // MARK: Comparing Dates
    
    func isEqualToDateIgnoringTime(date: NSDate) -> Bool
    {
        let comp1 = NSDate.components(fromDate: self)
        let comp2 = NSDate.components(fromDate: date)
        return ((comp1.year == comp2.year) && (comp1.month == comp2.month) && (comp1.day == comp2.day))
    }
    
    func isToday() -> Bool
    {
        return self.isEqualToDateIgnoringTime(NSDate())
    }
    
    func isTomorrow() -> Bool
    {
        return self.isEqualToDateIgnoringTime(NSDate().dateByAddingDays(1))
    }
    
    func isYesterday() -> Bool
    {
        return self.isEqualToDateIgnoringTime(NSDate().dateBySubtractingDays(1))
    }
    
    func isSameWeekAsDate(date: NSDate) -> Bool
    {
        let comp1 = NSDate.components(fromDate: self)
        let comp2 = NSDate.components(fromDate: date)
        // Must be same week. 12/31 and 1/1 will both be week "1" if they are in the same week
        if comp1.weekOfYear != comp2.weekOfYear {
            return false
        }
        // Must have a time interval under 1 week
        return abs(self.timeIntervalSinceDate(date)) < NSDate.weekInSeconds()
    }
    
    func isThisWeek() -> Bool
    {
        return self.isSameWeekAsDate(NSDate())
    }
    
    func isNextWeek() -> Bool
    {
        let interval: NSTimeInterval = NSDate().timeIntervalSinceReferenceDate + NSDate.weekInSeconds()
        let date = NSDate(timeIntervalSinceReferenceDate: interval)
        return self.isSameYearAsDate(date)
    }
    
    func isLastWeek() -> Bool
    {
        let interval: NSTimeInterval = NSDate().timeIntervalSinceReferenceDate - NSDate.weekInSeconds()
        let date = NSDate(timeIntervalSinceReferenceDate: interval)
        return self.isSameYearAsDate(date)
    }
    
    func isSameYearAsDate(date: NSDate) -> Bool
    {
        let comp1 = NSDate.components(fromDate: self)
        let comp2 = NSDate.components(fromDate: date)
        return (comp1.year == comp2.year)
    }
    
    func isThisYear() -> Bool
    {
        return self.isSameYearAsDate(NSDate())
    }
    
    func isNextYear() -> Bool
    {
        let comp1 = NSDate.components(fromDate: self)
        let comp2 = NSDate.components(fromDate: NSDate())
        return (comp1.year == comp2.year + 1)
    }
    
    func isLastYear() -> Bool
    {
        let comp1 = NSDate.components(fromDate: self)
        let comp2 = NSDate.components(fromDate: NSDate())
        return (comp1.year == comp2.year - 1)
    }
    
    func isEarlierThanDate(date: NSDate) -> Bool
    {
        return self.earlierDate(date) == self
    }
    
    func isLaterThanDate(date: NSDate) -> Bool
    {
        return self.laterDate(date) == self
    }
    
    
    // MARK: Adjusting Dates
    
    func dateByAddingDays(days: Int) -> NSDate
    {
        let interval: NSTimeInterval = self.timeIntervalSinceReferenceDate + NSDate.dayInSeconds() * Double(days)
        return NSDate(timeIntervalSinceReferenceDate: interval)
    }
    
    func dateBySubtractingDays(days: Int) -> NSDate
    {
        let interval: NSTimeInterval = self.timeIntervalSinceReferenceDate - NSDate.dayInSeconds() * Double(days)
        return NSDate(timeIntervalSinceReferenceDate: interval)
    }
    
    func dateByAddingHours(hours: Int) -> NSDate
    {
        let interval: NSTimeInterval = self.timeIntervalSinceReferenceDate + NSDate.hourInSeconds() * Double(hours)
        return NSDate(timeIntervalSinceReferenceDate: interval)
    }
    
    func dateBySubtractingHours(hours: Int) -> NSDate
    {
        let interval: NSTimeInterval = self.timeIntervalSinceReferenceDate - NSDate.hourInSeconds() * Double(hours)
        return NSDate(timeIntervalSinceReferenceDate: interval)
    }
    
    func dateByAddingMinutes(minutes: Int) -> NSDate
    {
        let interval: NSTimeInterval = self.timeIntervalSinceReferenceDate + NSDate.minuteInSeconds() * Double(minutes)
        return NSDate(timeIntervalSinceReferenceDate: interval)
    }
    
    func dateBySubtractingMinutes(minutes: Int) -> NSDate
    {
        let interval: NSTimeInterval = self.timeIntervalSinceReferenceDate - NSDate.minuteInSeconds() * Double(minutes)
        return NSDate(timeIntervalSinceReferenceDate: interval)
    }
    
    func dateAtStartOfDay() -> NSDate
    {
        let components = self.components()
        components.hour = 0
        components.minute = 0
        components.second = 0
        return NSCalendar.currentCalendar().dateFromComponents(components)!
    }
    
    func dateAtEndOfDay() -> NSDate
    {
        let components = self.components()
        components.hour = 23
        components.minute = 59
        components.second = 59
        return NSCalendar.currentCalendar().dateFromComponents(components)!
    }
    
    func dateAtStartOfWeek() -> NSDate
    {
        let flags :NSCalendarUnit = [.Year, .Month, .WeekOfYear, .Weekday]
        let components = NSCalendar.currentCalendar().components(flags, fromDate: self)
        components.weekday = 1 // Sunday
        components.hour = 0
        components.minute = 0
        components.second = 0
        return NSCalendar.currentCalendar().dateFromComponents(components)!
    }
    
    func dateAtEndOfWeek() -> NSDate
    {
        let flags :NSCalendarUnit = [.Year, .Month, .WeekOfYear, .Weekday]
        let components = NSCalendar.currentCalendar().components(flags, fromDate: self)
        components.weekday = 7 // Sunday
        components.hour = 0
        components.minute = 0
        components.second = 0
        return NSCalendar.currentCalendar().dateFromComponents(components)!
    }
    
    
    // MARK: Retrieving Intervals
    
    func minutesAfterDate(date: NSDate) -> Int
    {
        let interval = self.timeIntervalSinceDate(date)
        return Int(interval / NSDate.minuteInSeconds())
    }
    
    func minutesBeforeDate(date: NSDate) -> Int
    {
        let interval = date.timeIntervalSinceDate(self)
        return Int(interval / NSDate.minuteInSeconds())
    }
    
    func hoursAfterDate(date: NSDate) -> Int
    {
        let interval = self.timeIntervalSinceDate(date)
        return Int(interval / NSDate.hourInSeconds())
    }
    
    func hoursBeforeDate(date: NSDate) -> Int
    {
        let interval = date.timeIntervalSinceDate(self)
        return Int(interval / NSDate.hourInSeconds())
    }
    
    func daysAfterDate(date: NSDate) -> Int
    {
        let interval = self.timeIntervalSinceDate(date)
        return Int(interval / NSDate.dayInSeconds())
    }
    
    func daysBeforeDate(date: NSDate) -> Int
    {
        let interval = date.timeIntervalSinceDate(self)
        return Int(interval / NSDate.dayInSeconds())
    }
    
    
    // MARK: Decomposing Dates
    
    func year () -> Int { return self.components().year  }
    func month () -> Int { return self.components().month }
    func week () -> Int { return self.components().weekOfYear }
    func day () -> Int { return self.components().day }
    func hour () -> Int { return self.components().hour }
    func minute () -> Int { return self.components().minute }
    func seconds () -> Int { return self.components().second }
    func weekday () -> Int { return self.components().weekday }
    func nthWeekday () -> Int { return self.components().weekdayOrdinal } //// e.g. 2nd Tuesday of the month is 2
    func monthDays () -> Int { return NSCalendar.currentCalendar().rangeOfUnit(.Day, inUnit: .Month, forDate: self).length }
    
    func firstDayOfWeek () -> Int {
        let distanceToStartOfWeek = NSDate.dayInSeconds() * Double(self.components().weekday - 1)
        let interval: NSTimeInterval = self.timeIntervalSinceReferenceDate - distanceToStartOfWeek
        return NSDate(timeIntervalSinceReferenceDate: interval).day()
    }
    func lastDayOfWeek () -> Int {
        let distanceToStartOfWeek = NSDate.dayInSeconds() * Double(self.components().weekday - 1)
        let distanceToEndOfWeek = NSDate.dayInSeconds() * Double(7)
        let interval: NSTimeInterval = self.timeIntervalSinceReferenceDate - distanceToStartOfWeek + distanceToEndOfWeek
        return NSDate(timeIntervalSinceReferenceDate: interval).day()
    }
    func isWeekday() -> Bool {
        return !self.isWeekend()
    }
    func isWeekend() -> Bool {
        let range = NSCalendar.currentCalendar().maximumRangeOfUnit(.Weekday)
        return (self.weekday() == range.location || self.weekday() == range.length)
    }
    
    
    // MARK: To String
    
    var toString: String {
        return self.toString(dateStyle: .ShortStyle, timeStyle: .MediumStyle, doesRelativeDateFormatting: true)
    }
    
    func toString(format format: DateFormat) -> String
    {
        var dateFormat: String
        var timeZone: NSTimeZone?
        switch format {
            
        case .WSDCEventMonth:
            dateFormat = "MMMM YYYY"
            
        case .ISO8601:
            dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            
        case .Kobol:
            dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            
        case .Custom(let string, let timezone):
            dateFormat = string
            timeZone = timezone.nsTimeZone
        }
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = dateFormat
        formatter.timeZone = timeZone
        return formatter.stringFromDate(self)
    }
    
    func toString(dateStyle dateStyle: NSDateFormatterStyle, timeStyle: NSDateFormatterStyle, doesRelativeDateFormatting: Bool = false) -> String
    {
        let formatter = NSDateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.doesRelativeDateFormatting = doesRelativeDateFormatting
        return formatter.stringFromDate(self)
    }
    
    func relativeTimeToString() -> String
    {
        let time = self.timeIntervalSince1970
        let now = NSDate().timeIntervalSince1970
        
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
        let formatter = NSDateFormatter()
        return formatter.weekdaySymbols[self.weekday()-1]
    }
    
    func shortWeekdayToString() -> String {
        let formatter = NSDateFormatter()
        return formatter.shortWeekdaySymbols[self.weekday()-1]
    }
    
    func veryShortWeekdayToString() -> String {
        let formatter = NSDateFormatter()
        return formatter.veryShortWeekdaySymbols[self.weekday()-1]
    }
    
    func monthToString() -> String {
        let formatter = NSDateFormatter()
        return formatter.monthSymbols[self.month()-1]
    }
    
    func shortMonthToString() -> String {
        let formatter = NSDateFormatter()
        return formatter.shortMonthSymbols[self.month()-1]
    }
    
    func veryShortMonthToString() -> String {
        let formatter = NSDateFormatter()
        return formatter.veryShortMonthSymbols[self.month()-1]
    }
}