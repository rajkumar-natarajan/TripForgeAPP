import Foundation

struct ParsedPrompt {
    var destination: String?
    var days: Int?
    var travelers: Int?
    var budget: Double?
    var interests: [String] = []
    var travelStyle: TravelStyle?
    var pace: Pace?
}

// Heuristic natural-language extractor — the Swift port of the web parsePrompt().
enum PromptParser {

    static func parse(_ text: String) -> ParsedPrompt {
        let lower = text.lowercased()
        var result = ParsedPrompt()

        // Days: "5 days", "5-day", "a week", "long weekend"
        if let m = firstMatch(lower, #"(\d+)\s*[-\s]?day"#), let n = Int(m) {
            result.days = n
        } else if lower.contains("week") {
            result.days = 7
        } else if lower.contains("long weekend") {
            result.days = 4
        } else if lower.contains("weekend") {
            result.days = 3
        }

        // Travelers
        if lower.contains("my wife") || lower.contains("my husband") || lower.contains("my partner")
            || lower.contains("couple") || lower.contains("for two") || lower.contains("for 2") {
            result.travelers = 2
        } else if lower.contains("solo") || lower.contains("myself") || lower.contains("just me") {
            result.travelers = 1
        } else if let m = firstMatch(lower, #"(\d+)\s*(?:people|travel(?:ers|lers)|adults|guests)"#), let n = Int(m) {
            result.travelers = n
        } else if let m = firstMatch(lower, #"family of\s*(\d+)"#), let n = Int(m) {
            result.travelers = n
        }

        // Budget: "$3000", "3,000 usd", "€1200", "budget 2000"
        if let m = firstMatch(text, #"[\$€£]\s*([\d,]+)"#) {
            result.budget = Double(m.replacingOccurrences(of: ",", with: ""))
        } else if let m = firstMatch(lower, #"budget(?:\s*(?:of|is|:))?\s*([\d,]+)"#) {
            result.budget = Double(m.replacingOccurrences(of: ",", with: ""))
        } else if let m = firstMatch(lower, #"([\d,]+)\s*(?:usd|eur|gbp|dollars|euros|pounds)"#) {
            result.budget = Double(m.replacingOccurrences(of: ",", with: ""))
        }

        // Destination: "in Tokyo", "to Paris", "trip to Bali"
        if let dest = extractDestination(text) {
            result.destination = dest
        }

        // Interests
        for interest in Constants.interestOptions where lower.contains(interest) {
            result.interests.append(interest)
        }
        let synonyms: [String: String] = [
            "anime": "anime", "manga": "anime", "temple": "history", "temples": "history",
            "hike": "hiking", "hiking": "hiking", "beach": "beaches", "surf": "beaches",
            "wine": "food", "eat": "food", "restaurants": "food", "cuisine": "food",
            "gallery": "art", "galleries": "art", "museum": "museums", "nightclub": "nightlife"
        ]
        for (k, v) in synonyms where lower.contains(k) && !result.interests.contains(v) {
            result.interests.append(v)
        }

        // Travel style
        if lower.contains("luxury") || lower.contains("luxurious") { result.travelStyle = .luxury }
        else if lower.contains("budget") || lower.contains("cheap") || lower.contains("backpack") { result.travelStyle = .budget }
        else if lower.contains("adventure") || lower.contains("adventurous") { result.travelStyle = .adventure }
        else if lower.contains("relax") || lower.contains("chill") || lower.contains("laid back") { result.travelStyle = .relaxed }
        else if lower.contains("culture") || lower.contains("cultural") { result.travelStyle = .cultural }

        // Pace
        if lower.contains("packed") || lower.contains("action") || lower.contains("see everything") { result.pace = .packed }
        else if lower.contains("relax") || lower.contains("slow") || lower.contains("chill") || lower.contains("laid back") { result.pace = .chill }

        return result
    }

    private static func extractDestination(_ text: String) -> String? {
        // Look for "in/to <Capitalized Words>"
        let pattern = #"(?:\bin\b|\bto\b|\bvisit(?:ing)?\b)\s+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+){0,2})"#
        if let m = firstMatch(text, pattern) {
            return cleanDestination(m)
        }
        // Fallback: known city name anywhere
        for city in Planner.cities.keys {
            if text.lowercased().contains(city) { return Planner.titleCase(city) }
        }
        return nil
    }

    private static func cleanDestination(_ s: String) -> String {
        // Trim trailing month/time words accidentally captured.
        let stop = ["In", "For", "With", "July", "June", "May", "April", "March",
                    "August", "September", "October", "November", "December",
                    "January", "February", "Mid", "Early", "Late", "Next"]
        let words = s.split(separator: " ").map(String.init).filter { !stop.contains($0) }
        return words.joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }

    /// Returns the first capture group of the first match, or nil.
    private static func firstMatch(_ text: String, _ pattern: String) -> String? {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = re.firstMatch(in: text, range: range), match.numberOfRanges > 1,
              let r = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[r])
    }
}
