import Foundation

enum DateUtils {
    static let iso: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func todayISO() -> String { iso.string(from: Date()) }

    static func date(from isoStr: String) -> Date {
        iso.date(from: isoStr) ?? Date()
    }

    static func addDays(_ isoStr: String, _ n: Int) -> String {
        let d = date(from: isoStr)
        let nd = Calendar(identifier: .gregorian).date(byAdding: .day, value: n, to: d) ?? d
        return iso.string(from: nd)
    }

    static func daysBetween(_ start: String, _ end: String) -> Int {
        let s = date(from: start)
        let e = date(from: end)
        let comps = Calendar(identifier: .gregorian).dateComponents([.day], from: s, to: e)
        return max(1, (comps.day ?? 0) + 1)
    }

    /// Add minutes to a "HH:mm" string, returning "HH:mm".
    static func addMinutes(to time: String, _ addMin: Int) -> String {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return time }
        let total = parts[0] * 60 + parts[1] + addMin
        let h = (total % 1440) / 60
        let m = total % 60
        return String(format: "%02d:%02d", h, m)
    }

    /// "09:30" -> "9:30 AM"
    static func time12(_ t: String) -> String {
        let parts = t.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return t }
        let h = parts[0], m = parts[1]
        let ampm = h >= 12 ? "PM" : "AM"
        let hh = h % 12 == 0 ? 12 : h % 12
        return String(format: "%d:%02d %@", hh, m, ampm)
    }

    static func dayLabel(_ isoStr: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: date(from: isoStr))
    }

    static func rangeLabel(_ start: String, _ end: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        let sD = date(from: start), eD = date(from: end)
        let fy = DateFormatter(); fy.dateFormat = "MMM d, yyyy"
        return "\(f.string(from: sD)) – \(fy.string(from: eD))"
    }
}

enum Money {
    static func format(_ amount: Double, _ currency: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currency
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }
}

enum Constants {
    static let interestOptions = [
        "food", "history", "art", "nature", "nightlife", "shopping", "architecture",
        "anime", "music", "beaches", "hiking", "photography", "coffee", "museums"
    ]
    static let dietaryOptions = ["vegetarian", "vegan", "halal", "kosher", "gluten-free", "no restrictions"]
    static let currencies = ["USD", "EUR", "GBP", "JPY", "IDR", "AUD", "CAD"]

    static let templates: [TripTemplate] = [
        TripTemplate(id: "honeymoon", name: "Honeymoon", emoji: "💞",
                     description: "Romantic, unhurried, memorable moments for two.",
                     travelStyle: .luxury, pace: .chill,
                     interests: ["romance", "food", "photography"]),
        TripTemplate(id: "solo", name: "Solo Adventure", emoji: "🎒",
                     description: "Spontaneous, budget-savvy, off the beaten path.",
                     travelStyle: .adventure, pace: .packed,
                     interests: ["hiking", "food", "history"]),
        TripTemplate(id: "family", name: "Family Trip", emoji: "👨‍👩‍👧",
                     description: "Kid-friendly, balanced, plenty of downtime.",
                     travelStyle: .balanced, pace: .moderate,
                     interests: ["nature", "museums", "beaches"]),
        TripTemplate(id: "foodie", name: "Foodie Tour", emoji: "🍽️",
                     description: "Eat your way through the city, one bite at a time.",
                     travelStyle: .cultural, pace: .moderate,
                     interests: ["food", "coffee", "shopping"])
    ]
}
