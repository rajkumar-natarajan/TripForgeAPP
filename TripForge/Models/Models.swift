import Foundation

// MARK: - Enums

enum ActivityType: String, Codable, CaseIterable, Identifiable {
    case attraction, food, cafe
    case hiddenGem = "hidden-gem"
    case transport, hotel, shopping, nature, nightlife, other
    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .attraction: return "🎡"
        case .food: return "🍜"
        case .cafe: return "☕"
        case .hiddenGem: return "💎"
        case .transport: return "🚆"
        case .hotel: return "🏨"
        case .shopping: return "🛍️"
        case .nature: return "🌲"
        case .nightlife: return "🌙"
        case .other: return "📍"
        }
    }

    var label: String {
        switch self {
        case .attraction: return String(localized: "Attraction")
        case .food: return String(localized: "Food")
        case .cafe: return String(localized: "Café")
        case .hiddenGem: return String(localized: "Hidden Gem")
        case .transport: return String(localized: "Transport")
        case .hotel: return String(localized: "Stay")
        case .shopping: return String(localized: "Shopping")
        case .nature: return String(localized: "Nature")
        case .nightlife: return String(localized: "Nightlife")
        case .other: return String(localized: "Other")
        }
    }
}

enum TravelStyle: String, Codable, CaseIterable, Identifiable {
    case budget, balanced, luxury, adventure, relaxed, cultural
    var id: String { rawValue }
    var label: String { String(localized: LocalizedStringResource(stringLiteral: "style.\(rawValue)")) }
}

enum Pace: String, Codable, CaseIterable, Identifiable {
    case chill, moderate, packed
    var id: String { rawValue }
    var label: String { String(localized: LocalizedStringResource(stringLiteral: "pace.\(rawValue)")) }
    var activitiesPerDay: Int {
        switch self {
        case .chill: return 3
        case .moderate: return 4
        case .packed: return 5
        }
    }
    var hint: String { String(localized: "\(activitiesPerDay) stops/day") }
}

// MARK: - Core models

struct GeoPoint: Codable, Hashable {
    var lat: Double
    var lng: Double
}

struct Weather: Codable, Hashable {
    var high: Int
    var low: Int
    var condition: String
    var emoji: String
}

struct Activity: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var title: String
    var type: ActivityType
    var description: String
    var startTime: String   // "09:30"
    var durationMin: Int
    var cost: Double        // total for all travelers, trip currency
    var location: String
    var coords: GeoPoint?
    var notes: String?
    var booked: Bool = false
}

struct Day: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var date: String        // ISO "2025-07-14"
    var title: String
    var summary: String
    var weather: Weather?
    var activities: [Activity]
}

struct Participant: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var email: String?
    var role: String        // owner|editor|viewer
}

struct PackingItem: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var label: String
    var category: String
    var packed: Bool = false
}

struct Trip: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var title: String
    var destination: String
    var destinationCoords: GeoPoint?
    var startDate: String
    var endDate: String
    var travelers: Int
    var budget: Double
    var currency: String
    var travelStyle: TravelStyle
    var pace: Pace
    var interests: [String]
    var dietary: [String]
    var prompt: String?
    var days: [Day]
    var participants: [Participant]
    var packingList: [PackingItem]
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var totalCost: Double {
        days.reduce(0) { $0 + $1.activities.reduce(0) { $0 + $1.cost } }
    }
}

// MARK: - Planner input & generated output

struct PlannerInput {
    var destination: String
    var startDate: String
    var endDate: String
    var travelers: Int
    var budget: Double
    var currency: String
    var interests: [String]
    var pace: Pace
    var travelStyle: TravelStyle
    var dietary: [String]
}

struct TripTemplate: Identifiable {
    var id: String
    var name: String
    var emoji: String
    var description: String
    var travelStyle: TravelStyle
    var pace: Pace
    var interests: [String]
}
