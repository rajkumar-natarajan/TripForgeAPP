import Foundation
import SwiftUI

@MainActor
final class TripStore: ObservableObject {
    @Published var trips: [Trip] = []

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("tripforge_trips.json")
    }()

    init() {
        if ProcessInfo.processInfo.arguments.contains("UITEST_RESET") {
            try? FileManager.default.removeItem(at: fileURL)
        }
        load()
    }

    // MARK: Persistence

    func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([Trip].self, from: data) {
            trips = decoded
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(trips) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    // MARK: Generation

    /// Build a PlannerInput from an optional prompt merged with explicit fields.
    static func coerceInput(prompt: String?,
                            destination: String? = nil,
                            startDate: String? = nil,
                            endDate: String? = nil,
                            travelers: Int? = nil,
                            budget: Double? = nil,
                            currency: String? = nil,
                            interests: [String]? = nil,
                            pace: Pace? = nil,
                            travelStyle: TravelStyle? = nil,
                            dietary: [String]? = nil) -> PlannerInput {
        let parsed = prompt.map { PromptParser.parse($0) } ?? ParsedPrompt()
        let today = DateUtils.todayISO()
        let start = startDate ?? DateUtils.addDays(today, 30)
        let days: Int = {
            if let s = startDate, let e = endDate { return DateUtils.daysBetween(s, e) }
            return parsed.days ?? 3
        }()
        let end = endDate ?? DateUtils.addDays(start, days - 1)

        let mergedInterests = (interests?.isEmpty == false) ? interests! : parsed.interests

        return PlannerInput(
            destination: destination?.isEmpty == false ? destination! : (parsed.destination ?? "Tokyo"),
            startDate: start,
            endDate: end,
            travelers: travelers ?? parsed.travelers ?? 1,
            budget: budget ?? parsed.budget ?? 2000,
            currency: currency ?? "USD",
            interests: mergedInterests,
            pace: pace ?? parsed.pace ?? .moderate,
            travelStyle: travelStyle ?? parsed.travelStyle ?? .balanced,
            dietary: dietary ?? []
        )
    }

    @discardableResult
    func createTrip(input: PlannerInput, prompt: String?) -> Trip {
        var trip = Planner.generate(input)
        trip.prompt = prompt
        trips.insert(trip, at: 0)
        save()
        return trip
    }

    // MARK: Mutations

    func delete(_ trip: Trip) {
        trips.removeAll { $0.id == trip.id }
        save()
    }

    func update(_ trip: Trip) {
        guard let idx = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        var t = trip
        t.updatedAt = Date()
        trips[idx] = t
        save()
    }

    func trip(withID id: String) -> Trip? { trips.first { $0.id == id } }

    func moveActivity(tripID: String, dayID: String, from: IndexSet, to: Int) {
        guard let ti = trips.firstIndex(where: { $0.id == tripID }),
              let di = trips[ti].days.firstIndex(where: { $0.id == dayID }) else { return }
        trips[ti].days[di].activities.move(fromOffsets: from, toOffset: to)
        trips[ti].updatedAt = Date()
        save()
    }

    func removeActivity(tripID: String, dayID: String, activityID: String) {
        guard let ti = trips.firstIndex(where: { $0.id == tripID }),
              let di = trips[ti].days.firstIndex(where: { $0.id == dayID }) else { return }
        trips[ti].days[di].activities.removeAll { $0.id == activityID }
        trips[ti].updatedAt = Date()
        save()
    }

    func addActivity(tripID: String, dayID: String, activity: Activity) {
        guard let ti = trips.firstIndex(where: { $0.id == tripID }),
              let di = trips[ti].days.firstIndex(where: { $0.id == dayID }) else { return }
        trips[ti].days[di].activities.append(activity)
        trips[ti].updatedAt = Date()
        save()
    }

    func togglePacked(tripID: String, itemID: String) {
        guard let ti = trips.firstIndex(where: { $0.id == tripID }),
              let pi = trips[ti].packingList.firstIndex(where: { $0.id == itemID }) else { return }
        trips[ti].packingList[pi].packed.toggle()
        trips[ti].updatedAt = Date()
        save()
    }
}
