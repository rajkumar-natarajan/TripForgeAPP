import Foundation
import EventKit

enum CalendarExport {

    // MARK: ICS

    static func icsString(for trip: Trip) -> String {
        var lines: [String] = [
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "PRODID:-//TripForge//iOS//EN",
            "CALSCALE:GREGORIAN",
            "METHOD:PUBLISH",
            "X-WR-CALNAME:\(escape(trip.title))"
        ]
        let stamp = utcStamp(Date())
        for day in trip.days {
            for act in day.activities {
                lines += [
                    "BEGIN:VEVENT",
                    "UID:\(act.id)@tripforge",
                    "DTSTAMP:\(stamp)",
                    "DTSTART:\(localStamp(day.date, act.startTime))",
                    "DTEND:\(localStamp(day.date, DateUtils.addMinutes(to: act.startTime, act.durationMin)))",
                    "SUMMARY:\(escape(act.title))",
                    "DESCRIPTION:\(escape(act.description))",
                    "LOCATION:\(escape(act.location))",
                    "BEGIN:VALARM",
                    "TRIGGER:-PT30M",
                    "ACTION:DISPLAY",
                    "DESCRIPTION:\(escape(act.title))",
                    "END:VALARM",
                    "END:VEVENT"
                ]
            }
        }
        lines.append("END:VCALENDAR")
        return lines.joined(separator: "\r\n")
    }

    /// Writes the .ics to a temp file and returns its URL for the share sheet.
    static func writeICS(for trip: Trip) -> URL? {
        let name = trip.title.lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).ics")
        do {
            try icsString(for: trip).data(using: .utf8)?.write(to: url)
            return url
        } catch { return nil }
    }

    // MARK: EventKit (add straight to the user's calendar)

    static func addToCalendar(_ trip: Trip) async -> Result<Int, Error> {
        let store = EKEventStore()
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await store.requestWriteOnlyAccessToEvents()
            } else {
                granted = try await store.requestAccess(to: .event)
            }
            guard granted else {
                return .failure(NSError(domain: "TripForge", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Calendar access was denied. You can enable it in Settings."]))
            }
            var count = 0
            for day in trip.days {
                for act in day.activities {
                    guard let start = date(day.date, act.startTime) else { continue }
                    let event = EKEvent(eventStore: store)
                    event.title = act.title
                    event.location = act.location
                    event.notes = act.description
                    event.startDate = start
                    event.endDate = start.addingTimeInterval(TimeInterval(act.durationMin * 60))
                    event.calendar = store.defaultCalendarForNewEvents
                    event.addAlarm(EKAlarm(relativeOffset: -1800))
                    try store.save(event, span: .thisEvent)
                    count += 1
                }
            }
            return .success(count)
        } catch {
            return .failure(error)
        }
    }

    // MARK: Helpers

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    private static func utcStamp(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return f.string(from: d)
    }

    private static func localStamp(_ dateISO: String, _ time: String) -> String {
        let d = dateISO.replacingOccurrences(of: "-", with: "")
        let t = time.replacingOccurrences(of: ":", with: "")
        return "\(d)T\(t)00"
    }

    private static func date(_ dateISO: String, _ time: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.date(from: "\(dateISO) \(time)")
    }
}
